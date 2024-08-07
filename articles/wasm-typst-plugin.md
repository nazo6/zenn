---
published: true
type: tech
topics:
  - typst
  - Rust
  - webassembly
emoji: 💭
title: WASMでTypstプラグインを作ろう
---
最近なんだか話題ですね、Typst。その簡潔な構文や環境構築の容易さが注目されているのだと思います。
そんなTypstですが、プラグインシステムを備えており、WASMを使って拡張することが可能です。

https://typst.app/docs/reference/foundations/plugin

[公式のパッケージリスト](https://typst.app/docs/packages/)に掲載されているパッケージの中にも内部でWASMプラグインを使用しているものが既に多々あります。例えばQuickJSを利用してJavaScriptを実行する「[Jogs](https://github.com/typst/packages/tree/main/packages/preview/jogs/0.2.3)」やMarkdownをTypstに変換する「[cmarker](https://github.com/typst/packages/tree/main/packages/preview/cmarker/0.1.0)」、さらにはLaTeXをTypst構文に変換して表示する(!)「[mitex](https://github.com/mitex-rs/mitex)」なんていうものもあります。

この記事ではRustを使ってTypstのプラグインを作成します。Typst自体もRustで作られているためRustの環境がよく整備されていますが、もちろんWASMにコンパイルできる言語であればどのような言語も使用可能です。ただし、WASIはサポートされていないため、WASIが必須な言語やライブラリを使用する際には[wasi-stub](https://github.com/astrale-sharp/wasm-minimal-protocol?tab=readme-ov-file#wasi-stub)を使用する必要があります。

ZigとCの例が[ここ](https://github.com/astrale-sharp/wasm-minimal-protocol/tree/master/examples)にある他、その他の言語でも[Typstのwasm protocol](https://typst.app/docs/reference/foundations/plugin#protocol)に従って関数をエクスポートすることでTypstプラグインを作成できます。

基本的なRustの知識があることを前提にしています。

:::message
プラグインとパッケージ

Typstでのプラグインというのは`wasm`ファイルのことを指します。一方、パッケージはプラグインをロードする処理などが記述された`typ`ファイルなどを含んだ一連のファイル群のことを指します。パッケージは`wasm`ファイルを含んでいる必要はありません。
:::
# Greetプラグイン
 まずは`Hello {name}`という文字列を出力するだけのプラグインを作ります。
```
cargo new --lib typst-greet
rustup target add wasm32-unknown-unknown
```
を実行してRustのプロジェクトを作り、wasmにビルドできるようにしておきましょう。
次に`Cargo.toml`に以下を追記します。
```toml:Cargo.toml
[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-minimal-protocol = { git = "https://github.com/astrale-sharp/wasm-minimal-protocol/" }
```
`crate-type = ["cdylib"]`はwasmにビルドするのに必要です。また、[`wasm-minimal-protocol`](https://github.com/astrale-sharp/wasm-minimal-protocol)クレートでは、関数を先述したプロトコルに合うように変換してくれるマクロを提供してくれています。
また、`.cargo/config.toml`ファイルを作成し、デフォルトでwasmがコンパイルされるようにしておきます。

```toml:.cargo/config.toml
[build]
target = "wasm32-unknown-unknown"
```

次に`lib.rs`を以下のように書き換えます。
```rust:src/lib.rs
use wasm_minimal_protocol::*;

initiate_protocol!();

#[wasm_func]
pub fn greet(name: &[u8]) -> Vec<u8> {
    [b"Hello, ", name, b"!"].concat()
}
```
`initiate_protocol!()`を実行した後、`wasm_func`アノテーションを関数に付与することでマクロがよしなに関数をTypst向けにエクスポートしてくれます。
Typstプラグインは基本的にバイト列を受け取りバイト列を返すことしかできません。ただし戻り値には`Result`typeを使うこともできます。詳しくは[`wasm-minimal-protocol`のサンプル](https://github.com/astrale-sharp/wasm-minimal-protocol/blob/master/examples/hello_rust/src/lib.rs)を見ていただければわかると思います。

最後に以下のコマンドでビルドします。
```
cargo build --release
```
`target`ディレクトリ内にwasmが生成されたはずです。では実際にTypstで読み込んでみましょう。以下のようなTypstファイルを作成します。
```typst:sample.typ
#let plugin = plugin("./target/wasm32-unknown-unknown/release/typst_greet.wasm")

#let greet(name) = str(
  plugin.greet(
    bytes(name),
  )
)

#greet("typst")
```
プラグインはバイト列を受け取りバイト列を返すので、引数は`bytes()`で変換して渡し戻り値は`str()`関数で文字列に戻します。

これを
```
typst compile sample.typ
```
でコンパイルすれば…
![](/images/blog/2024/02/typst-plugin/sample1.png)
このようなpdfファイルが生成されているはずです。非常に簡単ですね。

# Excel読み込みプラグイン
これだけでは面白くないのでもう少し実用的なものを作りましょう。

自分は表を作る時に雑にExcelで作ることが多いのですが、Typstでxlsxファイルは読み込めないのでCSVにいちいち変換しなければなりません。
これは面倒なのでxlsxファイルを直接読み込んでくれるTypstプラグインを作ろうと思います。

xlsxファイルを読み込むのは大変そうだな…と思った方もいるかもしれませんがそこはRust、[calamine](https://github.com/tafia/calamine)という素晴らしいクレートが存在します。これを使うことで手軽にxlsxの解析が行えます。

まずは前節と同様にRustプロジェクトを作成してから
```
cargo add calamine
```
で依存関係を追加し、以下のコードを`lib.rs`に書きます。
```rust:lib.rs
use calamine::{Reader, Xlsx, XlsxError};
use wasm_minimal_protocol::*;

initiate_protocol!();

fn parse_num(num: &[u8]) -> Result<usize, String> {
    std::str::from_utf8(num)
        .map_err(|e| format!("Invalid number: {e}"))?
        .parse()
        .map_err(|e| format!("Invalid number: {e}"))
}

#[wasm_func]
pub fn get_table(
    data: &[u8],
    sheet: &[u8],
    col: &[u8],
    row: &[u8],
    width: &[u8],
    height: &[u8],
) -> Result<Vec<u8>, String> {
    let sheet = std::str::from_utf8(sheet).map_err(|e| format!("Invalid sheet name: {e}"))?;
    let col = parse_num(col)?;
    let row = parse_num(row)?;
    let width = parse_num(width)?;
    let height = parse_num(height)?;

    let cursor = std::io::Cursor::new(data);
    let mut workbook: Xlsx<_> = calamine::open_workbook_from_rs(cursor)
        .map_err(|e: XlsxError| format!("Failed to open workbook: {e}"))?;
    let sheet_range = workbook
        .worksheet_range(sheet)
        .map_err(|e| format!("Sheet read error: {e}"))?;

    let mut lines = vec![];

    for r in row..row + height {
        let mut line = vec![];
        for c in col..col + width {
            if let Some(cell) =
                sheet_range.get_value((r.try_into().unwrap(), c.try_into().unwrap()))
            {
                line.push(cell.to_string());
            } else {
                line.push("null".to_string());
            }
        }
        lines.push(line.join("\t"));
    }

    Ok(lines.join("\n").into_bytes())
}
```

```typst:sample.typ
#let plugin = plugin("./target/wasm32-unknown-unknown/release/typst_excel.wasm")

#let get_table(file, sheet, col, row, width, height) = csv.decode(
  plugin.get_table(
    read(file, encoding: none),
    bytes(sheet),
    bytes(str(col)),
    bytes(str(row)),
    bytes(str(width)),
    bytes(str(height))
  ),
  delimiter: "\t"
)

#table(
  columns: 4,
  ..get_table("Book1.xlsx", "Sheet1", 1, 1, 4, 10).flatten()
)
```
ソースコードを見てもらえれば大体何をしているのかわかると思います。
ポイントとしては、TypstのWASM環境は完全に外部と分離されているため、外部のファイルにアクセスするために`.typ`ファイルのほうでxlsxファイルをバイト列として読み込みそれをプラグインに渡しています。
プラグイン側ではxlsxデータを読み込み、指定された範囲のデータをtsv形式で返しています。
CSVやTSVはTypstで読み込めるため後は自由にデータを弄ることができます。

では以下のような`Book1.xlsx`を作って`typst compile`を実行してみましょう。
![](/images/blog/2024/02/typst-plugin/sample2_book.png)
するとこのように期待通りの表が得られました！
![](/images/blog/2024/02/typst-plugin/sample2_pdf.png)
少し意外だったのですがxlsxって計算結果もファイルの中に保持してあるんですね。これは嬉しい。数式を取りたければコード内の`worksheet_range`を`worksheet_formula`に変えればよさそうです。

# 最後に
いかがでしたか？かなり簡単にTypstのプラグインを作成できることがお分かり頂けたかと思います。既存の言語のエコシステムを使って比較的容易に複雑なプラグインを開発することができることはTypstの大きな利点になると思いました。

ちなみに、パッケージを作ったら[`typst/packages`](https://github.com/typst/packages)リポジトリにPRを送ることで公式のプラグインリストに載り、`import "@preview/..."`でインポートできるようになります。

参考:

https://zenn.dev/mkpoli/articles/7e54c1c780ff43

また、今回使用したソースコードは

https://github.com/nazo6/playground/tree/main/typst-plugin

で公開しています。

是非みなさんもTypstプラグインを作ってみてください。

> この記事は [https://note.nazo6.dev/blog/wasm-typst-plugin](https://note.nazo6.dev/blog/wasm-typst-plugin) とのクロスポストです。