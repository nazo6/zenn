---
published: true
type: tech
topics:
  - Linux
emoji: 😀
title: Linuxで顔認証を動作させる
---

Linuxで、Windows Helloのように色々な所で顔認証を使う方法

# 1. Howdyをインストール

基本的にLinuxで顔認証したい場合は[howdy](https://github.com/boltgolt/howdy)を使う。これをまずはインストールする。ただし、リリース版は非常に古いため、git版を使うことを前提にする。

ArchであればAURにパッケージがあるため、

```
paru -Sy howdy-git
```

などとしてインストールできる

# 2. howdyの設定

まずは目的のカメラを探そう。例えば`mpv`がインストールされていれば

```
mpv /dev/video0
```

などとしてカメラ映像を見ることができる。`video0`の数字部分を変えながらどれが正解か試して探す。

目的のカメラのパスが分かったら

```
sudo howdy config
```

で設定ファイルを開き(nanoがインストールされている必要がある)、

```
device_path =
```

の行に先程の`/dev/video0`などを書き足す。

次に、

```
sudo howdy add
```

を実行し、顔を登録する。登録し終わったら

```
sudo howdy test
```

で、きちんと顔が認識されていることを確認する。

# 3. PAMの設定

ここまででHowdy自体の設定は終わったが、次にどこでHowdyを使うか決めるため、PAMの設定をいじる。まず、

```
cd /etc/pam.d
ls
```

を実行してみると、様々なファイルが見えるはず。例えば`sudo`というファイルがあるはずで、これは`sudo`を使う際にどのような認証方法を使うかの設定を記述している。

## sudo

ではまずsudoの挙動を設定するために好きなエディタで`sudo`ファイルを開いてみよう

```
sudo vim sudo
```

すると、

```
#%PAM-1.0
auth		include		system-auth
account		include		system-auth
session		include		system-auth
```

このようなファイルとなっているはずだ。この`#%PAM`の行の後に

```
auth		sufficient	/lib/security/pam_howdy.so
```

を追加して保存する。なお、日本語版Arch
Wikiでは若干違う記述になっているが、それは古いものなので注意。

これで`sudo`を実行すると、顔認証によって認証がされるはず。

## GUI特権ダイアログ

次に、ファイラーなどで特権操作を行う場合などに表示されるGUIのダイアログで顔認証を使えるようにする。自分はKDEでしか確認していないが恐らく他のDEでも動くはず。このためにはpolkitの設定を変更する。

ただ、自分の場合はpolkitのPAM設定ファイルが無かったが、このissue

https://github.com/boltgolt/howdy/issues/623

を見ると、`/usr/lib/pam.d/polkit-1`をコピーしてくればいいようだ。

```
sudo cp /usr/lib/pam.d/polkit-1 .
```

この`polkit-1`ファイルを編集し、先と同じようにHowdyの設定を追加する。

これで、GUIでの特権認証時に顔認証できるようになる。

## KDE(ロック解除)

次に、KDEのロック解除を設定する。これはKDEから明示的にロックした場合に用いられるものであり、SDDMなどのディスプレイマネージャによって行われる初回ロック解除時とは違うものであることに注意。
これも先程と同様に`pam.d`フォルダに`kde`というファイルがあるはずなのでそれを同じく編集するだけ。

## SDDM(非推奨)

KDEのデフォルトディスプレイマネージャであるSDDMは起動直後やスリープ解除後のログインなどを司り、これについても先程と同様に`sddm`というファイルを編集することで顔認証による解除ができるようになる…

のだが、これはおすすめしない。というのも、SDDMを顔認証で解除するとKWalletのロックが解除されず、パスワードを求められるからである。KWalletとは資格情報を安全に保管しておくためのシステムで、git-credential-managerなどで内部的に使われている。

KWalletのパスワードはユーザーパスワードと基本的に同じため、SDDMで直接パスワードが入力された場合自動でKWalletのロックを解除できる。しかし、Howdyではパスワードを入力しないためそうはいかない。これを実現するためにはHowdyにパスワードを保管しておく必要があり、セキュリティ上よろしくないため実装されていない。詳しくは↓

https://github.com/boltgolt/howdy/issues/56

今回はKDE(KWallet)の話だが、Gnome Keyringなどでも同じ問題が起きると考えられる。



> この記事は [https://note.nazo6.dev/blog/linux-howdy-tutorial](https://note.nazo6.dev/blog/linux-howdy-tutorial) とのクロスポストです。