---
published: true
type: idea
topics:
  - raspberrypi
emoji: 🥧
title: Raspberry Pi Zero 互換ボードの調査
---

Raspberry Pi Zero 2W向けのPCBを現在設計しているが、Pi Zero 2Wだとスペックが足りなそう…
ということで同じサイズで使えそうなSBCを探したのでメモ。

ちなみに、ほとんど技適を取ってないので実用上はほぼ選択肢がない。

# 一覧

以下は調べたボードの一覧です。Zeroサイズのものはほぼ網羅していると思います。

## Raspberry Pi Zero

| 項目   | 内容                     |
| ---- | ---------------------- |
| SoC  | BCM2835(1GHz,1コア), Arm |
| GPU  | Broadcom VideoCore IV  |
| 発売   | 2015/11, 2017/2(W)     |
| メモリ  | 512M                   |
| 無線   | BT/Wifi(Wモデルのみ,技適あり)   |
| 消費電力 | 150mA                  |
| 値段   | 3000程度(Wモデル)           |

- Vulkanなし
- さすがに今時これだと性能が厳しい

## Raspberry Pi Zero

| 項目   | 内容                                |
| ---- | --------------------------------- |
| SoC  | BCM2710A1(BCM2837)(1GHz,4コア), Arm |
| GPU  | Broadcom VideoCore IV             |
| 発売   | 2021/10                           |
| メモリ  | 512M                              |
| 無線   | BT/Wifi(技適あり)                     |
| 消費電力 | 200mA                             |
| 値段   | 3000程度(Wモデル)                      |

- Vulkanなし

## Orange Pi Zero 2W

| 項目   | 内容                  |
| ---- | ------------------- |
| SoC  | Allwinner H618, Arm |
| 発売   |                     |
| メモリ  | 1-4G                |
| 無線   | BT/Wifi(技適なしっぽい)    |
| 消費電力 | 200mA               |
| 値段   | 3000(1G)-6000(4G)   |

- 公式: <http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-Zero-2W.html>
- 技適さえあれば…
  - ちなみにOrange Pi Zero 2(Wなし)とか3は技適が通ってたりするみたい
    - <https://tech-blog.cerevo.com/archives/10944/>

## Radxa Zero 3W

| 項目   | 内容                 |
| ---- | ------------------ |
| SoC  | RK3566, Arm        |
| 発売   |                    |
| メモリ  | 1-8G               |
| 無線   | BT/Wifi(技適あるかも)    |
| 消費電力 |                    |
| 値段   | 4000(1G)-10000(8G) |

- ちなみにZero 3Wというのもあり、そちらは無線なしで代わりにイーサネットコネクタがついてる
- ドキュメントが割としっかりしている印象
- めっちゃ熱くなるというレビューをけっこう見かけるのが気がかり

## Radxa Cubie A7Z

| 項目   | 内容                  |
| ---- | ------------------- |
| SoC  | AllWinner A733, Arm |
| 発売   |                     |
| メモリ  | 1-8G                |
| 無線   | BT/Wifi(技適なさそう)     |
| 消費電力 |                     |
| 値段   | 2500(1G)-9000(8G)   |

- 発売されたばっかりなので全く情報がない

## Banana Pi M2 Zero

| 項目   | 内容                |
| ---- | ----------------- |
| SoC  | AllWinner H3, Arm |
| 発売   |                   |
| メモリ  | 512M              |
| 無線   | BT/Wifi(技適無さそう)   |
| 消費電力 |                   |
| 値段   | 3500              |

- Zero 2Wとほぼ同じ性能のような気がする。Vulkanも無さそうだし使う意味なし

## Banana Pi M4 Zero

| 項目   | 内容                  |
| ---- | ------------------- |
| SoC  | AllWinner H618, Arm |
| 発売   |                     |
| メモリ  | 2-4G                |
| 無線   | BT/Wifi(技適無さそう)     |
| 消費電力 |                     |
| 値段   | 6500(2G), 9000(4G)  |

- M2のアップグレード版っぽい。高い割にOrange Piと同じSoCだしあまり利点はなさそう？

## Luckfox Lyra Zero W

| 項目   | 内容              |
| ---- | --------------- |
| SoC  | RK3506B, Arm    |
| 発売   |                 |
| メモリ  | 512M            |
| 無線   | BT/Wifi(技適無さそう) |
| 消費電力 |                 |
| 値段   | 3500            |

- このSoCが何なのかがよくわからない
  - <https://wiki.luckfox.com/Luckfox-Lyra/Introduction>
- GPUは無い？

## (おまけ) Radxa Zero 2 Pro

| 項目   | 内容              |
| ---- | --------------- |
| SoC  | Amlogic A311d   |
| 発売   |                 |
| メモリ  | 4G              |
| 無線   | BT/Wifi(技適無さそう) |
| 消費電力 |                 |
| 値段   | 18000           |

- 高級路線っぽいもの
- **通常のZeroサイズが65x30なのに対し、これは65x35とちょっと大きいので互換性がない**

## (おまけ)RP2040 PiZero

| 項目   | 内容     |
| ---- | ------ |
| SoC  | RP2040 |
| 発売   |        |
| メモリ  |        |
| 無線   | なし     |
| 消費電力 |        |
| 値段   | 1500   |

- ZeroのサイズでRP2040を載せるという面白いやつ
- <https://www.switch-science.com/products/9440>
- 無線があれば使ってみたかったけどね…

## MangoPi MQ Pro

| 項目   | 内容                   |
| ---- | -------------------- |
| SoC  | AllWinner D1, RISC-V |
| 発売   |                      |
| メモリ  |                      |
| 無線   | BT/Wifi(技適無さそう)      |
| 消費電力 |                      |
| 値段   |                      |

- RISC-Vなのでまあ…

# 追記(26/2/3)

## Luckfox Pico Zero

| 項目   | 内容              |
| ---- | --------------- |
| SoC  | RV1106G3, Arm   |
| 発売   | 2025/08         |
| メモリ  | 256MB?          |
| 無線   | BT/Wifi(技適無さそう) |
| 消費電力 |                 |
| 値段   | $30             |

- <https://www.luckfox.com/Luckfox-Pico-Zero>
- GPUがないのが特徴

# 結論

技適を取っているもので考えると使えそうなのはオリジナルのPi Zero、Pi Zero 2WかRadxa Zero 3Wぐらいのよう。
Radxa Zero 3Wはかなり良いスペックで1GBモデルならばZero 2Wと値段も変わらないので良さそう。
また、Radxa Zero 3Wについても日本の代理店で販売しているものでないと技適が怪しいが、意外とアリエクなどと値段も変わらなそう。

また、ここで調査したものの他に、搭載している外部接続端子やソフトウェアサポートの面でも結構違いがあるのでぱっと見良さそうなものでもちゃんと調べたほうがいい。

## 参考記事

比較してるものとか

- <https://bret.dk/pi-zero-showdown/>
- <https://youtu.be/Fyet0-L1IWI>


> この記事は[個人ブログ](https://nazo6.dev/blog/article/rpi-zero-compatible-board)とクロスポストしています。