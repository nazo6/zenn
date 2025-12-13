---
published: true
type: tech
topics:
  - Rust
  - gpui
emoji: 🖼
title: RustでデスクトップGUI - gpui入門 Part1 (gpuiの仕組み・状態管理の基礎編)
---

> この記事は[Rust Advent Calendar 2025](https://qiita.com/advent-calendar/2025/rust) シリーズ2 14日目の記事です。

[gpuiに関するスクラップ](https://zenn.dev/nazo6/scraps/4452b3e2b175eb)が最近よく見られていたのと、自分自身もgpuiでアプリを作ってみたかったので、gpuiについての記事を書いてみました。

# gpuiとは

[gpui](https://www.gpui.rs/)は、Rust製のデスクトップ向けUIフレームワークライブラリで、[Zedエディタ](https://zed.dev/)のために開発されました。Windows,Mac,Linuxの主要なデスクトップOSに対応しています。
ちなみに、公式サイト等では「GPUI」ではなく「gpui」という小文字表記が使用されているので本記事でもそれに従います。

gpuiは名前にも含まれている通りGPUを用いることを前提としています。GPUを搭載していないPCでも動作させることは可能ですが、エミュレーションとなるため低速になります。一方、現代的なGPUを搭載したPCであれば非常に高速に動作することを目標としているようです。

## 環境

執筆時点(2025/12/13)における最新のバージョンを使用しています。

- Rust 1.92.0
- gpui v0.2.2

gpuiを導入するには、Rustプロジェクトで

```bash
cargo add gpui
```

を実行するだけです。

:::message
gpuiはZedエディタに合わせて開発が進んでおり、今後もAPIに破壊的変更があることが予想されます。
:::

# gpuiのメリット・デメリット

他の言語及びRustのGUIライブラリと比較した際に感じたメリット・デメリットは以下のようになります。

## メリット

- GPUを活用して高速に動作するGUIを作成できる
- IMEが動作する
- Zedという製品で実用されているフレームワークであり、ある程度成熟しており、開発の継続可能性も高いと思われる
- [gpui-component](https://github.com/longbridge/gpui-component)や[adabraka-ui](https://github.com/augani/adabraka-ui)などの既成のコンポーネントライブラリがある程度ある
- WebViewじゃないのでWebのあれこれに縛られない

## デメリット

- GPUが搭載されていないPCとの互換性は低い
- OSのコンポーネントを使わない独自描画のため、ネイティブルックではなくバイナリが大きめ
- ドキュメントが非常に不足している
- モバイルには対応していない
- コンポーネントライブラリがあるとは言えそこまで充実しているわけでもない
- ホットリロードなどはない
- WebViewじゃないのでWebの膨大なエコシステムを使えない

# gpuiのスタック

まず、gpuiがどのように動作するかについてざっと見ていきます。

## コンポーネントシステム

最も高レイヤから見たgpuiは、以下のようなコンポーネントベースのUIフレームワークです。以下はgpuiの公式サイトに書いてあるサンプルコードです。

```rust
use gpui::{
    div, prelude::*, px, rgb, size, App, Application, Bounds, Context, SharedString, Window,
    WindowBounds, WindowOptions,
};
 
struct HelloWorld {
    text: SharedString,
}
 
impl Render for HelloWorld {
    fn render(&mut self, _window: &mut Window, _cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .flex()
            .flex_col()
            .gap_3()
            .bg(rgb(0x505050))
            .size(px(500.0))
            .justify_center()
            .items_center()
            .shadow_lg()
            .border_1()
            .border_color(rgb(0x0000ff))
            .text_xl()
            .text_color(rgb(0xffffff))
            .child(format!("Hello, {}!", &self.text))
            .child(
                div()
                    .flex()
                    .gap_2()
                    .child(div().size_8().bg(gpui::red()))
                    .child(div().size_8().bg(gpui::green()))
                    .child(div().size_8().bg(gpui::blue()))
                    .child(div().size_8().bg(gpui::yellow()))
                    .child(div().size_8().bg(gpui::black()))
                    .child(div().size_8().bg(gpui::white())),
            )
    }
}
 
fn main() {
    Application::new().run(|cx: &mut App| {
        let bounds = Bounds::centered(None, size(px(500.), px(500.0)), cx);
        cx.open_window(
            WindowOptions {
                window_bounds: Some(WindowBounds::Windowed(bounds)),
                ..Default::default()
            },
            |_, cx| {
                cx.new(|_| HelloWorld {
                    text: "World".into(),
                })
            },
        )
        .unwrap();
    });
}
```

これを実行すると以下のようになります。
![](/images/84b75ec33232.png)
コードを見てみると基本要素として`div`という名前が使われていたり、Tailwind CSSっぽいスタイリング構文が標準で用意されていたりと、Webフロントエンドが意識されているようです。

ここで重要になるのが状態管理ですが、これについては後の章で解説します。

## `Element`トレイト

このような`Render`/`RenderOnce`を実装したコンポーネントから`Element`トレイトを実装した型を返すことができます。これは実際の描画を担当する低レベルなものです。`Element`トレイトの実装では、自身の大きさや実際に描画する内容を決める必要があり、内部では階層構造のように保持されています。

先程出てきた`div`要素は`Element`(および`IntoElement`)を実装している物の代表例で、以下のコードを見るとかなり複雑そうなことをしているのがわかります。

@[card](https://docs.rs/gpui/latest/src/gpui/elements/div.rs.html)

Renderトレイトの`render`メソッドが`IntoElement`を返すことからもわかる通り、ElementはRenderから生成されます。

## Taffy

そしてElementの描画を支えているのが、[taffy](https://github.com/DioxusLabs/taffy)というライブラリです。Taffyはいわゆるレイアウトエンジンというもので、先程のElement達を実際に画面に描画すべき構造に変換してくれます。

Taffyは他のRustプロジェクトでも使用されています。例えば[Blitz](https://github.com/DioxusLabs/blitz)というDioxusをベースとした別のGUIライブラリや[Servo](https://github.com/servo/servo)という、Rustで新しいブラウザエンジンを作るというプロジェクトなどです。

このTaffyですが、flexboxやCSS gridといったブラウザのCSSで実現できるレイアウトを処理することができます。(どちらが先なのかはよくわかりませんが、Servoで使われているのはそのような事情もありそうです。)
先程のサンプルコードに`justify_center`などCSSではお馴染のワードが出てきたのは、Taffyの力でgpuiではFlexboxがサポートされているからということです。

## GPUレンダラ

ここまでで画面に描画する内容を決定することができたので、これを実際に描画しなければいけません。そこで出てくるのがGPUレンダラです。RustではクロスプラットフォームのGUIレンダリングを実装したい場合は[wgpu](https://github.com/gfx-rs/wgpu)などを使うことが一般的だと思いますが、gpuiではそのような物は使っています。

- Mac: Metalまたは[blade](https://github.com/kvark/blade)
- Linux: bladeを介したVulkan
- Windows: Direct3D
  のAPIを叩くことでそれぞれ頑張って実装しているようです。すごい…

@[card](https://zed.dev/blog/zed-decoded-linux-when)

また、↑の記事にあるように、レンダラ以外の基本的なウインドウ管理についても各OS向けに実装されている他、テキスト描画システムについてもWindowsではDirectWriteなどOSネイティブのものを使うようにしているようです。

これら各プラットフォームを抽象化したAPIの上にレンダリングパイプラインが実装されています。

以上がgpuiのレンダリングシステムの全貌となります。

# gpuiの状態管理

前項で飛ばした重要な項目に、状態管理があります。ここからは、コンポーネントを組み合わせる方法と状態管理について説明します。

## `RenderOnce`と`IntoElement`

まずは`RenderOnce`トレイトですが、これは状態を持たないコンポーネントに実装します。このトレイトの定義は

```rust
pub trait RenderOnce: 'static {
    // Required method
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement;
}
```

です。注目すべきは`render`で`self`が渡ってくるという点です。これにより「一度だけレンダリングされる」ということが表現されています。つまり`RenderOnce`はステートレスなコンポーネントに実装されます。

このトレイトの特徴は、`#[derive(IntoElement)]`により`IntoElement`トレイトを実装できることです。
`div().child`等のメソッドは`IntoElement`を引数として受け取るため、`RenderOnce`と`IntoElement`を実装する以下のような`Stateless` structはdivの子要素として直接渡すことができます。

```rust
use gpui::*;

struct Root {}
impl Render for Root {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div().child(Stateless {}) // ← Statelessを要素として渡せる
    }
}

#[derive(IntoElement)]
struct Stateless {} // ← RenderOnceを実装したコンポーネント
impl RenderOnce for Stateless {
    fn render(self, window: &mut Window, cx: &mut gpui::App) -> impl IntoElement {
        div().child("Stateless")
    }
}

pub fn main() {
    let app = Application::new();
    app.run(move |cx| {
        cx.spawn(async move |cx| {
            cx.open_window(WindowOptions::default(), |window, cx| cx.new(|cx| Root {}))?;
            Ok::<_, anyhow::Error>(())
        })
        .detach();
    });
}
```

以上がステートの無いコンポーネントの例です。↓のような面白みのない画面が表示されます。
![](/images/b88beecb59d7.png)

## `Render`と`Entity`

状態を持たないコンポーネントについてはわかりましたね。では、状態を持つコンポーネントはどうすればいいでしょうか？実は既にコード中に出ていますが、そのようなコンポーネントには`Render`トレイトを実装します。
以前のコードで`Render`が既に出ていたのは、単にルートコンポーネントが`Render`を実装していないといけないからで、深い意味はありません。

では、`Render`トレイトを実装した以下のようなコンポーネントを見てみましょう。

```rust
struct Stateful {
    count: u32,
}
impl Render for Stateful {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div().child(format!("Stateful: {}", self.count)).child(
            div().child("Button").on_mouse_down(
                MouseButton::Left,
                cx.listener(|this, _evt, _window, cx| {
                    this.count += 1;
                    cx.notify();
                }),
            ),
        )
    }
}
```

`render`関数の中身は後ほど説明しますが、これはカウンターとインクリメントボタンを持つコンポーネントです。`count`というステートを持っています。`RenderOnce`では`self`が渡ってきたのに対して`Render`では`&mut self`が渡ってきており、型でも何回もレンダリングされそうなことがわかります。
では、このコンポーネントはどうやって要素ツリーの中に入れればいいのでしょうか？`derive(IntoElement)`は`RenderOnce`専用なので、

```rust
fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
    div().child(Stateful {})
}
```

というコードは書けません。

ですが、[`IntoElement`のdoc](https://docs.rs/gpui/latest/gpui/trait.IntoElement.html)を見ると

```rust
impl<V: 'static + Render> IntoElement for Entity<V>
```

という実装があることがわかります。なので`Entity<Stateful>`というものを作ればレンダリングができそうです。

### `Entity`

`Entity`が何なのかという話の前にまずは`Render`なコンポーネントをどう使うかを示します。

```rust
use gpui::*;

struct Root {
    stateful: Entity<Stateful>,
}
impl Root {
    fn new(cx: &mut App) -> Self {
        Self {
            stateful: cx.new(|_| Stateful { count: 0 }), // ← ココ
        }
    }
}
impl Render for Root {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div().child(self.stateful.clone()) // ← ココ
    }
}
```

新たにできた`Root::new`で、`cx.new()`というものを呼んでそれを保存しています。`render`時にはそこで作ったものを`clone`して渡していることがわかります。

これを実行すると、下のButtonと書かれた部分を押すことで`Stateful: 0`の数字が増え、動作していることがわかります。
![](/images/a0544589b865.png)

`cx`は`&mut App`型ですが、これはgpuiアプリの開始時にgpuiから渡されるものです。そしてこの`cx`のメソッドである`cx.new()`こそが`Entity<Stateful>`を作るための処理です。この`Entity<V>`は**View**と呼ばれています。
これは`IntoElement`を実装しているため、`div().child()`に渡すことができます。

このコードより、ステートを持つコンポーネントを子としたい場合には、そのステートを親が保存しておく必要があることがわかります。

:::message
ここまで、「コンポーネント」という用語をカジュアルに使ってきましたが、この用語はあまり適切ではないと感じています。「RenderOnceを実装したstruct」は確かにコンポーネントっぽいですが、「Renderを実装した構造体」はコンポーネントなのでしょうか？それはステートではないのでしょうか？
ただ、これ以外に適切な言葉を見つけられないため、とりあえずコンポーネントらしきものをコンポーネントを呼んでいます。
:::

では、`Entity`とは何なのでしょうか。実はZed公式の以下の記事に詳しく書いてあります。

@[card](https://zed.dev/blog/gpui-ownership)

要するに、`Entity`は「`Rc`といったスマートポインタに似ているが、それを`App`構造体でのステート中央集権型のアーキテクチャに適応したもの」です。

この記事では、Rustの所有権システムと状態管理をうまく組み合わせる方法を探した結果、`App`というルート構造体に全てのステートを保存するという手法を採用したということが書いてあります。これは今まで出てきた`App`構造体のことで、`cx`の型です。執筆時点での実際の`App`構造体のコードがこちらです。

```rust
pub struct App {
	...
    pub(crate) entities: EntityMap,
    ...
}

pub(crate) struct EntityMap {
    entities: SecondaryMap<EntityId, Box<dyn Any>>,
    pub accessed_entities: RefCell<FxHashSet<EntityId>>,
    ref_counts: Arc<RwLock<EntityRefCounts>>,
}
```

`entities: SecondaryMap<EntityId, Box<dyn Any>>`に、全てのステートが保存されます。ここのステートの一つにアクセスするための鍵が`Entity`であるというわけです。
つまり、`cx.new() (= AppContext::new())`は、この`entities`に構造体を追加し、それへのハンドルである`Entity`を取得するメソッドだったという訳です。
また、ここから`render`時に`self.stateful.clone()`をしているのはあくまで`Entity`のクローンであり、安価なコピーであることがわかります。

### 状態の更新

`Entity`について分かったところで、`Stateful`コンポーネントの中身について見てみましょう。

```rust
struct Stateful {
    count: u32,
}
impl Render for Stateful {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div().child(format!("Stateful: {}", self.count)).child(
            div().child("Button").on_mouse_down(
                MouseButton::Left,
                cx.listener(|this, _evt, _window, cx| {
                    this.count += 1;
                    cx.notify();
                }),
            ),
        )
    }
}
```

gpui単体では「ボタン」というコンポーネントは用意されていないため、単にdivに描画されたテキストの左クリックを検知とすることでボタンにしています。
そのボタンのハンドラでは`cx.listener`をいうものが使われています。ここで注意するのは、ここでの`cx`は`&mut App`ではなく`&mut Context<Self>`という型であるということです。とは言っても難しいことはありません。[`Context<T>`](https://docs.rs/gpui/latest/gpui/struct.Context.html)の定義は以下の通りです。

```rust
pub struct Context<'a, T> {
    app: &'a mut App,
    entity_state: WeakEntity<T>,
}
```

この定義から分かるのは、`Context<T>`は`App`に`T`のステートの`Entity`を加えたものであるということです。つまり、`Context<T>`は、`T`のステートに特化した`App`であると言えます。

今回は`cx: &mut Context<Self>`より、`cx`は`Context<Stateful>`という型となります。つまりこの`cx`では`Stateful`の値を操作するための操作ができるのです。その一つが`cx.listener`です。

```rust
pub fn listener<E: ?Sized>(
    &self,
    f: impl Fn(&mut T, &E, &mut Window, &mut Context<'_, T>) + 'static,
) -> impl Fn(&E, &mut Window, &mut App) + 'static
```

というシグネチャを持っています。これはイベントコールバックの中で`this`として`&mut T`にアクセスできるようにするメソッドです。今回はインクリメントするボタンなので、`this.count += 1`としています。
また、カウントを増やした後に`cx.notify()`を実行しています。これは、gpuiは変更を自動追跡するわけではないからです。変更を加えた場合は`cx.notify()`を実行することでそのEntityが更新されます。

### Observe

状態管理の最後として`observe`について紹介します。`observe`は他のエンティティの状態を監視するための仕組みです。

Observeを用いる例として以下のコードを示します。

```rust
struct Counter {
    value: u32,
}

impl Counter {
    fn new() -> Self {
        Self { value: 0 }
    }

    fn increment(&mut self, cx: &mut Context<Self>) {
        self.value += 1;
        cx.notify();
    }
}

struct CounterDisplay {
    counter: Entity<Counter>,
}

impl CounterDisplay {
    fn new(counter: Entity<Counter>, cx: &mut Context<Self>) -> Self {
        cx.observe(&counter, |this, counter, cx| {
            cx.notify();
        })
        .detach();

        Self { counter }
    }
}

impl Render for CounterDisplay {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let value = self.counter.read(cx).value;
        div()
            .child(format!("Counter value: {}", value))
            .child(div().child("Button").on_mouse_down(
                MouseButton::Left,
                cx.listener(|this, _evt, _window, cx| {
                    this.counter.update(cx, |counter, cx| {
                        counter.increment(cx);
                    });
                }),
            ))
    }
}
```

`Entity<Counter>`が`CounterDisplay`に入っていますが、`Counter`自体は`Render`ではありません。Entityはあくまでgpuiが状態を保存するための仕組みなので必ずしも`Entity<T>`の`T`が`Render`を実装しなければいけないわけではないのです。

さて、そのような`Counter`の値を表示する`CounterDisplay`は当然`Counter`のステートに依存するわけですが、`cx.notify()`は自身のEntityのアップデートを行うだけです。
そこで使用できるのが`cx.observe`です。これを用いることで、他の`Entity`で`cx.notify()`が実行された際の処理を記述できます。`CounterDisplay`では`Counter`の更新時に自身をnotifyすることで表示を更新しています。
また、最後に`.detach()`が付いているのは、`cx.observe()`から返される`Subscription`はドロップ時に監視を解除するからです。本来は`CounterDisplay`の中にこの値を保存しておくべきですが、今回は便宜上`.deatch()`することで、`new`の後にドロップしてもobserve処理を継続します。

# まとめ

以上で、gpuiのアーキテクチャと状態管理の基本的な仕組みについて解説しました。gpuiにはまだ

- subscribe/emit
- Globalステート
- Action(キーボードショートカット)
- 非同期ランタイム

などの機能があるのですが、これらを紹介しきることはできない(というか自分もあまり理解していない)ので、このあたりにしておきます。

# さいごに

今回はgpuiの動作の仕組みというところに焦点を当てました。正直ドキュメントが少なくて厳しかったです。間違っている箇所もあるかと思うので何かあればご指摘頂けると幸いです。

gpuiは他のRustフレームワークと比べてもZedという実戦がある分、IMEといった細かい箇所できちんとしているように感じるので、デスクトップアプリであれば選択肢に入るようになるかもしれません。

本当は[gpui-component](https://github.com/longbridge/gpui-component)とかを使ってカッコイイアプリを作るような記事を書こうと思っていたのですが、ステート管理などについて調べていると結構深堀りしないといけないような箇所が出てきてこのような記事になりました。
元気があればいつか実践的なアプリを作るPart 2の記事を書こうと思います…


> この記事は[個人ブログ](https://nazo6.dev/blog/article/gpui-introduction-1)とクロスポストしています。