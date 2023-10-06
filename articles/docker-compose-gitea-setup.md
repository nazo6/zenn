---
published: true
created: 2023-07-02T14:13:21+09:00
updated: 2023-07-02T14:16:47+09:00
tags:
  - tech/git
  - tech/selfhosted
type: tech
slug: docker-compose-gitea-setup
topics:
  - Gitea
emoji: 💭
title: docker-composeでGitea + Gitea Actionsのセットアップ
---
> この記事は [https://knowledge.nazo6.dev/blog/docker-compose-gitea-setup](https://knowledge.nazo6.dev/blog/docker-compose-gitea-setup) とのクロスポストです。


# 結論から
こんな感じのdocker-compose.ymlで良い

```yaml:docker-compose.yaml
version: "3"

services:
  server:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID=1026
      - USER_GID=100
      - GITEA__database__DB_TYPE=postgres
      - GITEA__database__HOST=db:5432
      - GITEA__database__NAME={{name}}
      - GITEA__database__USER={{user}}
      - GITEA__database__PASSWD={{pass}}
    restart: always
    volumes:
      - ./gitea:/data
    ports:
      - "3300:3000"
      - "222:22"
    depends_on:
      - db
    networks:
      - default

  db:
    image: postgres:14
    restart: always
    environment:
      - POSTGRES_USER={{user}}
      - POSTGRES_PASSWORD={{pass}}
      - POSTGRES_DB={{name}}
    volumes:
      - ./postgres:/var/lib/postgresql/data
    networks:
      - default

  runner:
    image: gitea/act_runner
    restart: always
    volumes:
      - ./runner_data:/data
      - /var/run/docker.sock:/var/run/docker.sock
      - ./config.yaml:/config.yaml
    environment:
      - GITEA_INSTANCE_URL={{gitea_url}}
      - GITEA_RUNNER_REGISTRATION_TOKEN={{token}} # 下の注意点を参照
      - CONFIG_FILE=/config.yaml
      - DOCKER_HOST=unix:///var/run/docker.sock
    network_mode: host

```

これで
```
docker-compose up -d
```
すればよい。

## 注意点
- `act_runner`の`config.yaml`は[Gitea Actions(act_runner)の設定](#Gitea%20Actions(act_runner)の設定)を参照
- `{{}}`で囲まれた値は適宜変更すること。
- 特に、`GITEA_RUNNER_REGISTRATION_TOKEN`については、Giteaの管理者画面より「新しいランナーを作成」してその値を入れること。
  ![](/images/blog/2023/07-02_gitea/gitea_action.png)
- [Gitea Actionsがいつの間にか動かなくなってた](../../../memo/2023/07/Gitea%20Actionsがいつの間にか動かなくなってた.md)

# Giteaの設定
上のコンテナを作成した際にできる`./gitea/gitea/conf/app.ini`を弄る。
以下が弄るべきだと思われる値
```ini:app.ini
[server]
ROOT_URL={{giteaのurl}}

[packages]
ENABLED=true # お好みで

[actions]
ENABLED=true # Actionsに必要
```

# Gitea Actions(act_runner)の設定
ドキュメントらしいドキュメントが見つからなかったが一応[Giteaのact_runnerのリポジトリ](https://gitea.com/gitea/act_runner)にそれらしいことが書いてある。

まず、設定を生成する。act_runnerコンテナの中で
```bash
./act_runner generate-config > config.yaml
```
を実行。この`config.yaml`をdocker-composeに指定する。
この設定はそんなに弄る必要は無いが、自分は[VPNを繋いだときだけDockerの中から特定のサイトにアクセスできない！](../../../memo/2023/06/VPNを繋いだときだけDockerの中から特定のサイトにアクセスできない！.md)の影響で
```yaml:config.yaml
container:
  network: "host"
```
これだけ指定した。