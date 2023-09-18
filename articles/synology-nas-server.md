---
published: true
created: 2023-07-17T20:12:12+09:00
updated: 2023-07-17T20:12:32+09:00
tags:
  - tech/synology
type: idea
slug: synology-nas-server
topics:
  - NAS
emoji: 📄
title: Synology NASをサーバーとして運用してみたメリット・デメリット
---> この記事は[https://knowledge.nazo6.dev/blog/Synology NASをサーバーとして運用してみたメリット・デメリット](https://knowledge.nazo6.dev/blog/2023/07/17/Synology%20NAS%E3%82%92%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%81%A8%E3%81%97%E3%81%A6%E9%81%8B%E7%94%A8%E3%81%97%E3%81%A6%E3%81%BF%E3%81%9F%E3%83%A1%E3%83%AA%E3%83%83%E3%83%88%E3%83%BB%E3%83%87%E3%83%A1%E3%83%AA%E3%83%83%E3%83%88)とのクロスポストです。



# はじめに
自分はSynology製のNASのDS720をNASとして以外にLinuxサーバーとして動かしています。運用し始めてから数ヵ月たって色々わかってきたので普通にLinuxサーバーを建てるのと比べてどんなメリット・デメリットがあるのかまとめようと思います。

## メリット
## 1. NASとして使える
まあ当たり前なのですが本来NASとして使われるものなのでNAS用のソフトウエアなどは充実しています。特にHyper Backupなど専用ソフトウエアの出来は結構良いと感じています。

## 2. Synology製ソフトウエアが充実している
NASをGoogle Driveのような感覚で使えるようにするSynology DriveやこれもまたGoogle Photoの代替であるSynology Photosなどのソフトウエアが使えます。
Synology製のソフトを使わなくともこれらに相当するオープンソースのソフトは色々あるにはあり、そちらも色々と試してみました(Nextcloludとかimmichとか)。ただ個人で動かすにはオーバースペックすぎて扱いづらいとかハマる所があったりだとかで若干辛い思いもしました。
Synology純正はやはり専用ソフトウエアなのでインストールも手軽ですしあまり重量級すぎるわけでもなく使いやすいです。

## 3. Dockerが動かせるので大抵の物は動く
一定以上のグレードのSynology NASには`Container Manager`というものがインストールできます。要するにDockerです。
最近は大抵のソフトウエアはDockerで動かせるように提供されているので「普通のLinuxなら動かせるのにSynology NASでは動かせないよ~」ということは**ほぼ**ありません。

## 4. (一人しか使わないなら)CPUの性能は意外と足りる
Dockerコンテナが30個ぐらい動いていますが、レスポンスが遅くて不便だと感じることはあまりないです。
ただ、何人も同時にアクセスするような環境ではまた別だと思います。あとメモリの増設は必要です。

# デメリット
## 1. いわゆる一般的なLinuxではない
DSM(SynologyのOS)はLinuxベースではありますが一般的なLinuxとはディレクトリ構成が違ったりします。なので通常の知識が使えないことは多いです。

## 2. カーネル(やその他諸々)が古い
```sh
$ uname -r
4.4.302+
```
メリットの所で**ほぼ**動かせないものはないと書きましたが、たまーにネックになるのがこれです。具体的には自分は`wireguard`が入っていないことに苦しみました。
まあNASというのは安定性が何よりなので安易にカーネルのバージョンを上げられないのは理解はできますが新しいカーネルに依存したものは動かせないかもねということは頭に入れておく必要があります。

## 3. ハードウエア構成に制限がある
自分が所持しているDS720にはSSDスロットが2つついているのですが、それらはなんとストレージとして使うことはサポートされておらず、キャッシュとして使うことしかできません。
「サポートされていない」だけなので使おうとすれば使えるのですがDSMをアプデして再起動するとSSDストレージを認識しなくなっているなどのことがありました。
また、Synology純正のメモリやストレージを入れていると警告を出してきたりと不自由さを感じる場面が多かったです。

# 結論
結論としては、「NASとして見れば満足だがサーバー機として見れば物足りない」と感じています。
NASとしての完成度は一級品で、あまり変なことをせずSynologyの言うことに従っていれば不便さを感じる場面はほぼないのではないかと思います。
ただ、道から外れるようなことをすると急に辛くなるなと感じました。まあ、本来の用途として想定されていないので当然と言えば当然なのかもしれませんが…