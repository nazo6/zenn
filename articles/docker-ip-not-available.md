---
published: true
type: tech
topics:
  - Docker
emoji: 🐋
title: DockerでIPアドレスが枯渇した時の対処法
---

自宅サーバーで`docker-compose up`をしたとき
```
could not find an available, non-overlapping IPv4 address pool among the defaults to assign to the network
```
というエラーが出ました。どうやらデフォルトの設定ではIPアドレスが使い果たされてしまうため30個以上のネットワークをDockerで作ることができないみたいです。
ググったところ`docker network prune`などの解決策が出てきましたが実際に30個のネットワークを使っているのでこれでは意味がありません。

根本から解決するには、1ネットワークあたりのIPアドレスを少なくするように変更する必要があります。

これはネットワークにアドレスを設定することで可能です。例えば以下の記事ではそのようにやっています。

https://zenn.dev/kobachiki/articles/dc72ce717e3c01

ですが今後のために今回はdockerの設定を変更することにしました。Dockerの`default-address-pools`という設定を変更することで`docker compose up`で作られるネットワークのデフォルト設定をすることができます。

デフォルトではdockerの`default-address-pools`は以下のようになっています(実際にこういう設定が記述されているわけではありませんが概念としてはこうなります)。
```json
  "default-address-pools" : [
    {
      "base" : "172.17.0.0/12",
      "size" : 16
    },
    {
      "base" : "192.168.0.0/16",
      "size" : 20
    }
  ]
```
これは1ネットワークあたり最大で`/16`という巨大領域を割り当てています。1コンテナに対してこれは明らかに過剰なので減らしてしまいましょう。
```json
  "default-address-pools" : [
    {
      "base" : "172.17.0.0/12",
      "size" : 20
    },
    {
      "base" : "192.168.0.0/16",
      "size" : 24
    }
  ]
```
にして1ネットワークあたりのホスト数を少なくしてやればより多くのネットワークを作れるというわけです。

以下の記事に非常に詳しく説明されていて分かりやすいです。

https://straz.to/2021-09-08-docker-address-pools/

# SynologyのContainer Managerでの設定方法
SynologyのContainer Managerを使っている人だけに関係がある話です。

通常であれば以上の設定を`/etc/docker/daemon.json`に加えればいいのですが、Synology NAS上のdockerでは
```
/var/packages/ContainerManager/etc/dockerd.json
```
に設定しなければなりません。

また、ここはContainer Managerの更新で上書きされる可能性があるため注意する必要があります。

> この記事は [https://note.nazo6.dev/blog/docker-ip-not-available](https://note.nazo6.dev/blog/docker-ip-not-available) とのクロスポストです。