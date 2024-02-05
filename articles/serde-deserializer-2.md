---
published: true
type: tech
topics:
  - Rust
emoji: 🦞
title: SerdeのDeserializerを実装する(Part2 JSON編)
---

この記事は[Rust Advent Calendar 2023](https://qiita.com/advent-calendar/2023/rust) シリーズ3の19日目の記事です。

前回の[SerdeのDeserializerを実装する(Part1)](SerdeのDeserializerを実装する(Part1).md)の続きとして、この記事ではserdeの公式ドキュメントにある「[Implementing a Deserializer](https://serde.rs/impl-deserializer.html)」というページで実装されているjsonのデシリアライザ(を一部改変したもの)についてチュートリアル風に解説します。逆に言えばこのページの内容を理解していればこの記事を読む必要はないかもしれません…)。
と言っても全て解説すると分量が多すぎなので基本的なところのみを紹介します。
このページで実装されているデシリアイザは結構実践的で、このページの内容が理解できればserdeで割と思い通りのDeserializerを実装できるんじゃないかと思います。

この記事のコードは大体

https://github.com/serde-rs/example-format/blob/master/src/de.rs

からのコピペですが若干違うところもあるので

https://github.com/nazo6/serde-deserializer-example

こちらのリポジトリに記事に沿ったソースコードを載せておきます。それぞれのソースコードには`serde-rs/example-format`のソースコードのリンクを貼っておくのでserdeのドキュメントと見比べていただくとより理解しやすいのではないかと思います。
# 雛形の作成
Deserializerの雛形を作ったものが以下になります。詳細についてはPart1の記事を参考にしてください。
```rust:error.rs
use serde::de;
use std::fmt::Display;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("{0}")]
    Message(String),
}

impl de::Error for Error {
    fn custom<T: Display>(msg: T) -> Self {
        Error::Message(msg.to_string())
    }
}

pub type Result<T> = std::result::Result<T, Error>;
```

```rust:lib.rs
mod error;

use serde::{
    de::{self, Visitor},
    forward_to_deserialize_any, Deserialize,
};

use error::DeserializeError;

pub struct JsonDeserializer<'de> {
    input: &'de str,
}

impl<'de, 'a> de::Deserializer<'de> for &'a mut JsonDeserializer<'de> {
    type Error = DeserializeError;

    fn deserialize_any<V>(self, visitor: V) -> Result<V::Value, Self::Error>
    where
        V: Visitor<'de>,
    {
        Err(DeserializeError::Message("Unsupported type".to_string()))
    }

    forward_to_deserialize_any! {
        bool i8 i16 i32 i64 i128 u8 u16 u32 u64 u128 f32 f64 char str string
        bytes byte_buf option unit unit_struct newtype_struct seq tuple
        tuple_struct map struct enum identifier ignored_any
    }
}

pub fn from_str<'de, T: Deserialize<'de>>(input: &'de str) -> Result<T, DeserializeError> {
    let mut deserializer = JsonDeserializer { input };
    T::deserialize(&mut deserializer)
}
```
この状態では何を入力されてもエラーを返す、意味のないDeserializerになっています。

# ユーティリティの作成
これから`deserialize_*`メソッドを実装するにあたり、あると便利なメソッドがあるので実装しておきます。

ref: [L54](https://github.com/serde-rs/example-format/blob/54c5393580aa63465c5d6965e583a39e9ab4c0d3/src/de.rs#L54)

```rust:lib.rs
impl<'de> Deserializer<'de> {
    // Look at the first character in the input without consuming it.
    fn peek_char(&mut self) -> Result<char> {
        self.input.chars().next().ok_or(Error::Eof)
    }

    // Consume the first character in the input.
    fn next_char(&mut self) -> Result<char> {
        let ch = self.peek_char()?;
        self.input = &self.input[ch.len_utf8()..];
        Ok(ch)
    }
}
```
これから実装するデシリアライザでは文字列を一文字づつ進めながら解析を行います。そのため、文字列を消費して次の文字を得る`next_char`と進めずに文字を得る`peek_char`メソッドが実装されています。

serdeの`Deserializer`を実装する上で頭に入れておくと良いことは、Deserializer内部の状態をどんどん変化させながらパースを進めていくということです。
これは個人的な感想なのですが、Rustでは可変参照の取り扱いの難しさからこのように状態を変化させながら処理を行うことは少ないような気がしていて、頭の切り替えが必要でした。また、そのようなプログラムをここまで大規模に作ったserde、もといdtolnayさんはやはりすごいな…と感じました。

ついでにエラーを簡単に返すためのマクロも作っておきます。これは記事の都合上エラー処理を簡単にするためです。実際にはちゃんとErrorのEnumにバリアントを追加しましょう。
```rust:lib.rs
macro_rules! err {
    ($msg:expr) => {
        Error::Message($msg.to_string())
    };
}
```
# `deserialize_any`について
前回の記事では、`false`か`true`の文字列のみをDeserializeできるDeserializeを作成しましたが、その際、`deserialize_any`メソッドを実装することで`bool`型以外をエラーにしました。しかし、`deserialize_any`はそれ以外に重要な用途があり、「Self-describingなデータ」をデシリアライズする際に、デシリアイズするべき構造体の情報を見ずにデシリアライズを行うことができます。

"Self-describing"なデータ形式というのは、データ自体に型の情報を含むデータのことです。例えばjsonはSelf-describingな形式であり、データ中に現れる文字を見ることでデータ構造を決定できます。例えば「`{`」はマップ構造、「`"`」は文字列を意味する、などです。
これによりボイラープレートを削減できる他、`serde_json`では`serde_json::Value`型を使うことで型を決めなくても柔軟にjsonを処理できますが、これにも`deserialize_any`が活用されているようです。

しかしながら、上に挙げたserdeのドキュメントのサンプルには「The code below implements every method explicitly for documentation purposes but there is no advantage to that.」とあり、`deserialize_any`メソッドは実装されているもの他の`deserialize_*`メソッドも全て実装されており、`forward_to_deserialize_any!`が使われていないため実行されることはありません。ですが、せっかくなので今回は`deserialize_*`メソッドは必要な場所のみに実装して可能な限り`deserialize_any`を使うようにしたいと思います。

# `deserialize_any`の実装
そんなわけで、先程作成した`JsonDeserializer`に`deserialize_any`を実装しました。
```rust
impl<'de, 'a> de::Deserializer<'de> for &'a mut JsonDeserializer<'de> {
    fn deserialize_any<V>(self, visitor: V) -> Result<V::Value>
    where
        V: Visitor<'de>,
    {
        while let ' ' | '\n' | '\t' | '\r' = self.peek_char()? {
            self.next_char()?;
        }

        match self.peek_char()? {
            'n' => visitor.visit_unit(), // null (Unit)
            't' => {
                for c in ['t', 'r', 'u', 'e'] {
                    if c != self.next_char()? {
                        return Err(err!("Expected true"));
                    }
                }
                visitor.visit_bool(true)
            }
            'f' => {
                for c in ['f', 'a', 'l', 's', 'e'] {
                    if c != self.next_char()? {
                        return Err(err!("Expected false"));
                    }
                }
                visitor.visit_bool(false)
            }
            // 後で実装します
            '"' => visitor.visit_borrowed_str(self.parse_string()?), // string
            '0'..='9' => visitor.visit_u64(self.parse_u64()),        // unsigned number
            '-' => visitor.visit_u64(self.parse_u64()),              // signed number
            '[' => self.parse_deserialize_seq(visitor),
            '{' => self.parse_deserialize_map(visitor),
            _ => Err(err!("Unexpected character")),
        }
    }
	...
}
```
デシリアイズごとに次のデシリアライズ単位まで文字列を消費するのでこのように最初の一文字を見れば型をある程度決定できます。とりあえず実装が簡単な`bool`と`()`型はデシリアライザを書いておきました。

それ以外のデシリアライズについて以下で解説します。

# 数字のパース
まず数字からです。
```rust
impl<'de> JsonDeserializer<'de> {
    pub fn parse_u64(&mut self) -> u64 {
        let mut num = 0;
        while let Ok('0'..='9') = self.peek_char() {
            num *= 10;
            num += self.next_char().unwrap().to_digit(10).unwrap() as u64;
        }
        num
    }
    pub fn parse_i64(&mut self) -> Result<i64> {
        let mut num: i64 = 0;
        self.next_char().unwrap();
        if let Ok('0'..='9') = self.peek_char() {
            return Err(err!("Expected number"));
        }
        while let Ok('0'..='9') = self.peek_char() {
            num *= 10;
            num += self.next_char().unwrap().to_digit(10).unwrap() as i64;
        }
        Ok(num)
    }
}
```
今回はu64とi64に決め打ちしていますが実際に実装するときはきちんと切り替えられるようにしたほうがいいでしょう。

# 文字列のパース
文字列のパースは他とは違い、ライフタイムのことを考えなければいけません。デシリアライザのライフタイムについては詳しく[serdeのドキュメント](https://serde.rs/lifetimes.html)に書いてあります。とは言っても今回は呪文のように`'de`を付けるだけです。

また、エスケープのことを考えなければなりません。これは難しいのでとりあえず考えないことにしましょう(serdeのサンプルコードもそう言ってる)。

ref: [L123](https://github.com/serde-rs/example-format/blob/54c5393580aa63465c5d6965e583a39e9ab4c0d3/src/de.rs#L123)
```rust
    pub fn parse_string(&mut self) -> Result<&'de str> {
        if self.next_char()? != '"' {
            return Err(err!("Expected string"));
        }
        match self.input.find('"') {
            Some(len) => {
                let s = &self.input[..len];
                self.input = &self.input[len + 1..];
                Ok(s)
            }
            None => Err(err!("Unexpected EOF")),
        }
    }
```

# 配列のパース
配列は若干特殊で、visitorに[`SeqAccess` trait](https://docs.rs/serde/latest/serde/de/trait.SeqAccess.html)を実装した構造体を`visitor.visit_seq`に与えることでデシリアライズを行います。このトレイトで実装しなければならないのは`next_element_seed`メソッドのみです。
serdeのドキュメントの例では`CommaSeparated`という構造体に実装されています。

ref: [L503](https://github.com/serde-rs/example-format/blob/54c5393580aa63465c5d6965e583a39e9ab4c0d3/src/de.rs#L503),[L359](https://github.com/serde-rs/example-format/blob/54c5393580aa63465c5d6965e583a39e9ab4c0d3/src/de.rs#L359)
```rust
pub struct CommaSeparated<'a, 'de: 'a> {
    de: &'a mut JsonDeserializer<'de>,
    first: bool,
}

impl<'a, 'de> CommaSeparated<'a, 'de> {
    fn new(de: &'a mut JsonDeserializer<'de>) -> Self {
        CommaSeparated { de, first: true }
    }
}

// `SeqAccess` is provided to the `Visitor` to give it the ability to iterate
// through elements of the sequence.
impl<'de, 'a> SeqAccess<'de> for CommaSeparated<'a, 'de> {
    type Error = Error;

    fn next_element_seed<T>(&mut self, seed: T) -> Result<Option<T::Value>>
    where
        T: DeserializeSeed<'de>,
    {
        // Check if there are no more elements.
        if self.de.peek_char()? == ']' {
            return Ok(None);
        }
        // Comma is required before every element except the first.
        if !self.first && self.de.next_char()? != ',' {
            return Err(err!("Expected array comma"));
        }
        self.first = false;
        // Deserialize an array element.
        seed.deserialize(&mut *self.de).map(Some)
    }
}

impl<'de> JsonDeserializer<'de> {
    pub fn parse_deserialize_seq<V>(&mut self, visitor: V) -> Result<V::Value>
    where
        V: Visitor<'de>,
    {
        // Parse the opening bracket of the sequence.
        if self.next_char()? == '[' {
            // Give the visitor access to each element of the sequence.
            let value = visitor.visit_seq(CommaSeparated::new(self))?;
            // Parse the closing bracket of the sequence.
            if self.next_char()? == ']' {
                Ok(value)
            } else {
                Err(err!("Expected array closing bracket"))
            }
        } else {
            Err(err!("Expected array opening bracket"))
        }
    }
}


```
`CommaSeparated`には`Deserializer`への参照が保持されており、そのライフタイムは`'de: 'a`、つまり`'de`より短い間有効です。これは直感的に納得できるのではないかと思います。

`next_element_seed`は配列の各要素をデシリアライズするために呼ばれます。`seed: DeserializeSeed`という値が渡されるため、この`seed.deserialize`に文字列を与えることでデシリアライズされた要素の中身を得ることができます。
# 構造体のパース
構造体も配列と同様ですが、今度は[`MapAccess` trait](https://docs.rs/serde/latest/serde/de/trait.MapAccess.html)を実装する必要があります。実装しなければいけないメソッドは`next_key_seed`と`next_value_seed`です。

一つのマップ状要素(Key-Value)のそれぞれについて`next_key_seed → next_value_seed`の順に呼ばれます。

serdeの例では、先程の配列のパースの時に`CommaSeparated`という概念として構造体を抽象化したのでそれを再利用しています。賢い

ref: [L539](https://github.com/serde-rs/example-format/blob/54c5393580aa63465c5d6965e583a39e9ab4c0d3/src/de.rs#L539),[L407](https://github.com/serde-rs/example-format/blob/54c5393580aa63465c5d6965e583a39e9ab4c0d3/src/de.rs#L407)
```rust
impl<'de, 'a> MapAccess<'de> for CommaSeparated<'a, 'de> {
    type Error = Error;

    fn next_key_seed<K>(&mut self, seed: K) -> Result<Option<K::Value>>
    where
        K: DeserializeSeed<'de>,
    {
        // Check if there are no more entries.
        if self.de.peek_char()? == '}' {
            return Ok(None);
        }
        // Comma is required before every entry except the first.
        if !self.first && self.de.next_char()? != ',' {
            return Err(err!("Expected map comma"));
        }
        self.first = false;
        // Deserialize a map key.
        seed.deserialize(&mut *self.de).map(Some)
    }

    fn next_value_seed<V>(&mut self, seed: V) -> Result<V::Value>
    where
        V: DeserializeSeed<'de>,
    {
        // It doesn't make a difference whether the colon is parsed at the end
        // of `next_key_seed` or at the beginning of `next_value_seed`. In this
        // case the code is a bit simpler having it here.
        if self.de.next_char()? != ':' {
            return Err(err!("Expected map colon"));
        }
        // Deserialize a map value.
        seed.deserialize(&mut *self.de)
    }
}

impl<'de> JsonDeserializer<'de> {
    pub fn parse_deserialize_map<V>(&mut self, visitor: V) -> Result<V::Value>
    where
        V: Visitor<'de>,
    {
        // Parse the opening brace of the map.
        if self.next_char()? == '{' {
            // Give the visitor access to each entry of the map.
            let value = visitor.visit_map(CommaSeparated::new(self))?;
            // Parse the closing brace of the map.
            if self.next_char()? == '}' {
                Ok(value)
            } else {
                Err(err!("Expected map closing brace"))
            }
        } else {
            Err(err!("Expected map opening brace"))
        }
    }
}
```
keyとvalueそれぞれでシリアライズするということ以外は配列の時と大体同じです。

# 試してみる
では実際にこれがちゃんと動くか試してみましょう。
```rust:main.rs
use serde::Deserialize;
use serde_deserializer_2::from_str;

fn main() {
    #[derive(Deserialize, PartialEq, Debug)]
    struct Test {
        key: String,
        array: Vec<u64>,
    }

    let j = r#"{"key":"value","array":[1,2,3]}"#;

    let expected = Test {
        key: "value".to_string(),
        array: vec![1, 2, 3],
    };
    assert_eq!(expected, from_str(j).unwrap());
}
```

```
$ cargo run
   Compiling serde-deserializer-2 v0.1.0 (/home/nazo/dev/playground/serde-deserializer-2)
    Finished dev [unoptimized + debuginfo] target(s) in 0.15s
     Running `target/debug/serde-deserializer-2`


```
正しそうですね！
# 最後に
スペースとか改行とか考えなければならないことはまだまだありますが、これでserdeの`Deserializer`を書く上で主となる要素はある程度カバーできたのではないかと思います。何か参考になれば幸いです。

また、自分としても正直理解が怪しいところもあり、間違った解釈をしている可能性があるのでそういう箇所があれば是非教えていただけると助かります。

> この記事は [https://note.nazo6.dev/blog/serde-deserializer-2](https://note.nazo6.dev/blog/serde-deserializer-2) とのクロスポストです。