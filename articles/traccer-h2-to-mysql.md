---
published: true
type: tech
topics:
  - traccar
emoji: 🔄
title: TraccarのデータをH2からMySQLに移行
---

> この記事は [https://knowledge.nazo6.dev/blog/traccer-h2-to-mysql](https://knowledge.nazo6.dev/blog/traccer-h2-to-mysql) とのクロスポストです。


# 概要
[Traccar](https://www.traccar.org/)を5.9にアプデしたら起動しなくなった。どうやら今までの内部データベース形式はサポートされなくなったみたいです。

https://github.com/traccar/traccar/issues/5164

これを機にMySQLに移行しようという記事です。

# MySQLの導入
traccarのサーバーはdocker-compose.ymlで管理しているのでそこにmysqlを追加します。データ移行のために一時的にportsを設定します。
```yaml:docker-compose.yml
  db:
    image: mysql:latest
    environment:
      MYSQL_ROOT_PASSWORD: mysql
      MYSQL_DATABASE: db
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    ports:
      - "3306:3306"
    volumes:
      - ./db/data:/var/lib/mysql
      - ./db/logs:/var/log/mysql
```
次に`traccar.xml`のデータベース設定を書き換えます。
参考:

https://www.traccar.org/mysql/

```xml:traccar.xmlの一部
    <entry key='database.driver'>com.mysql.cj.jdbc.Driver</entry>
    <entry key='database.url'>jdbc:mysql://db/db?zeroDateTimeBehavior=round&amp;serverTimezone=UTC&amp;allowPublicKeyRetrieval=true&amp;useSSL=false&amp;allowMultiQueries=true&amp;autoReconnect=true&amp;useUnicode=yes&amp;characterEncoding=UTF-8&amp;sessionVariables=sql_mode=''</entry>
    <entry key='database.user'>user</entry>
    <entry key='database.password'>password</entry>

```

ここで一度Traccarを起動し、MySQLにテーブルが作成されていることを確認するようにしてください。
確認後はデータの移行を行うため、Traccarのコンテナは停止しておきます。
# データの移行
次に実際にデータを移行します。このメモを書く際に色々試してみましたが、[DBeaver](https://dbeaver.io/)を使うと一番簡単だったのでこれを使うことにしました。他のソフトウエアでも一応できるみたいではあるようです。
参考:

https://www.traccar.org/forums/topic/suggestions-for-a-good-migration-tool-to-convert-h2-to-mysql/

## 手順
### 1. H2データベースとMySQLに接続
DBeaverを開き、データベースに接続します。H2データベースはdockerであればボリューム内のどこかに`database.mv.db`というファイルがあるはず。多分バックアップしておいたほうがいいです。接続する際のユーザーネームは今までの`traccar.xml`に書いてあるはずです。
同様に新しいMySQLデータベースにも接続します。

### 2. データのエクスポート
DBeaverでは他データベースにエクスポートするという機能があり、今回はこれを使うことで簡単にデータを移行できました。
まず、H2データベースのテーブルから`DATABASECHANGELOG`と`DATABASECHANGELOGLOCK`を除いた全てのテーブルを選択して右クリックしてデータのエクスポートを選択。

その後出てくるウィザードに従い進めます。

:::message
H2データベースが動いてたときととMySQLにテーブルを作成したtraccarのバージョンが合っていないとデータベースの移行がうまくいかないと思われます
:::
![](/images/blog/2023/09/traccar/t1.png)
Export targetでは「データベース」を選択し次へ
![](/images/blog/2023/09/traccar/t3.png)
次の画面で`Choose...`よりMySQLのデータベースを選択する。すると自動で既存のデータベースにinsertするように設定してくれます。

そのまま次へと進み、正しくマッピングされているか確認をしてから「続行」でデータベースが移行されます。

:::message
自分の場合、`tc_servers`というテーブルの移行でエラーが出ました。移行元のテーブルにも1件しか入っておらずあまり重要なデータでも無さそうだったので自分は移行しないでそのままにしておくことにしましたが人によっては手動で色々と作業をしなければいけないかもしれないです。
:::

### 3. 確認
Traccarが正常に起動し、データが失われていないことを確認したら完了。

# あとがき
一応自分はこの方法でデータを移行できましたがこれから使っていくうちに何かエラーなどが出始める可能性もあるしもっと大きいデータベースからの移行だと失敗するかもしれないです。

H2データベースは今回のように急に壊れる可能性があるのでH2データベースでtraccarを運用している人はデータが小さいうちに移行しておいたほうがいいかも。
