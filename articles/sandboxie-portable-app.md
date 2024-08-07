---
published: true
type: idea
topics:
  - Sandboxie
emoji: 📦
title: Sandboxieの基礎解説+Sandboxieでアプリをポータブル化して持ち運ぶ方法
---
# はじめに
アプリをポータブル化するやつってなんか昔流行ってたけどなんか最近聞かない気がしますね(CameyoとかPortableAppsとか)。
そんな時代ですがアプリをポータブル化して持ち運んだりしたいなーと思い調べたところSandboxieを使うのが一番まともに使えそうな感じがしたので記録しておきたいと思います。

# Sandboxieとは
[Sandboxie](https://sandboxie-plus.com/)はWindows専用ソフトウエアで、サンドボックス環境下でアプリを実行する仮想化ソフトウエアです。Sandboxieを通してアプリを実行することでレジストリやディスクへの変更などを傍受し、実環境に影響を与えないようにアプリを実行することができます。
主にウイルスの可能性があるプログラムの実行や一部ではゲームの多重起動などに使われているらしいです。ですが今回はこの性質を利用してプログラムをポータブル化してみたいと思います。
また、基本無料で使用できますが、寄付をすることで追加機能が使えるようになります。オープンソースなので自分でビルドすればクラックし放題！かと思いきやドライバ署名の都合上そういうことはできません(絶対にできないということもないみたいですが・・・)。

# インストール
[公式サイト](https://sandboxie-plus.com/downloads/)から`Sandboxie-Plus Downloads`の欄の適切なインストーラをダウンロードし、インストールします。

## Sandboxie ClassicとSandboxie Plus
Sandboxieは元々企業によって開発されていましたが、開発が終了することになりその際にオープンソース化されました。それをフォークして作られたのがSandboxie Plusです。Sandboxie PlusをインストールするとClassicとPlusの2つがインストールされます。Plusの方ではPlusにフォーク後に追加された機能が使えますが、Classicではできる日本語表示ができなくなります。今後この記事ではPlusを使います。

# 基本的な使い方
ではSandboxie-Plusを起動しましょう。すると`DefaultBox`というのが表示されていて、その右にパスが書かれているかと思います。傍受されたレジストリやディスク書き込みはこのフォルダ以下に書き込まれます。つまり、このフォルダを持ち運ぶことでアプリをポータブル化することができるというわけです。

## Sandboxの作成
DefaultBoxをそのまま使ってもいいですがここでは新しいサンドボックスを作ります。`Sandbox -> New Box`を押すと
![](/images/blog/2023/08/sandboxie/newbox.png)
こんな画面が出てくるので適宜名前を書いてあとは何も変えずにNext,Finishと押します。
すると以下のようにBoxが作成されたはずです。
![](/images/blog/2023/08/sandboxie/newbox1.png)
## ディレクトリの変更
では次にこのBoxが保存されるフォルダを変えてみましょう。上部ツールバーのメモ帳のアイコンを押して管理者権限を承認します。するとメモ帳が開くはずです。
その中から先程作成したBoxの名前のセクションを探します。下のようになっているはずです。
![](/images/blog/2023/08/sandboxie/changedir.png)
ここに
```
FileRootPath=[保存したいパス]
```
を追記して保存します。すると、Sandboxieの画面でパスが変わっています。これでデータはこのフォルダ内に保存されることになります。
このパスはGoogle Driveやネットワークドライブのパスを指定することもできるため、同期先のパソコンでも同様の設定をすることで実質ポータブル的にアプリを扱えるようになります。

# 同期のコツ
コンピュータごとに作られているファイルや一時ファイルなどは除外設定をして同期されないようにしています。Nextcloudの例は以下のようになります。他のクラウドでこういうことが出来るのかは知りません。
```.sync-exclude.lst
drive/C/WINDOWS/*
RegHive.LOG*
RegHive*.blf
user/current/AppData/Local/Microsoft/*
user/current/AppData/Local/Temp/*
```
また、Sandboxieにもユーザー設定の項目がありこれを合わせたほうがいいような気がしますが今のところ問題ないので放置してます。

また、これはNextcloudの同期エンジンのせいなのかわかりませんが`RegHive`というファイルがコンフリクトすることがあります。これはレジストリを保存しているファイルなので間違えて消さないよう慎重に扱いましょう。


> この記事は [https://note.nazo6.dev/blog/sandboxie-portable-app](https://note.nazo6.dev/blog/sandboxie-portable-app) とのクロスポストです。