---
published: true
type: idea
topics:
  - Synology
emoji: 💭
title: Synology NASへのHomebrew(linuxbrew)を使ったNeovimのインストール
---

> この記事は [https://note.nazo6.dev/blog/synology-nas-homebrew](https://note.nazo6.dev/blog/synology-nas-homebrew) とのクロスポストです。


# 概要
Synology NASにいろんなツールをインストールしたいとき(まあ本当はしないほうがいいんですが)、Entwareと呼ばれるツールを使うのが一般的だと思われます。
しかしながら、Entwareはリポジトリが小さく古めなため他に使えるパッケージマネージャがないかと調べていたところ、Homebrewをインストールできるという情報を見かけて試してみました。
このbrewを使ってneovim nightlyをSynology NASにインストールしたいと思います。

# Homebrewのインストール
まあ↓の記事にある通りなのですがやっていきます。

https://community.synology.com/enu/forum/1/post/153781

## 1. `ldd`コマンドの作成
homebrewインストール時に`ldd --version`を実行するみたいですがsynology nasには這ってないので無理やり作ります。
```sh:/usr/bin/ldd
#!/bin/bash  
[[ $(/usr/lib/libc.so.6) =~ version\ ([0-9]\.[0-9]+) ]] && echo "ldd ${BASH_REMATCH[1]}"
```

## 2. `/home`へのホームディレクトリのマウント
どうやらbrewは`/home`に各ユーザのホームディレクトリがあることを想定しているみたいですがsynologyでは`/var/services/homes`にあるので色々うまくいかないみたいです。なので`/home`にマウントします。
```sh
sudo mkdir /home
sudo mount -o bind "/volume1/homes" /home
```
恐らく`mount`コマンドはタスクスケジューラでブート時に実行させてあげる必要があります。

## 3. brewのインストール
[Homebrew公式サイト](https://brew.sh/ja/)に書いてある通りコマンドを実行します。成功すれば`/home/linuxbrew/.linuxbrew/bin`に`brew`コマンドがあるはずです。

## 4. パスを通す
`/etc/profile`にPATHを追記しました。
```sh:/etc/profile
PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
```

# Neovimをインストール

:::message
本当はhomebrewでneovimのheadをインストールしたいと思っていたのですがビルドがコケまくるので諦めました。
代わりに[bob](https://github.com/MordechaiHadad/bob)というneovimのバージョンマネージャをbrewでインストールすることにしました。
:::

:::details brewでインストールしようとしていた記録の断片
## 1. gccのインストール
neovimのコンパイルにはgccが必要なのでインストールします。
```
brew install gcc
```

## 2. gccのsymlinkを作成

## 3. 依存関係のインストール

:::

次のコマンドでneovimがインストールできます。
```sh
brew install bob
bob install nightly
bob use nightly
```
インストールしたら、`~/.local/share/bob/nvim-bin`にPATHを通す必要があります。