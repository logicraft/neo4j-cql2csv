# neo4j-cql2csv

No4jからdumpした `CQL` ファイルを `CSV` ファイルに変換するスクリプトです。

## 要件

- グラフDBである [No4j](https://neo4j.com/) のバックアップ・リストアをお手伝するスクリプトです。
- dumpされた `Cypher Query Language` を No4j のインポート用CSVに変換します。
- Neo4jがインストールされていることを前提とします。

## インストール

スクリプトを任意の場所にダウンロードしてから、実行権限の付与をしてください。

設置先はpathが通っている、 `/usr/local/bin` か `$HOME/bin` が推奨です。

```bash
 $ wget https://raw.githubusercontent.com/logicraft/neo4j-cql2csv/master/neo4j-cql2csv.sh
 $ chmod +x neo4j-cql2csv.sh
```

## CQLファイルのdump

```bash
 $ neo4j-shell -c dump | sed -e "4iMATCH(n) OPTIONAL MATCH(n)-[r]-() DELETE n,r;" > /var/db/neo4j/dump.cql
```

## 使い方

*コマンド*

`neo4j-cql2csv.sh [cql|zip file]`

*オプション*

- -p　　進捗状況の表示
- -x　　デバッグモード
- -h　　簡易ヘルプの表示


## ライセンス

[MIT](https://github.com/logicraft/neo4j-cql2csv/blob/master/LICENSE)
