# ここで取り組むこと

- DRYの法則に従い、terraformコードに以下のリファクタを実施する
    - tf_stateファイルをリモートバックエンド管理(s3,dynamodb)する。
    - for_eachを積極的に活用し、同様のコード記述を削減
        - 特にサブネットについては合計8つもあるので1つのコードにまとめられたのは素晴らしい
        - もちろんプライベートとパブリックとを分けて作成
    - for とifを用いてタグ名から適切なリソースを選別
        - 8つにもなるサブネットの各タグ名で判定をして、適切なルートテーブルにサブネットを関連付けできるように設定
    - module化することで、記述量削減と環境分けにも対応
        - modulesにリソースの記述はだいたいぶち込んだ
    - フォルダをリソースカテゴリに分けてモジュラー的な管理を実現
        - environment/環境(今回はstgのみ作成)/ネットワークだったりその他だったり
        - という感じでコンポーネントレベルでフォルダを分けた
        - 分けたフォルダ内では環境変数の定義とモジュール起動とアウトプットくらいしかしてない
        - terraform_remote_stateで各カテゴリ間の情報受け渡しは実施した。

- autoscaling実装
    - terraform上で起動テンプレートと
        
        Autoscalingリソースを定義した。desiredcapとかは適当に設定した。
        
- NatGWとElasticIP実装
    - NATGatewayとElasticIPを実装した
        - APIサーバーがgitからイメージ取得するのに必要
        - あとyum installとかができないのでその対処のために必要
- mysqlとAPIサーバー間のmysql通信ができることを確認する
    - mysql -h [sprint-db-instance-stg.criiqsqeswc6.ap-northeast-1.rds.amazonaws.com](http://sprint-db-instance-stg.criiqsqeswc6.ap-northeast-1.rds.amazonaws.com/) -u admin -p
- albを実装(webの前面)
    - albの作成、ターゲットグループ、albリスナー、alb用のsgを定義した
        - 簡潔に言えばあらゆる80番ポート宛の通信をフォワーディングするっていう簡素な設定となっている
    - 参考
    
    https://qiita.com/kakita-yzrh/items/27684b9c36c8be20eafd
    
- nlbを実装(apiの前面)
    - 今回web側にalbを配置するというアドリブを施したので
        - 同じリソースだとつまらないという理由でnlbで作成を試みた
    - albと概ね同様だがsgがアタッチできない(らしい)ということで、
    - api側ではIPアドレスレベルの制御のみ行う方針とした。
    - 参考
        
        https://christina04.hatenablog.com/entry/2018/02/09/095743
        
- webサーバー用起動テンプレートにてnginx.confの書き換えをするための、
    - sedコマンド部分でnlbのエンドポイントを渡すように記載を修正した 。
- dbにダミーテーブルとダミーデータを登録する

テーブル作成

```sql
CREATE TABLE Reservations (
ID INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(255) NOT NULL);
```

サンプルデータ

```sql
INSERT INTO Reservations ( name )
VALUES ('山本');
```

- 諸々確認観点をクリアした
    - 外部からの通信をalbのdns名に対して行い、webサーバーが確認できる
    - nlbのエンドポイントからapi情報が確認できる
    - webサーバーから打鍵して、アプリのテスト情報が確認できる
    - webサーバーから打鍵してdbの情報が参照できる
