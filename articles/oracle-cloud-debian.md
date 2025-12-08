---
published: true
type: tech
topics:
  - OCI
  - Linux
emoji: 🌀
title: Oracle Cloud ComputingにDebian(などのディストリビューション)をインストールする方法
---

最近Oracle CloudのarmのFree Tierを使えるようになったので使おうとしたのですが、作成時に選べるイメージに使い慣れたDebianがありません。
オブジェクトストレージにイメージをアップロードすればカスタムイメージを使えるようですが、容量をなるべく使いたくなかったのとインストール時のオプションを変更したいと思い探したところ[netboot.xyz](https://netboot.xyz/)というものが使えることがわかったので紹介します。

ちなみにDebian以外の様々なLinuxを入れることができます。

参考:

@[card](https://netboot.xyz/docs/kb/providers/oci)

# 1. インスタンスを作成

Ubuntuのminimalではないイメージを使って作ってください。ARMでもx64でもどちらでもいけるみたいです。また、作成時にはSSHキーを登録するようにしてください。

# 2. netboot.xyzの準備

netboot.xyzのブートファイルをダウンロードするためにSSHでログインして以下のコマンドを実行します。
※この手順はarm用のものです。x64の場合は上のリンクを参考にして別のコマンドを実行してください。

```shell
# netbootをダウンロード
sudo wget -O /boot/efi/netboot.xyz-arm64.efi https://boot.netboot.xyz/ipxe/netboot.xyz-arm64.efi
# UEFIにreboot
sudo systemctl reboot --firmware-setup
```

# 2. VNCで接続

UEFIブートメニューを使うためにVNC接続をする必要があります。インスタンス詳細画面のコンソール接続より、「ローカル接続の作成」を押し、秘密鍵をダウンロードしてから接続を作成してください。

できたら作成した接続のメニューより「WindowsのVNC接続のコピー」を押します。LinuxではLinuxの方を選択しますが今回はWindowsでの接続について書きます。
![](/images/50588ac6618a.png)

接続するためにPuTTYをインストールします。例えばscoopでは

```
scoop install putty
```

となります。

次に秘密鍵をPuTTYの形式に変換します。PuTTYと同時にインストールされるPuTTYGenを開き、先程ダウンロードした秘密鍵を「File -> Load Private Key」より開きます。開けたら画面中央部の「Save private key」より`.ppk`ファイルを保存します。

今度はWindowsのコンソールでPowershellを開き、先程コピーしたコマンドを貼り付けます。コマンド中に

```
-i $env:homedrive$env:homepath\oci\console.ppk
```

という箇所が2箇所あるはずです。この`-i`の後のパスを先程生成した`.ppk`ファイルのパスに置き換えて実行します。接続できれば

```
Access granted. Press Return to begin session.
```

というメッセージが出るはずです。これで接続準備は完了です。

> 追記
> Linuxだとsshのオプションに`-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedAlgorithms=ssh-rsa`が必要？

# 3. OSのインストール

お好きなVNCビューアを使って`localhost:5900`に接続します。するとこのようにブートメニューが出るはずです。
![](/images/f4b30c25f443.png)
この画面で「Boot Maintenance Manager -> Boot From File -> 一つだけ見えてるやつを選択 -> netboot.xyz-なんとか.efi」を選択します。

しばらく待っているとnetboot.xyzが起動します。
ここで「Linux Network Installs」を選択することで様々なディストリビューションをインストールすることができます。あとはインストールを指示に従い進めるだけです。

ちなみにこの状態で放置しているとVNCが切断されてしまい、コンソールから再起動することができなくなってしまいました…。たまに何か操作してあげたほうかいいかもしれません。


> この記事は[個人ブログ](https://nazo6.dev/blog/article/oracle-cloud-debian)とクロスポストしています。