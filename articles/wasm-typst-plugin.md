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
最近話題の組版システムのTypstですが、プラグインシステムを備えておりWASMを使って拡張することが可能です。

https://typst.app/docs/reference/foundations/plugin

プラグインを使うことで従来のTypst言語のみでは難しかった様々な処理を行うことができます。

[公式のパッケージリスト](https://typst.app/docs/packages/)に掲載されているパッケージの中にも内部でWASMプラグインを使用しているものがあります。例えばQuickJSを利用してJavaScriptを実行する「[Jogs](https://github.com/typst/packages/tree/main/packages/preview/jogs/0.2.3)」やMarkdownをTypstに変換する「[cmarker](https://github.com/typst/packages/tree/main/packages/preview/cmarker/0.1.0)」、さらにはLaTeXをTypst構文に変換して表示する(!)「[mitex](https://github.com/mitex-rs/mitex)」なんていうものもあります。

この記事ではRustを使ってTypstのプラグインを作成します。Typst自体Rustで作られているためRustの環境がよく整備されていますが、もちろんWASMにコンパイルできる言語であればどのような言語も使用可能です。ただし、WASIはサポートされていないため、WASIが必須な言語やライブラリを使用する際には[wasi-stub](https://github.com/astrale-sharp/wasm-minimal-protocol?tab=readme-ov-file#wasi-stub)を使用する必要があります。

ZigとCの例が[ここ](https://github.com/astrale-sharp/wasm-minimal-protocol/tree/master/examples)にある他、その他の言語でも[Typstのwasm protocol](https://typst.app/docs/reference/foundations/plugin#protocol)に従って関数をエクスポートすることでTypstプラグインを作成できます。

:::message
プラグインとパッケージ

Typstでのプラグインというのは`wasm`ファイルのことを指します。一方、パッケージはプラグインをロードする処理などが記述された`typ`ファイルなどを含んだ一連のファイル群のことを指します。パッケージは`wasm`ファイルを含んでいる必要はありません。
:::
# Greetプラグイン
 まずは`Hello {name}`という文字列を出力するだけのプラグインを作ってみましょう。
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
`crate-type = ["cdylib"]`はwasmにビルドするのに必要です。また、[`wasm-minimal-protocol`](https://github.com/astrale-sharp/wasm-minimal-protocol)クレートでは関数をTypstから呼び出すのに必要な諸々をやってくれます。
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
`initiate_protocol!()`を実行した後、`wasm_func`アトリビュートを関数に付与することで関数をTypstにエクスポートすることができます。
エクスポートされた`greet`関数では、バイト列として受け取った引数に`Hello, `を付加してそれをやはりバイト列として返しています。Rustには文字列を表す`String`型がありますが、`Vec<u8>`を返しているのは、Typstのプラグインができることは「バイト列を受け取ってバイト列を返すこと」だからです。(ただし将来的にはマクロを使って型の自動変換ぐらいはしてくれるようになるかも？例えば[`wasm-minimal-protocol`のサンプル](https://github.com/astrale-sharp/wasm-minimal-protocol/blob/master/examples/hello_rust/src/lib.rs)にあるように`Result`型は今でも使えるようです)

では実行するために以下のコマンドでビルドします。
```
cargo build --release
```
`target/wasm32-unknown-unknown/release`ディレクトリ内にwasmが生成されたはずです。では実際にTypstで読み込んでみましょう。作成プロジェクトのルートに以下のようなTypstファイルを作成します。
```typst:sample.typ
#let plugin = plugin("./target/wasm32-unknown-unknown/release/typst_greet.wasm")

#let greet(name) = str(
  plugin.greet(
    bytes(name),
  )
)

#greet("typst")
```
wasmファイルは`plugin`関数で読み込みこまれ、後は通常のメソッドのように使うことができます。ただし、バイト列を渡して受け取ることには注意が必要です。

これを
```
typst compile sample.typ
```
でコンパイルすれば…
![](/images/blog/2024/02/typst-plugin/sample1.png)
このようなpdfファイルが生成されているはずです。非常に簡単ですね。

# Excel読み込みプラグイン
これだけでは面白くないのでもう少し実用的なものを作りましょう。

自分は表を作る時に雑にExcelで作ることが多いのですが、Typstでxlsxファイルは読み込めないのでCSVにいちいち変換しなければならず面倒です。これを簡略化するためにxlsxファイルを直接読み込むTypstプラグインを作ってみましょう。

当然イチからxlsxファイルを読み込む処理を実装するのは非常に大変ですが、プラグインを作るのにRustが使えるということは当然Rustのエコシステムを使えるということです。Rustのエコシステムは結構豊富で、今回の目的にドンピシャな[calamine](https://github.com/tafia/calamine)というクレートを見つけました。Cのラッパーとかでもないのでビルドも難しい所はありません。

ということで実際にプラグインを作っていきましょう。まずは前節と同様に`cargo new`でRustプロジェクトを作成してから
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
`get_table`関数が実際の処理内容で、calamineクレートでバイト列として受け取ったxlsxファイルの内容を解析し、引数として指定された範囲の内容を読み取っています。
読み取ったデータはTypstで解析できるようにtsvの文字列として返しています。Typstの表データとして直接返せれば良いのですがそのような方法は今は無いようです。

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
そしてこちらが上のRustコードから生成されたプラグインWASMを実行するためのファイルです。Rust内の`get_table`関数にxlsxファイルの内容と引数を渡して実行し、tsvとしてパースすることでxlsxファイル内の値を表示しています。

では試しに以下のような`Book1.xlsx`を作って`typst compile`を実行してみましょう。
![](/images/blog/2024/02/typst-plugin/sample2_book.png)
するとこのように期待通りの表が得られました！
![](/images/blog/2024/02/typst-plugin/sample2_pdf.png)
今回始めて知ったのですがxlsxって計算結果もファイルの中に保持してあるんですね。数式を取りたければコード内の`worksheet_range`を`worksheet_formula`に変えればよさそうです。

### ファイルをプラグインから読み込めない理由
:::message
このセクションは別に読まなくてもいいです。
:::

先程のコードでは、わざわざTypstからファイルをバイト列として渡していましたが、TypstでWASIなどの仕組みをサポートすればRustから直接IOできたりして便利なのではないでしょうか？

そのようなことができない実際的な理由としては、「Typstがサポートしているwasm環境向けターゲットの`wasm32-unknown-unknown`ではファイルを読み込めないから」です。しかしながら、wasmターゲットがこれに限られておりWASMなどが使えないのは意図的な物だと考えられます。

というのもtypstの関数は全て純粋でなければならないからです。これによりドキュメントの再現性が確保され、高速な差分コンパイルが実現されています。ここでもしプラグインから外部にアクセスできてしまうと全く純粋ではなくなってしまうわけですね。

なので、プラグイン内で状態を保持することもできません。例えば以下のようなコードを考えてみましょう。
```rust
use wasm_minimal_protocol::*;

initiate_protocol!();

static mut COUNTER: u32 = 0;

#[wasm_func]
pub fn count() -> Vec<u8> {
    unsafe {
        COUNTER += 1;
    }
    format!("{}", unsafe { COUNTER }).into_bytes()
}
```
unsafeなどはとりあえず無視して頂くとこれは呼び出される度にCOUNTERを加算するコードなのですが、これをTypstから何回呼び出しても1が表示されます。

とまあ長々と書きましたが、実はこのことはTypstのドキュメントページに全部書いてあります。

# 最後に
いかがでしたか？とても簡単にTypstのプラグインを作成できることがお分かり頂けたかと思います。既存の言語のエコシステムを使って比較的容易に複雑なプラグインを開発することができることはTypstの大きな利点だと思います。

ちなみに、パッケージを作ったら[`typst/packages`](https://github.com/typst/packages)リポジトリにPRを送ることで公式のプラグインリストに載り、`import "@preview/..."`でインポートできるようになります。

参考記事:

https://zenn.dev/mkpoli/articles/7e54c1c780ff43

また、今回使用したソースコードは

https://github.com/nazo6/playground/tree/c0fb192f71e71fbbaafcc57673bdc4e931f3dd39/other/typst-plugin

で公開しています。

是非みなさんもTypstプラグインを作ってみてください。

> この記事は [https://note.nazo6.dev/blog/wasm-typst-plugin](https://note.nazo6.dev/blog/wasm-typst-plugin) とのクロスポストです。