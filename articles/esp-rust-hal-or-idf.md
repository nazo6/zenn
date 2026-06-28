---
published: true
type: tech
topics:
  - ESP32
  - Rust
emoji: 🔀
title: Rust on ESP32ではesp-halとesp-idfのどちらを使うべきなのか
---

ESP32で使えるRust向けのHALは現在2種類開発されています。

@[card](https://github.com/esp-rs/esp-idf-svc)

@[card](https://github.com/esp-rs/esp-hal)

1つ目は[esp-idf-svc/hal](https://github.com/esp-rs/esp-idf-svc)です。こちらはEspressifによるESP-IDFというフレームワークをRustでも使えるようにしたものです。
2つ目は[esp-hal](https://github.com/esp-rs/esp-hal)です。これはベアメタルなRust向けのライブラリで、こちらの方が開発が活発です。というかesp-idf-svc/halの方はほとんど開発が止まっており、公式にはこちらを使うことが推奨されています。

# std vs no\_std

esp-idf-svcの一番大きな特徴として、Rustの`std`が使えることが挙げられます。通常組み込みRustではOSの機能に依存する`std`標準ライブラリは使えず、`core`と呼ばれるライブラリを使います。しかしながらesp-idf-svcでは、IDFの機能を用いて標準ライブラリを実装しています。そのため、タスクを並行実行したいなら`std::thread::spawn`を呼び出すだけでできてしまいます。
その他にもWiFiやBLEもIDFの機能を使って比較的用意に実装することが可能です。

一方、esp-halは`core`のみが使える`no_std`環境で使用することが想定されています。では並行タスクなどはどうするのか、RTOSは使うのかという話になりますが、Rustでは[embassy](https://github.com/embassy-rs/embassy)というフレームワークを使うのが一般的です。これはRustの言語機能である非同期機能を使ってタスクを実行します。Embassyについて詳しくは[この記事](https://zenn.dev/nazo6/articles/keyball-embassy-rp2040)などを参考にしてください。慨して非常に書きやすく良いフレームワークです。

# どちらを使うべきなのか

では、どちらを使うべきなのかという話になりますが、「基本的には」esp-halを使うべきだと思います。esp-idf-svc/halはstdが使えるので一見初心者向けのような気もしますが、以下のような気に入らない点があります。

- svc/halでサポートされている機能ならば良いが、結局のところFFIなので時には[esp-idf-sys](https://github.com/esp-rs/esp-idf-sys)を使ってunsafeなコードを書く必要がある
- トラブル時にIDFの方を疑う必要がある
- IDFの設定フレームワークがCargoとうまく連携しないことがある
  - それによってコンパイルが通らないとかLSPが動かないなどの事象が発生する
  - また、コンパイル速度も遅い
- esp-halよりもasyncサポートが弱い
  - 基本的にesp-halはembassyを念頭に置いて開発されているため、asyncサポートが充実
  - 一方、esp-idf-halでは例えばSPIは非同期ドライバが実装されているがI2Cにはされていない
- いくらRTOS上とは言え結局MCU上なのだから変にstdによる抽象化をすると逆に何が起こっているか分かりづらい

一方、現状では「esp-halではできないこと」が存在しているのも事実であり、このような場合にはIDF系を使ったほうが良いです。

- esp-halで実装されていないドライバを使いたい場合
  - 例えば執筆時点だとSDIOドライバがない(ただし開発中のようではある)
- 消費電力を最大限まで抑えたい場合
  - ESP-IDFでは、esp-halには(まだ)実装されていない自動ライトスリープや動的周波数調整などの高度な電力管理機能が実装されている
  - 特に無線を用いる場合には差が顕著に出る
- Rustエコシステムが発達していない機能を使いたい場合
  - 例えば、SDカードを使いたい場合には、Rustでも[embedded-fatfs](https://github.com/MabezDev/embedded-fatfs)などの実装があるにはあるが、esp-idf-sysで提供されている`std::fs`から使える仮想ファイルシステムのほうが使い勝手もパフォーマンスも良い
- [ESP Component Registry](https://components.espressif.com/)を使いたい場合
  - esp-idf-svcにはESP Component Registryを使うための機能があり、自動でライブラリを取得してバインディングの生成まで行ってくれる

このようにまだ機能面ではIDF系が勝っているのは事実ですが、esp-halはEspressif公式が関与するようになったこともあってか最近急速に開発が進んでいます。例えば無線系だとBLEは[trouble](https://github.com/embassy-rs/trouble)、WiFiは[embassy-net](https://docs.embassy.dev/embassy-net/0.9.0/default/index.html)などのRust製スタックを使うことができます。なので将来的にはこれらのesp-halでできないことも解消されるのではないかと期待しています。


> この記事は[個人ブログ](https://nazo6.dev/blog/article/esp-rust-hal-or-idf)とクロスポストしています。