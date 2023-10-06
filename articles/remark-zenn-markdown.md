---
published: true
created: 2023-09-25T00:11:04+09:00
updated: 2023-09-25T00:11:20+09:00
tags:
  - tech/lang/js-ts
  - tech/lang/js-ts/unified
slug: remark-zenn-markdown
topics:
  - typescript
emoji: 📝
title: RemarkでZenn形式のmarkdownを再現する
---
> この記事は [https://knowledge.nazo6.dev/blog/remark-zenn-markdown](https://knowledge.nazo6.dev/blog/remark-zenn-markdown) とのクロスポストです。


# 概要
この記事はブログとZennに同時投稿しているのですが、その際に[Zen独自のmarkdown記法](https://zenn.dev/zenn/articles/markdown-guide#zenn-%E7%8B%AC%E8%87%AA%E3%81%AE%E8%A8%98%E6%B3%95)を使いたいときがあります。ブログ側ではmarkdownの表示に`remark`を使っているので`remark`でそれらを表示したいという趣旨です。

# Directive
まずはディレクティブ記法です。

```
:::message
メッセージをここに
:::
```
このようなコードで

:::message
メッセージ
:::

が表示されるというものです。これはどうやら一般にdirectiveと呼ばれる記法のようです。
これはなんかメジャーっぽいしお目当てのプラグインで既にあるのではと思い探すとありました。[これ](https://github.com/remarkjs/remark-directive)です。

これでdirective記法はクリア…かと思いきや実はこのプラグインではZennの記法を再現することはできません。これはZennでは
```
:::message alert
:::

:::details タイトル
内容
:::
```
のようにディレクティブ名の後にタイトルなどを記述するのですがこれはremark-directiveではサポートされていないからです。

なのでしょうがないので`remark-directive`にパッチを当てることにしました。パッチの内容は以下です。
```diff:micromark-extension-directive@2.2.1.patch
diff --git a/lib/factory-name.js b/lib/factory-name.js
index 4599862b23fcad95ac6ccc87a35ebca1a86aaa0b..083bbc056f41dd141e15f93e486f619aa7e3c67a 100644
--- a/lib/factory-name.js
+++ b/lib/factory-name.js
@@ -29,11 +29,11 @@ export function factoryName(effects, ok, nok, type) {
 
   /** @type {State} */
   function name(code) {
-    if (code === 45 || code === 95 || asciiAlphanumeric(code)) {
+    if (code && code !== 10 && code > 0) {
       effects.consume(code)
       return name
     }
     effects.exit(type)
-    return self.previous === 45 || self.previous === 95 ? nok(code) : ok(code)
+    return self.previous === 45 || self.previous === 95 || self.previous === 32 ? nok(code) : ok(code)
   }
 }
diff --git a/package.json b/package.json
index 43ac4e41363a82066fb338ef385bed9eefa83075..0ef29ce297f92a9fedda1a3771bd01b941647690 100644
--- a/package.json
+++ b/package.json
@@ -35,7 +35,6 @@
   ],
   "exports": {
     "types": "./index.d.ts",
-    "development": "./dev/index.js",
     "default": "./index.js"
   },
   "dependencies": {
```
このパッチでは、英字か数字のみがdirectiveのラベルで有効だったものを全ての文字で有効になるように変えています。これによって`:::directive{.class}`のような記法は使えなくなりますが今回は問題ないのでよしとします。

`remark-directive`はこのプラグインを読み込んだ後に独自のプラグインで実際にディレクティブを有効なhtmlデータなどに変換します。
`message`ディレクティブと`details`ディレクティブを実装したものがこちらです。`details`の方は無理くりmdxの内部形式に変換しています。
```ts
import { h } from "hastscript";
import { Root } from "mdast";
import type { Plugin } from "unified";
import { visit } from "unist-util-visit";

export const remarkCustomDirective: Plugin<[], Root> = () => {
  return (tree) => {
    visit(tree, (node: any) => {
      if (
        node.type === "textDirective" ||
        node.type === "leafDirective" ||
        node.type === "containerDirective"
      ) {
        const [name, ...n] = node.name.split(" ");
        let value: string | null = null;
        if (n.length > 0) {
          value = n.join(" ");
        } else {
          value = null;
        }
        if (name === "message") {
          node.attributes.class = `note ${value ?? "warn"}`;

          const data = node.data || (node.data = {});
          const tagName = node.type === "textDirective" ? "span" : "div";

          data.hName = tagName;

          data.hProperties = h(tagName, node.attributes).properties;
        } else if (name === "details") {
          const children = [...node.children];
          node.type = "mdxJsxFlowElement";
          node.name = "details";
          node.attributes = [];
          node.children = value
            ? [
              {
                type: "mdxJsxFlowElement",
                name: "summary",
                attributes: [],
                children: [
                  {
                    type: "text",
                    value,
                  },
                ],
                data: {
                  _mdxExplicitJsx: true,
                },
              },
              ...children,
            ]
            : children;
          node.data = {
            _mdxExplicitJsx: true,
          };
        }
      }
    });
  };
};
```

これを使うには`remark-directive`と上の`remarkCustomDirective`の両方のプラグインを読み込みます。