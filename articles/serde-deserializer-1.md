---
published: true
type: tech
topics:
  - Rust
emoji: 🛠️
title: SerdeのDeserializerを実装する(Part1)
---

# 概要
Serdeで任意の形式のファイルなどをデシリアライズする際にはDeserializerを書く必要があります。この記事では基本的なDeserializerの書き方を解説します。
正直自分もあまり理解していない部分が多々あるのですが世に出ている情報が少ないので書くことにしました。
# コードの概観
serdeのDeserializerを実装するというのはつまり、「`Deserializer`トレイトを実装した構造体を用意する」ということです。ある文字列をデシリアライズするための関数`from_str`の概略コードは以下のようになります(あくまでイメージです)。
```rust
use serde::de;

struct MyDeserializer;

impl<'de, 'a> de::Deserializer<'de> for &'a mut MyDeserializer<'de> {
	(ここにDeserializeの実装)
	...
}

pub fn from_str<T: Deserialize>(input: &str) -> Result<T, Error> {
	let deserializer = MyDeserializer::new();
	T::deserialize(deserializer)?
}
```
ここで、`MyDeserializer`がデシリアライザ本体、`T: Deserialize`は`#[derive(Deserialize)]`などにより`serde::de::Deserialize`が実装された型のことですね。

# デシリアライズの基本を理解する
この記事では、超基本的なデシリアライザを実装して流れを理解していくことを目指します。

今回実装するのは、「`"true"`か`"false"`の文字列を受けとり、それを`bool`型にデシリアライズするだけ」のデシリアライザです。

