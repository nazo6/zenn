---
published: true
type: tech
topics:
  - svelte
  - typescript
emoji: 🖼
title: SvelteKitでOG画像を生成する
---

> この記事は[Svelte Advent Calendar 2025](https://qiita.com/advent-calendar/2025/svelte) 11日目の記事です。(記事を書いてからAdvent Calendarがあることに気づいた…)

- SSG対応
- Svelteコンポーネントを用いる

ようなOG画像生成方法についてまとめました。

# 1. Svelteコンポーネントを画像化

まずレンダリングしたいコンポーネントを以下のように作成します。

```html:OgImage.svelte
<script lang="ts">
  const props: { title: string } = $props();
</script>

<div
  class="flex w-full h-full bg-black text-white items-center justify-center"
  style="background-image: linear-gradient(90deg, #f05122, #b55df7);"
>
  <h1 class="p-4 text-6xl leading-[1.3]">{props.title}</h1>
</div>

```

今回使うsatoriはTailwindをサポートしているので、このようにTailwindクラスを記述してスタイリングできます。ただし、全てのクラスをサポートしているわけではないので、例えばグラデーションは例のように`style`を使う必要があります。

このコンポーネントをレンダリングする手順は以下の通りとなります。

1. [Svelteのrender関数](https://svelte.dev/docs/svelte/imperative-component-api#render)を用いて、SvelteコンポーネントからHTMLを生成
2. satori-htmlを使ってHTMLからSVGを生成
3. sharpを使ってSVGをラスター画像に変換

satoriはJSXコンポーネントをSVG化するのに用いられるライブラリですが、satori-htmlを使えばHTMLをSVGに変換することができます。これに`render`関数で生成されたHTMLを食わせることでSVGを生成することができます。

これらの実装をしたのが以下のコードです。これを`lib/server/renderImage.ts`に作成しました。

```ts
import { readFile } from 'fs/promises';
import satori from 'satori';
import { html } from 'satori-html';
import sharp from 'sharp';
import type { Component, ComponentProps } from 'svelte';
import { render } from 'svelte/server';

let fontData: Buffer | null = null;

export async function renderImage<
  Comp extends Component<any>,
  Props extends ComponentProps<Comp> = ComponentProps<Comp>,
>(comp: Comp, props: Props): Promise<Buffer> {
  // @ts-expect-error RenderFn type is not accurate
  const result = render(comp, { props });
  const markup = html(result.body);

  if (!fontData) {
    fontData = await readFile('resource/fonts/NotoSansJP-Regular.ttf');
  }

  const svg = await satori(markup, {
    width: 1200,
    height: 630,
    fonts: [{ name: 'Noto Sans CJK JP', data: fontData }],
  });

  const sharpData = sharp(Buffer.from(svg)).webp({ quality: 90, effort: 0 });

  const buffer = await sharpData.toBuffer();

  return buffer;
}
```

satoriはレンダリング時にフォントを一つ以上指定する必要があります。今回は`resource/fonts/`にNotoSansJP-Regularを入れてそれを指定しています。

また、今回はwebpで画像を生成するようにしてみました。もちろんPNGなど他の形式でも大丈夫です。

# 2. OG画像用エンドポイントを作成

次にこのOG画像を実際に生成するためのエンドポイントを作成します。og画像は`/og/[...route]/og.webp`に保存されるようにします。
ということで以下のような`routes/og/[...route]/+server.ts`を作成しました。

```ts
import { error, type RequestHandler } from '@sveltejs/kit';
import OgImage from '$lib/components/OgImage.svelte';
import { renderImage } from '$lib/server/renderImage';

export const prerender = true;

export const GET: RequestHandler = async ({ params }) => {
  if (params.route === undefined) {
    return error(400, 'Bad Request');
  }
  const title = params.route

  const imageData = await renderImage(OgImage, { title });

  return new Response(imageData, {
    headers: {
      'Content-Type': 'image/webp',
    },
  });
};

```

レンダリングしたいコンポーネントが`OgImage.svelte`で、タイトルには仮でroute名を入れています。もちろん好きにカスタマイズできます。

また、SSGを行うためにはprerender=trueが必要です。

これで開発サーバーを起動して、例えば`http://localhost:5173/og/blog/article`にアクセスすると以下のような画像が得られるはずです。
![](/images/4535edd8be08.png)

# 3. `og:image`メタタグを指定

SvelteKitは生成されたページの`og:image`メタタグをクロールして、それが相対パスであればサーバー関数もprerenderしてくれるため、各ページに先程のエンドポイントへの具体的なパスを指定しておけば自動で静的なOG画像を生成することができます。

例えば`/article/[slug]`のようなルートがある場合、`/article/[slug]/+page.svelte`に

```html
<svelte:head>
  <meta property="og:image" content={`/og/article/${slug}/og.webp`}>
</svelte:head>
```

のように書き加えるだけで自動的にSSGができます。非常に便利ですね。

# まとめ

SvelteKitでは思ったよりシンプルな方法でOG画像を生成できることがわかりました。
特に`og:image`を探してサーバー関数も事前レンダリングしてくれるのが非常に便利で良かったです。これが無ければもっと面倒くさいことになっていた気がします。

ただ、画像のレンダリング、特にSVGからラスター画像への変換に500ms程度要しているのでビルドに時間がかかるようになってしまいました。ここは改善したい点です。


> この記事は[個人ブログ](https://nazo6.dev/blog/article/sveltekit-og-image)とクロスポストしています。