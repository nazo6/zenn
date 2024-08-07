---
published: true
type: idea
topics:
  - Rust
  - keyball
emoji: ⌨
title: RustとEmbassyでKeyballのファームウェアを作った
---
# はじめに
以前[RustでKeyballのファームウェアを書きたい話](https://zenn.dev/nazo6/articles/keyball-firmware-rust)で、ATMega32U4向けのファームウェアの作成をRustで試みたという話を書きましたが、結論から言うとこれは諦めてProMicro RP2040向けのファームウェアをRustで書くことにしました。

理由は当該記事に既にちらっと書いているのですが
- USBの謎バグを解決できなかった
- さすがにメモリサイズが小さすぎる
- RP2040であればEmbassyが対応している
というのが大まかなものになっています。

今回は純正品ではなくAliExpressで互換品を購入したのですが、これは16MBのフラッシュメモリを積んでおりもはや容量の心配はゼロです。
また、Rustの組み込み向け非同期フレームワーク[Embassy](https://embassy.dev)がRP2040をサポートしており、Rustのasync/await機能を使った開発ができます。
とまあこのようにRP2040搭載ボードを使うことで開発が大幅に楽になりそうだったのでこのような選択となりました。
また、今回購入したボード一つ1000円もせず非常に安価なことも決め手の一つでした。

そんなわけでRP2040向けのファームウェアをちまちま作ってきたのですが、一応キーボードとして使えるぐらいのところまでは持ってこれたので行ってきたことをまとめておこうと思います。

# 作ったもの
実際に作ったもののリポジトリはこちらになります。

https://github.com/nazo6/keyball-embassy-rp2040

主に実装した物としては
- キースキャン
- マウス
- OLEDディスプレイ
- LED(とりあえず自動マウスレイヤで光るだけ)
- 分割キーボードの通信
- レイヤシステム(本当に一部だけ)
- 自動マウスレイヤ
などです。

## 試し方
:::message
使えないことはないレベルにはなりましたがまだ色々とバグがありレイヤ機能がまだ実装途中なので実用はちょっと厳しいかもしれないです。
:::

READMEに書いている通りに`elf2uf2-rs`をインストールしてProMicroを接続し`cargo run`をすれば実行できます。分割キーボードとして使いたれば両側に行う必要があります。
通常のProMicroではなくRP2040版ProMicro(かその互換ボード)が必要です。

今のところKeyball61専用です。`src/constants.rs`を適切に変更すれば恐らく動くと思いますが持っていないので検証はできません。

# このファームウェアのアピールポイント
- Rust製！

…残念ながら今のところ公式のものよりこちらのファームを使うべき理由があるほど完成はしてません。

しかしながらRustとasync/awaitを用いて書くことでQMKよりはわかりやすいであろうコードになっているので(主観)、1から自作キーボードのファームを作りたいという方には参考になるのではないかと思います。
# 苦労話
苦労したところです。
## Duplex Matrix
まずキースキャン部を作り始めたわけですが、その時はマトリックススキャンというものがあるなどとは露知らず、まず思ったのが「あれ？どうやって全キースキャンするんだろう…」ということでした。30キーに対してCOL0~3、ROW0~4のピンしかありません。3x4でも全く足りないじゃん。というわけで調べた結果KeyballはDuplex matrixという方法でスキャンを行っているということを知りました。

https://e3w2q.github.io/8/

https://voyage4bliss.com/what-is-duplex-matrix/

ただ一度理解してしまえば実装はそこまで難しくはなく、以下のように実装することができました。

https://github.com/nazo6/keyball-embassy-rp2040/blob/master/src/driver/common/keyboard/mod.rs

## ボード間の通信
Keyballでは、3極のTRSケーブルで分割キーボード間の通信を行います。一つはV+、一つはGNDなので実質通信に使える線は一本だけということになります。また、繋がっているピンも一つだけです。この実装がなかなか大変でした。

自分も調べるまで知らなかったのですが、このようなカスタムの通信機能を実装するために、RP2040にはPIOというものが搭載されています。これは小さいCPUのようなもので、プログラムを書き込むことができます。また、メインのプログラムからアクセスできるキューとGPIOにアクセスできる機能を持ちます。
つまりどういうことかと言うと、送られてきたデータに合わせてGPIOのHigh/LowをカチカチしたりFIFOキューに書き込むようなプログラムをPIOで実行させ、CPUの負荷なくデータ送受信処理を行えるということです。

長々と書いてしまいましたが、このPIOのアセンブリを書いて半二重通信を行うというのがこのファームウェアの制作で一番大変なところでした。[QMKのコード](https://github.com/qmk/qmk_firmware/blob/de4d28cd6065058057535aac168d48bd734f2adc/platforms/chibios/drivers/vendor/RP/RP2040/serial_vendor.c)などを参考にしてなんとか実装しましたが、通信が不安定だなと感じる瞬間がたまにあるのでなるべく早く直したいです。
## キーマップ機能
これはハードウェアの都合で難しいというよりは、同時押しなどのステートフルな処理を実装するのに結構苦労している感じです。
TapとHoldぐらいなら簡単だろと思いきやQMKで言うところのPERMISSIVE_HOLDとかHOLD_ON_OTHER_KEY_PRESSなどを考えると頭が爆発しそうになりQMKの偉大さを実感しました。

# 今後の展望
基本的なキーボードの機能の実装は完了したので今後はレイヤ機能などをきちんと作りこんだ後に[Vial](https://get.vial.today)(Remapみたいなやつ)の対応や、Keyball61以外のサポートをやりたいです。

また、EmbassyにはBLE Micro Proに搭載されている[nrfプロセッサのサポート](https://docs.embassy.dev/embassy-nrf/git/nrf51/index.html)もあるので、いつかこちらに移植できたらいいなーと考えています。
# 感想
## Rust
Rustでの開発は非常に快適でした。Rustのモダンな言語機能が使えるのはもちろんのこと、コミュニティ全体でなるべくno_stdで利用しようという意識があるのか様々なクレートで`std`featureを外すことができたり、`heapless`などの様々な`no_std`用便利クレートもあります。

また、各デバイス向けの抽象化レイヤがうまく機能していると感じました。例えば[embedded-hal](https://github.com/rust-embedded/embedded-hal)は組み込みデバイス向けの抽象化トレイトを提供しており、Embassyが提供するモジュールも基本的のこのトレイトを実装しているため、`embedded-hal`に対応しているクレートならEmbassyと一緒に使うことも容易です。
さらに、[embedded-graphics](https://github.com/embedded-graphics/embedded-graphics)という組み込み向けディスプレイの抽象化もあり、Keyballに搭載されている[ssd1306を扱うためのクレート](https://docs.rs/ssd1306/latest/ssd1306/)も対応しています。
## 先駆者
今回この開発をしていて感じたのが、思ったよりもRustでキーボード開発してる人が多いということです。
GitHubで検索をかけると基板から自作したキーボードのファームをRustで書いているようなものも数多く見つけられました。
また、[rmk](https://github.com/haobogu/rmk)や[rumcake](https://github.com/Univa/rumcake)など今回自分がしたことの上位互換みたいなことをやっているのを見つけたりして途中で若干やる気を無くしてしまったぐらいには想像よりも開拓されている領域でした。
## Embassy
最後にEmbassyについて。実はEmbassyはつい最近までstable Rustで使えず、crates.ioにも無い状態でした。それが最近[embedded-halのv1がリリースされた](https://blog.rust-embedded.org/embedded-hal-v1/)ことやトレイトでの非同期関数のサポートの安定化により[ついに最初のバージョンがcrates.ioにリリースされました](https://embassy.dev/blog/embassy-hals-released/)。

このように今は組み込みRustが過渡期にありますが、なるべく互換性を保つためにEmbassyの各モジュールは`embedded-hal`と`embedded-hal-async`の両方を実装するといった工夫が成されています。

さて、Embassyの一番のウリはその名前にもある通り、asyncをサポートしていることです。asyncを用いることで非同期コードを直感的に書くことができます。

Rustのasync/await機能は柔軟性を高めるためにエクゼキュータを持っておらずtokioなどの外部ライブラリが必要で、そのために分かりづらいと言われがちなことで有名です(？)。
しかしEmbassyはまさにその柔軟性を生かしたライブラリとなっており、Rustの非同期がヒープすら必要としないのでこのように組み込み環境でも使用できるわけです。

そんなEmbassyを用いた開発体験は非常に良いです。async/awaitを用いることで並列処理を容易に記述することができますし、`embassy-time`や`embassy-sync`など便利なクレートが沢山用意されています。また、`embassy-usb`にはUSBやUSB HIDの実装が含まれていて非常に便利です。実際、USB関連のコードは今回ほとんど何も書いていません。

さらに、EmbassyのRP2040向けHALの[`embassy-rp`](https://docs.embassy.dev/embassy-rp/git/rp2040/index.html)には先述したPIOも含め必要な機能が網羅されており、「あれができない…」みたいなことは今回は特にありませんでした。
(ただ、embassy-syncのMutexの実装が怪しいのかその辺で落ちたりすることは多少ありましたが…)

embassyのasyncコード例として、実際の処理のメインループ部分は以下のようになっています。

https://github.com/nazo6/keyball-embassy-rp2040/blob/eed7ac8103418663ac86ae51a1064946e56b02c9/src/task/core_task/master/main_loop.rs#L97-L144

どうでしょうか。ハードウェアに近い層を触る時の面倒なあれこれをあまり感じずにわかりやすいコードになっているのではないでしょうか。また、`embassy_futures`のjoinやselect、`embassy_sync`のchannelやsignalを使うことでstd環境に近い開発体験を得ることができています。
# 最後に
なんだか自作キーボードの話というよりRustの良さを力説するような記事になってしまいましたが、今回初めてKeyballという自作キーボードを買ってRustを使って自分でファームウェアまで作れたことは非常に楽しい経験になりました。是非みなさんもファームウェア自作にチャレンジしてみてはいかがでしょうか。

> この記事は [https://note.nazo6.dev/blog/keyball-embassy-rp2040](https://note.nazo6.dev/blog/keyball-embassy-rp2040) とのクロスポストです。