## プロジェクトの作成
次のコマンドで、プロジェクトを作成し必要になるクレートを追加します。
```
$ cargo new --lib deserializer-example
$ cd deserializer-example
$ cargo add serde thiserror
```
## Errorの作成
まずはDeserializerのエラー型を作ります。これはDeserializerの関連型として必須で、`serde::de::Error`を実装している必要があります。
Deserializerを実装するのはライブラリであることが多いと思うので今回は[thiserror](https://docs.rs/thiserror/latest/thiserror/)を使います。
```rust:error.rs
use serde::de;
use std::fmt::Display;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum DeserializeError {
    #[error("Failed to parse: {0}")]
    Parse(String),
    #[error("Unsupported: {0}")]
    Unsupported(String),
    #[error("Error: {0}")]
    Message(String),
}

impl de::Error for DeserializeError {
    fn custom<T: Display>(msg: T) -> Self {
        DeserializeError::Message(msg.to_string())
    }
}
```
## Deserializerの実装
`BoolDeserializer`という構造体に`Deserializer`を適切に実装したものが以下になります。
```rust:lib.rs
mod error;

use serde::{
    de::{self, Visitor},
    forward_to_deserialize_any,
};

use error::DeserializeError;

pub struct BoolDeserializer<'de> {
    input: &'de str,
}

impl<'de, 'a> de::Deserializer<'de> for &'a mut BoolDeserializer<'de> {
    type Error = DeserializeError;

    fn deserialize_any<V>(self, visitor: V) -> Result<V::Value, Self::Error>
    where
        V: Visitor<'de>,
    {
        Err(DeserializeError::Unsupported(
            "Unsupported type".to_string(),
        ))
    }

    fn deserialize_bool<V>(self, visitor: V) -> Result<V::Value, Self::Error>
    where
        V: Visitor<'de>,
    {
        if self.input == "true" {
            visitor.visit_bool(true)
        } else if self.input == "false" {
            visitor.visit_bool(false)
        } else {
            Err(DeserializeError::Parse("Invalid boolean value".to_string()))
        }
    }

    forward_to_deserialize_any! {
        i8 i16 i32 i64 i128 u8 u16 u32 u64 u128 f32 f64 char str string
        bytes byte_buf option unit unit_struct newtype_struct seq tuple
        tuple_struct map struct enum identifier ignored_any
    }
}
```
### 実行してみる
なにはともあれ、実行してみましょう。以下のようなコードとテストを追加します。
```rust:lib.rs
fn from_str<'de, T: Deserialize<'de>>(input: &'de str) -> Result<T, DeserializeError> {
    let mut deserializer = BoolDeserializer { input };
    T::deserialize(&mut deserializer)
}

#[cfg(test)]
mod test {
    #[test]
    fn deserialize_true() {
        let value: bool = super::from_str("true").unwrap();
        assert!(value);
    }

    #[test]
    fn deserialize_error() {
        let value: String = super::from_str("true").unwrap();
        assert_eq!(value, "true");
    }
}
```
`cargo test`で実行すると以下のような出力が得られるはずです。
```
running 2 tests
test test::deserialize_error ... FAILED
test test::deserialize_true ... ok

failures:


- test::deserialize_error stdout 
-
thread 'test::deserialize_error' panicked at 'called `Result::unwrap()` on an `Err` value: Unsupported("Unsupported type")', src/lib.rs:61:53
```
`"true"`という文字列が正常に`true`にデシリアライズされ、さらに`"true"`という文字列であっても型がStringであればUnsupportedのエラーが発生していることがわかります。

### 解説

`Deserialize`を実装するには上で書いたエラー型、そして`deserialize_`で始まる、一連の型をデシリアライズするためのメソッドが必要です。`deserialize_`メソッドは対応する型がserdeに判別されて呼ばれます。全てのメソッドは以下のページで確認できます。

https://docs.rs/serde/latest/serde/trait.Deserializer.html

ただし、`forward_to_deserialize_any`マクロを使用することで、それらを`deserialize_any`メソッドに飛ばすことが可能です。
今回は`bool`のみをデシリアイズするDeserializerであるため、`bool`以外の全ての型を`deserialize_any`に飛ばしています。そして実際に`deserialize_any`で行われる処理はサポートされていないというエラーメッセージを返すことだけです。

そして重要なのがbool型をデシリアライズする`deserialize_bool`メソッドです。今回は受け取った文字列が`"true"`であれば`true`、`"false"`であれば`false`を返す処理にしたいわけですが、上の例では単に値を返すのではなく、何やら引数として受け取った`visitor: Visitor`の`visit_bool`関数で処理をしたものを返しています。
これは何かというと、型側(つまり`Deserialize`trait)での処理の柔軟性を高めるための`serde`の機構だと思います。次にこのVisitorについて解説します。
#### Visitorについて

Visitorについて説明するために、まずは今回デシリアライズした`bool`型への`Deserialize`トレイトの実装([github](https://github.com/serde-rs/serde/blob/ddc1ee564b33aa584e5a66817aafb27c3265b212/serde/src/de/impls.rs#L70))を見てみましょう。
```rust
struct BoolVisitor;

impl<'de> Visitor<'de> for BoolVisitor {
    type Value = bool;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str("a boolean")
    }

    fn visit_bool<E>(self, v: bool) -> Result<Self::Value, E>
    where
        E: Error,
    {
        Ok(v)
    }
}

impl<'de> Deserialize<'de> for bool {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        deserializer.deserialize_bool(BoolVisitor)
    }
}
```
このコードを見れば`Deserialize::deserialize -> Deserializer::deserialize_bool -> Visitor::visit_bool`の順で処理されていることがよりわかりやすいと思います。

また、[先程のコード](#Deserializerの実装)で実際に`deserialize_bool`に渡されていた`Visitor`は`BoolVisitor`だったということがわかります。そして、`BoolVisitor`には`expecting`と`visit_bool`の二つのメソッドが実装されています。詳しくは[docs.rs](https://docs.rs/serde/latest/serde/de/trait.Visitor.html)に解説がありますが、`expecting`はエラーメッセージに使われ、`visit_bool`はDeserializerで処理されたbool値を受けとり、`Self::Value`型を返しています。その他のメソッドは実装されていませんが、デフォルト実装でエラーが返るようになっています。

`bool`型の実装を見ても当然`bool`型をそのまま返しているだけなので「これって何の意味があるんだろう」と感じるかもしれません。しかし、例えば`bool`型からNewType構造体にデシリアライズされてほしいような型があるときにVisitorが役に立ちそうです。先程のテストコードに以下を追加してみます。
```rust
    #[test]
    fn deserialize_newtype() {
        use serde::de::{Error, Visitor};
        use std::fmt;

        #[derive(Debug, PartialEq)]
        struct NewType(bool);
        struct NewTypeVisitor;

        impl<'de> Visitor<'de> for NewTypeVisitor {
            type Value = NewType;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("a boolean")
            }

            fn visit_bool<E>(self, v: bool) -> Result<Self::Value, E>
            where
                E: Error,
            {
                Ok(NewType(v))
            }
        }

        impl<'de> Deserialize<'de> for NewType {
            fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
            where
                D: Deserializer<'de>,
            {
                deserializer.deserialize_bool(NewTypeVisitor)
            }
        }

        let value: NewType = super::from_str("true").unwrap();
        assert_eq!(value, NewType(true));
    }
```
ここで重要なのは、`Deserializer`には一切手を加えていないということです。つまり、`Deserializer`はserdeによって決められた基本的なインターフェースさえ実装すれば`Deserialize`を実装するあらゆる型をデシリアライズできるのです。

## 最後に
この記事では、簡単なDeserializerを実装してserdeでのデシリアライズの流れを追ってみました。参考になれば幸いです。

また、最初にも書きましたが、自分自身も(特にVisitor周りなど)これで理解が正しいのか曖昧な部分があります。間違いなどがありましたらコメントなどで教えていただけると嬉しいです

# 参考にさせていただいたサイト

https://serde.rs/impl-deserializer.html

Deserializerの実装方法についての公式ドキュメント


https://www.ricos.co.jp/tech/serde-deserializer/


https://crieit.net/posts/Serde-1-derive


https://users.rust-lang.org/t/why-are-there-2-types-for-deserializing-in-serde/35735/9

Visitorの理解を助けてくれました


> この記事は [https://note.nazo6.dev/blog/serde-deserializer-1](https://note.nazo6.dev/blog/serde-deserializer-1) とのクロスポストです。