---
published: true
type: tech
topics:
  - Rust
emoji: 📄
title: tokioで作ったサーバーをdockerで起動すると終了が遅くなるときの対処法
---

> この記事は [https://knowledge.nazo6.dev/blog/rust-server-docker-stop-slow](https://knowledge.nazo6.dev/blog/rust-server-docker-stop-slow) とのクロスポストです。


# 概要
axumなどを作ってRustでサーバーを作ると`docker compose stop`などが微妙に遅くてイライラだったのでそれを解決する方法です。

# コード
```rust
async fn main() {
	...なんかの処理
	...
	
    let mut sigterm = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()).unwrap();

    tokio::select!(
        _ = tart_server() => {},
        _ = sigterm.recv() => {}
    );
}
```

# 解説

https://docs.docker.jp/engine/reference/commandline/stop.html

ここに書かれているように、`docker stop`が実行されるとプログラムに`SIGTERM`が送信されるので`tokio::signal`を使ってそれを受け取り、`tokio::select`を使ってタスクを完了させます。