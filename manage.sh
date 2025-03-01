#!/bin/bash
# manage.sh - Docker Compose環境管理スクリプト

function help() {
  echo "使用方法: ./manage.sh [コマンド] [サービス名(オプション)]"
  echo "コマンド:"
  echo "  up       - すべてのサービスを起動"
  echo "  down     - すべてのサービスを停止"
  echo "  restart  - すべてのサービスを再起動"
  echo "  logs     - すべてのサービスのログを表示"
  echo "  ps       - 実行中のサービスを表示"
  echo "  clean    - 環境をクリーンアップ"
  echo "  build    - サービスをビルド"
  echo "  help     - このヘルプを表示"
  echo ""
  echo "例:"
  echo "  ./manage.sh up              - すべてのサービスを起動"
  echo "  ./manage.sh up auth-service - 認証サービスのみを起動"
  echo "  ./manage.sh logs user-service - ユーザーサービスのログを表示"
}

# コマンドライン引数の解析
COMMAND=$1
SERVICE=$2

case "$COMMAND" in
  up)
    if [ -z "$SERVICE" ]; then
      echo "すべてのサービスを起動しています..."
      docker-compose up -d
    else
      echo "$SERVICE を起動しています..."
      docker-compose up -d $SERVICE
    fi
    ;;
  down)
    echo "サービスを停止しています..."
    docker-compose down
    ;;
  restart)
    if [ -z "$SERVICE" ]; then
      echo "すべてのサービスを再起動しています..."
      docker-compose restart
    else
      echo "$SERVICE を再起動しています..."
      docker-compose restart $SERVICE
    fi
    ;;
  logs)
    if [ -z "$SERVICE" ]; then
      echo "すべてのサービスのログを表示しています..."
      docker-compose logs -f
    else
      echo "$SERVICE のログを表示しています..."
      docker-compose logs -f $SERVICE
    fi
    ;;
  ps)
    echo "実行中のサービスを表示しています..."
    docker-compose ps
    ;;
  clean)
    echo "環境をクリーンアップしています..."
    docker-compose down -v
    docker system prune -f
    ;;
  build)
    if [ -z "$SERVICE" ]; then
      echo "すべてのサービスをビルドしています..."
      docker-compose build
    else
      echo "$SERVICE をビルドしています..."
      docker-compose build $SERVICE
    fi
    ;;
  help|*)
    help
    ;;
esac 