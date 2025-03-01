# Golang マイクロサービス環境構築ガイド

このガイドでは、Golangを使用したマイクロサービスアーキテクチャの環境構築について説明します。Next.jsの知識をベースに、段階的に環境を構築していきます。

## 目次

1. [前提条件](#前提条件)
2. [開発環境のセットアップ](#開発環境のセットアップ)
3. [Goの基本環境構築](#goの基本環境構築)
4. [Dockerの設定](#dockerの設定)
5. [ローカルKubernetes環境](#ローカルkubernetes環境)
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
brew install go docker kubectl helm minikube
```

### VSCodeの設定（推奨エディタ）

1. VSCodeをインストール: https://code.visualstudio.com/
2. 以下の拡張機能をインストール:
   - Go (by Go Team at Google)
   - Docker
   - Kubernetes
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

## ローカルKubernetes環境

### Minikubeのセットアップ

```bash
# Minikubeのインストール確認
minikube version

# Minikubeの起動
minikube start --cpus=4 --memory=8g

# ステータス確認
minikube status
kubectl get nodes
```

### Helmのセットアップ

```bash
# Helmのインストール確認
helm version

# Helmリポジトリの追加
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

### 開発効率化ツールのインストール

```bash
# Skaffoldのインストール
brew install skaffold

# K9sのインストール（Kubernetes UIツール）
brew install derailed/k9s/k9s
```

## データベース環境

### PostgreSQLのセットアップ

```bash
# Kubernetesにデプロイ
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgres bitnami/postgresql --set postgresqlPassword=password

# または、Docker Composeで実行
cat > docker-compose.yml << EOF
version: '3'
services:
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
volumes:
  postgres-data:
EOF

docker-compose up -d
```

### Redisのセットアップ

```bash
# Kubernetesにデプロイ
helm install redis bitnami/redis --set auth.password=password

# または、Docker Composeで実行（既存のdocker-compose.ymlに追加）
cat >> docker-compose.yml << EOF
  redis:
    image: redis:7
    ports:
      - "6379:6379"
    command: redis-server --requirepass password
EOF

docker-compose up -d
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
