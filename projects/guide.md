# Golang マイクロサービス環境構築ガイド

このガイドでは、Golangを使用したマイクロサービスアーキテクチャの環境構築について説明します。Next.jsの知識をベースに、段階的に環境を構築していきます。

## 目次

1. [前提条件](#前提条件)
2. [開発環境のセットアップ](#開発環境のセットアップ)
3. [Goの基本環境構築](#goの基本環境構築)
4. [Dockerの設定](#dockerの設定)
5. [開発環境の選択](#開発環境の選択)
   - [Docker Compose環境（推奨）](#docker-compose環境推奨)
   - [ローカルKubernetes環境](#ローカルkubernetes環境)
6. [データベース環境](#データベース環境)
7. [マイクロサービスの構築](#マイクロサービスの構築)
8. [CI/CD環境の構築](#cicd環境の構築)
9. [モニタリングの設定](#モニタリングの設定)
10. [本番環境への移行](#本番環境への移行)

## 前提条件

このガイドを進めるにあたり、以下のツールの基本的な知識があると役立ちます：

- コマンドラインの基本操作
- Gitの基本的な使い方
- Next.jsなどのWebフレームワークの基本知識

## 開発環境のセットアップ

### 必要なツールのインストール

```bash
# macOSの場合（Homebrew使用）
# Homebrewのインストール（未インストールの場合）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 必要なツールのインストール
brew install go docker docker-compose
```

### VSCodeの設定（推奨エディタ）

1. VSCodeをインストール: https://code.visualstudio.com/
2. 以下の拡張機能をインストール:
   - Go (by Go Team at Google)
   - Docker
   - Remote - Containers

## Goの基本環境構築

### Goのインストールと設定

```bash
# Goのバージョン確認
go version

# GOPATHの設定（~/.zshrcまたは~/.bashrcに追加）
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# 設定の反映
source ~/.zshrc  # または source ~/.bashrc
```

### プロジェクト構造の作成

```bash
# プロジェクトディレクトリの作成
mkdir -p golang-microservices
cd golang-microservices

# Go Modulesの初期化
go mod init github.com/yourusername/golang-microservices

# 基本ディレクトリ構造の作成
mkdir -p services/auth-service
mkdir -p services/user-service
mkdir -p services/payment-service
mkdir -p pkg/database
mkdir -p pkg/logging
mkdir -p pkg/messaging
mkdir -p api/proto
mkdir -p api/openapi
```

## Dockerの設定

### Dockerのインストールと設定

Docker Desktopをインストールするか、Docker Engineをセットアップします。

```bash
# Docker Desktopのインストール（macOS/Windows）
# https://www.docker.com/products/docker-desktop からダウンロード

# インストール確認
docker --version
docker-compose --version
```

### マイクロサービス用Dockerfileの作成

各サービスディレクトリに`Dockerfile`を作成します。例として認証サービス用のDockerfileを示します：

```dockerfile
# services/auth-service/Dockerfile
FROM golang:1.22 as builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o service .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/service .
CMD ["./service"]
```

## 開発環境の選択

マイクロサービス開発には複数の環境オプションがありますが、チーム開発の観点から最も共有しやすい環境を選択することが重要です。

### Docker Compose環境（推奨）

Docker Composeを使用すると、チーム全体で一貫した開発環境を簡単に共有できます。これは特に初期開発段階で推奨されるアプローチです。

#### docker-compose.ymlの作成

プロジェクトのルートディレクトリに以下の内容の`docker-compose.yml`ファイルを作成します：

```yaml
version: '3.8'

services:
  auth-service:
    build:
      context: ./services/auth-service
    ports:
      - "8081:8080"
    environment:
      - DB_HOST=postgres
      - DB_USER=user
      - DB_PASSWORD=password
      - DB_NAME=microservices
      - REDIS_HOST=redis
      - REDIS_PASSWORD=password
    depends_on:
      - postgres
      - redis

  user-service:
    build:
      context: ./services/user-service
    ports:
      - "8082:8080"
    environment:
      - DB_HOST=postgres
      - DB_USER=user
      - DB_PASSWORD=password
      - DB_NAME=microservices
      - REDIS_HOST=redis
      - REDIS_PASSWORD=password
    depends_on:
      - postgres
      - redis

  payment-service:
    build:
      context: ./services/payment-service
    ports:
      - "8083:8080"
    environment:
      - DB_HOST=postgres
      - DB_USER=user
      - DB_PASSWORD=password
      - DB_NAME=microservices
      - REDIS_HOST=redis
      - REDIS_PASSWORD=password
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_USER: user
      POSTGRES_DB: microservices
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"
    command: redis-server --requirepass password

  # 開発用のKafkaとZookeeper
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1

volumes:
  postgres-data:
```

#### 環境の起動と停止

```bash
# 全サービスを起動
docker-compose up -d

# 特定のサービスだけを起動
docker-compose up -d auth-service postgres redis

# ログの確認
docker-compose logs -f

# 環境の停止
docker-compose down

# 環境の停止（ボリュームも削除）
docker-compose down -v
```

#### 開発ワークフロー

1. コードを変更する
2. `docker-compose build auth-service`でサービスを再ビルド
3. `docker-compose up -d auth-service`で更新されたサービスを起動
4. 必要に応じて`docker-compose restart auth-service`でサービスを再起動

#### 利点

- チーム全員が同じ環境設定を使用できる
- `.env`ファイルを使って環境変数を管理できる
- 新しいメンバーが参加しても、`docker-compose up`だけで環境構築が完了
- Kubernetes環境よりもリソース消費が少ない
- 設定が単一ファイルにまとまっているため管理が容易

### ローカルKubernetes環境

より本番環境に近い環境が必要な場合や、Kubernetesの機能を活用したい場合は、ローカルKubernetes環境を使用できます。ただし、チーム全体での共有や初期セットアップが複雑になる点に注意が必要です。

#### Minikubeのセットアップ

```bash
# Minikubeのインストール
brew install minikube kubectl helm

# Minikubeの起動
minikube start --cpus=4 --memory=8g

# ステータス確認
minikube status
kubectl get nodes
```

#### Helmのセットアップ

```bash
# Helmのインストール確認
helm version

# Helmリポジトリの追加
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

#### 開発効率化ツールのインストール

```bash
# Skaffoldのインストール
brew install skaffold

# K9sのインストール（Kubernetes UIツール）
brew install derailed/k9s/k9s
```

#### Kubernetesマニフェストの管理

Kubernetes環境を使用する場合は、マニフェストファイルをバージョン管理し、チーム全体で共有することが重要です。以下のような構造を推奨します：

```
k8s/
  base/
    auth-service/
      deployment.yaml
      service.yaml
    user-service/
      deployment.yaml
      service.yaml
  overlays/
    dev/
      kustomization.yaml
    prod/
      kustomization.yaml
```

Kustomizeを使用して環境ごとの違いを管理することで、一貫性を保ちながら柔軟な設定が可能になります。

## データベース環境

### PostgreSQLのセットアップ

Docker Compose環境では、`docker-compose.yml`ファイルに既にPostgreSQLの設定が含まれています。

Kubernetes環境を使用する場合：

```bash
# Kubernetesにデプロイ
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgres bitnami/postgresql --set postgresqlPassword=password
```

### Redisのセットアップ

Docker Compose環境では、`docker-compose.yml`ファイルに既にRedisの設定が含まれています。

Kubernetes環境を使用する場合：

```bash
# Kubernetesにデプロイ
helm install redis bitnami/redis --set auth.password=password
```

## マイクロサービスの構築

### 基本的なGoマイクロサービスの作成

認証サービスの例：

```go
// services/auth-service/main.go
package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
		})
	})
	
	r.POST("/auth/login", func(c *gin.Context) {
		// 認証ロジック
		c.JSON(http.StatusOK, gin.H{
			"token": "sample-token",
		})
	})
	
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
```

必要な依存関係のインストール：

```bash
go get -u github.com/gin-gonic/gin
go get -u gorm.io/gorm
go get -u gorm.io/driver/postgres
```

### Kubernetesマニフェストの作成

```bash
# services/auth-service/k8s/deployment.yaml
mkdir -p services/auth-service/k8s
cat > services/auth-service/k8s/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
      - name: auth-service
        image: auth-service:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: "0.5"
            memory: "512Mi"
          requests:
            cpu: "0.1"
            memory: "128Mi"
EOF

# services/auth-service/k8s/service.yaml
cat > services/auth-service/k8s/service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: auth-service
spec:
  selector:
    app: auth-service
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
```

## CI/CD環境の構築

### GitHub Actionsの設定

```bash
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << EOF
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.22'
        
    - name: Build and Test
      run: |
        go mod download
        go test ./...
        go build ./...
        
    - name: Build Docker images
      run: |
        docker build -t auth-service:latest ./services/auth-service
        docker build -t user-service:latest ./services/user-service
EOF
```

## モニタリングの設定

### Prometheusとgrafanaのインストール

```bash
# Prometheusのインストール
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

## 本番環境への移行

本番環境への移行準備として、以下の点を考慮してください：

1. **環境変数の管理**：
   - 開発環境と本番環境で異なる設定を環境変数で管理
   - Kubernetes Secretsを使用して機密情報を管理

2. **スケーリング戦略**：
   - Horizontal Pod Autoscaler (HPA) の設定
   - リソース制限の適切な設定

3. **バックアップと復旧**：
   - データベースの定期的なバックアップ
   - 障害復旧計画の策定

4. **セキュリティ対策**：
   - ネットワークポリシーの設定
   - RBAC（ロールベースアクセス制御）の設定
   - イメージスキャンの実施

## まとめ

このガイドでは、Golangを使用したマイクロサービスアーキテクチャの環境構築について説明しました。段階的に環境を構築することで、複雑なシステムも理解しやすくなります。

実際の開発では、ビジネス要件に合わせて適宜調整してください。また、チームの経験レベルに応じて、より複雑な機能（サービスメッシュ、高度なモニタリングなど）を段階的に導入することをお勧めします。

## 参考リソース

- [Go公式ドキュメント](https://golang.org/doc/)
- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/home/)
- [Docker公式ドキュメント](https://docs.docker.com/)
- [Gin Webフレームワーク](https://github.com/gin-gonic/gin)
- [GORM](https://gorm.io/)
