# README

## コンテナ生成と起動

```bash
docker build -t my-open-id-provider . -f Dockerfile
docker container run --name my-open-id-provider -it --add-host=host.docker.internal:host-gateway -p 33000:3000 -v $PWD:/webapp my-open-id-provider
```

## DB初期化

※ 事前にDBコンテナが作成されていること

e.g.
```bash
docker container run --name dev-mysql -itd --add-host=host.docker.internal:host-gateway -e MYSQL_ROOT_PASSWORD='password' -p 33306:3306 mysql:8.0.23
```

```bash
docker container exec my-open-id-provider bin/rake db:create db:migrate
```

