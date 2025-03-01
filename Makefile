.PHONY: up down restart build logs ps clean help

# デフォルトのターゲット
help:
	@echo "使用可能なコマンド:"
	@echo "  make up      - すべてのサービスを起動"
	@echo "  make down    - すべてのサービスを停止"
	@echo "  make restart - すべてのサービスを再起動"
	@echo "  make build   - すべてのサービスをビルド"
	@echo "  make logs    - すべてのサービスのログを表示"
	@echo "  make ps      - 実行中のサービスを表示"
	@echo "  make clean   - コンテナ、イメージ、ボリュームを削除"

# サービスを起動
up:
	docker-compose up -d

# サービスを停止
down:
	docker-compose down

# サービスを再起動
restart:
	docker-compose restart

# サービスをビルド
build:
	docker-compose build

# ログを表示
logs:
	docker-compose logs -f

# 実行中のサービスを表示
ps:
	docker-compose ps

# クリーンアップ（コンテナ、イメージ、ボリュームを削除）
clean:
	docker-compose down -v
	docker system prune -f

# 特定のサービスを起動（例: make up-auth）
up-%:
	docker-compose up -d $*

# 特定のサービスを再起動（例: make restart-auth）
restart-%:
	docker-compose restart $*

# 特定のサービスのログを表示（例: make logs-auth）
logs-%:
	docker-compose logs -f $*

# 特定のサービスをビルド（例: make build-auth）
build-%:
	docker-compose build $* 