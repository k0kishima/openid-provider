# README

## clone this repository

```bash
git clone git@github.com:k0kishima/openid-provider.git
```

## 鍵ペアの生成

```bash
cd openid-provider
ssh-keygen -t rsa -P "" -b 4096 -m PEM -f jwtRS256.key
```

※ 上記ファイル名を規定値としているので設定編集しなくても動作するが、ファイル名を変更する場合は `.gitignore` の編集と環境変数 `ENV['JWT_SECRET_KEY_FILE_NAME']` を設定すること

## コンテナ生成と起動

```bash
docker build -t my-open-id-provider . -f Dockerfile
docker container run --name my-open-id-provider -it --add-host=host.docker.internal:host-gateway -p 33000:3000 -v $PWD:/webapp my-open-id-provider
```

## DB初期化

事前にDBコンテナが作成されていること

以下、生成の一例

e.g.
```bash
docker container run --name dev-mysql -itd --add-host=host.docker.internal:host-gateway -e MYSQL_ROOT_PASSWORD='password' -p 33306:3306 mysql:8.0.23
```

`config/database.yml` を編集して上記に接続できる状態にした上で、migrateを実行

```bash
docker container exec my-open-id-provider bin/rake db:create db:migrate
```

## RPの登録

下記にアクセスしてRP（認証を受けるアプリケーション）を登録

http://localhost:33000/auth/openid/applications/new

未ログインだと以下にリダイレクトされるので、フッターの "Sign up" のリンクよりユーザー登録する

http://localhost:33000/users/sign_in

※ ここではローカル開発環境での利用を前提としているのでパブリックなURLから管理者登録できるものとする

ユーザー登録後、RPの登録フォームが表示されるのでRPに受け口として作ってあるコールバックURIやRPのタイプ（コンフィデンシャルクライアントかどうか）などを入力して送信する


