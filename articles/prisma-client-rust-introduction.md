---
published: true
type: tech
topics:
  - Rust
emoji: 📝
title: prisma-client-rust入門
---

> この記事は [https://knowledge.nazo6.dev/blog/prisma-client-rust-introduction](https://knowledge.nazo6.dev/blog/prisma-client-rust-introduction) とのクロスポストです。


# 概要
[prisma-client-rust](https://prisma.brendonovich.dev/)はJavascript向けのORMである[prisma](https://www.prisma.io/)をRustから使えるようにしたものです。実はprismaのコア部分はRustで書かれているためこういうものも作りやすかったんじゃないかと思います。

# セットアップ
まずはプロジェクトを作成します。`cargo new --bin`でバイナリプロジェクトを作成して、`Cargo.toml`をこんな感じに編集します。

```toml:Cargo.toml
[package]
name = "app"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = { version = "0.6.18", features = ["headers", "query"] }

[dependencies.prisma-client-rust]
git = "https://github.com/Brendonovich/prisma-client-rust"
tag = "0.6.9"
default-features = false
features = ["postgresql", "migrations"]

[workspace]
resolver = "2"
members = ["prisma-cli"]
```
`prisma-client-rust`はcrates.ioでは提供されていないため、gitリポジトリを指定する必要があります(参考: https://github.com/Brendonovich/prisma-client-rust/issues/76 )。

`features`には使用するデータベースの他に他ライブラリとの統合機能を指定できます。ここではpostgresqlとmigration機能を指定しました。
個人的に興味深いものとしては`rspc` featureがあります。[rspc](https://www.rspc.dev/)はRust版trpcみたいなやつで、Rustの型からTypescriptの型を吐き出してフロントエンドで使用することができます。そして`rspc` featureを指定することで必要なものをderiveしてくれるわけです。

## cliのセットアップ
JS版と同様、prisma cliを使うことになるのでインストールします。[公式の手順](https://prisma.brendonovich.dev/getting-started/installation)に従うことでプロジェクトディレクトリ内でのみ`cargo prisma`コマンドを使用することができるようになります。

## スキーマの作成
次にprismaのスキーマを作成します。プロジェクトディレクトリ直下に`prisma`フォルダを作成し、その中に`schema.prisma`と`migrations`フォルダを作成します。
その後`cargo prisma generate`を実行することで`src/prisma.rs`が生成されます。このファイルはデバイス固有のものなので`.gitignore`に含めるべきです。

# Clientの作成
```rust:main.rs
#[tokio::main]
async fn main() -> Result<()> {
    let client = prisma::PrismaClient::_builder()
        .with_url(std::env::var("DATABASE_URL").expect("No DATABASE_URL environment variable"))
        .build()
        .await;
    #[cfg(debug_assertions)]
    {
        info!("db push");
        client._db_push().await.unwrap();
    }

    #[cfg(not(debug_assertions))]
    {
        info!("Running database migrations");
        client._migrate_deploy().await?;
        info!("Database migrations completed");
    }

	Ok(())
}
```
このように`PrismaClient`を作成することでデータベースにアクセスできます。開発時には`_db_push`メソッドを使ってschemaの変更を直接反映させます。実際には`axum`のstateなどに`Arc<PrismaClient>`として入れることになるでしょう。
リリースビルドでは`prisma migrate dev`コマンドを使用してマイグレーション用sqlを生成した上でそれらを適用します。

# CRUD操作
基本的なことは公式のdocsを見てもらえばわかると思うのでdocsでは説明が足りないなと感じた箇所について記したいと思います。
以下のサンプルコードでは公式のdocsにもある以下の`prisma.schema`を使うことにします。
```prisma:prisma.schema
generator client {
    provider = "cargo prisma"
    output = "src/prisma.rs"
}
 
model Post {
    id        String   @id @default(cuid())
    createdAt DateTime @default(now())
    updatedAt DateTime @updatedAt
    published Boolean
    title     String
    content   String?
    desc      String?
 
    comments Comment[]
}
 
model Comment {
    id        String   @id @default(cuid())
    createdAt DateTime @default(now())
    content   String
 
    post   Post   @relation(fields: [postID], references: [id])
    postID String
}
```

## リレーション
prisma-client-rustでは、read時にrelationも含めて取得する方法が2つあります。
### 1. `.with()`と`fetch`を使う
[ここ](https://prisma.brendonovich.dev/reading-data/fetch#single-relations)に載っているやり方です。
```rust
use prisam::{comment, post};
 
let post: post::Data = client
    .post()
    .find_unique(post::id::equals("0".to_string()))
    .with(post::comments::fetch(vec![])
      .with(comment::post::fetch())
    )
    .exec()
    .await
    .unwrap()
    .unwrap();
 
// Safe since post::comments::fetch has been used
for comment in post.comments().unwrap() {
    // Safe since comment::post::fetch has been used
    let post = comment.post().unwrap();
 
    assert_eq!(post.id, "0");
}
```
このコードのようにwithとfetchを使うことでリレーション先のデータを取得できますがデータが関数の中にあるResultで取得できるので扱いづらいです。

### 2. `include!()`マクロを使用する
https://prisma.brendonovich.dev/reading-data/select-include

このマクロは`include`メソッドに使用できるstructを生成することで型安全かつ簡潔にリレーションの取得を記述することができます。
例えば 
```rust
prisma::post::include!(post_with_comments {
	comments
})
```
と記述することで
```rust
mod post_with_comments {
    pub struct Data {
        id: String,
        ...
        comments: comments::Data 
    }
    fn include() {
	    ...
    }
}
```
のようなコードが生成されます。そして
```rust
let posts: Vec<_> = client
    .post()
    .find_many(vec![])
    .include(post_with_comments::include())
    .exec()
    .await?;
```
のようなコードを書くことで`post_with_comments::Data`型の値が返ってきます。

2のやり型はJSのprismaと同じような書き心地で非常に便利です。正直1の方法を使う必要はあまりないのではないかと感じました。

## 一部の列のみを取得
先程紹介した`include!()`マクロに似た`select!()`マクロを使用することで一部の列のみを取得することができます。
また、includeマクロ内でselectキーワードを使用するというようなことも可能で柔軟にデータを取得できます。
