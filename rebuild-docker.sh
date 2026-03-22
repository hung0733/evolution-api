#!/bin/bash

# Evolution API Docker Rebuild Script
# 用法: ./rebuild-docker.sh [options]

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 顯示幫助
show_help() {
    echo -e "${BLUE}Evolution API Docker 重建腳本${NC}"
    echo ""
    echo "用法: ./rebuild-docker.sh [選項]"
    echo ""
    echo "選項:"
    echo "  -f, --full       完全重建（刪除所有資料並重新建立）"
    echo "  -c, --clean      清理未使用的 Docker 資源"
    echo "  -l, --logs       重建後顯示日誌"
    echo "  -h, --help       顯示此幫助訊息"
    echo ""
    echo "範例:"
    echo "  ./rebuild-docker.sh              # 一般重建"
    echo "  ./rebuild-docker.sh -f           # 完全重建（刪除資料）"
    echo "  ./rebuild-docker.sh -c           # 重建並清理資源"
    echo "  ./rebuild-docker.sh -l           # 重建並顯示日誌"
    echo "  ./rebuild-docker.sh -f -c -l     # 完全重建 + 清理 + 顯示日誌"
}

# 變數
FULL_REBUILD=false
CLEAN_RESOURCES=false
SHOW_LOGS=false

# 解析參數
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--full)
            FULL_REBUILD=true
            shift
            ;;
        -c|--clean)
            CLEAN_RESOURCES=true
            shift
            ;;
        -l|--logs)
            SHOW_LOGS=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}未知選項: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Evolution API Docker 重建工具${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 檢查 docker-compose.yaml 是否存在
if [ ! -f "docker-compose.yaml" ]; then
    echo -e "${RED}錯誤: 找不到 docker-compose.yaml${NC}"
    echo "請確保在包含 docker-compose.yaml 的目錄中執行此腳本"
    exit 1
fi

# 檢查 .env 是否存在
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}警告: 找不到 .env 檔案${NC}"
    echo "建議複製 .env.example 並修改後再執行"
    read -p "是否繼續? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 完全重建模式
if [ "$FULL_REBUILD" = true ]; then
    echo -e "${YELLOW}⚠️  完全重建模式 - 將刪除所有資料！${NC}"
    echo -e "${YELLOW}   包括: 資料庫、Redis 資料、實例資料${NC}"
    echo ""
    read -p "確定要繼續嗎? (yes/no) " -r
    if [[ ! $REPLY == "yes" ]]; then
        echo -e "${YELLOW}已取消${NC}"
        exit 1
    fi
    echo ""

    echo -e "${BLUE}🛑 停止並刪除容器...${NC}"
    docker-compose down -v

    echo -e "${BLUE}🗑️  刪除資料卷...${NC}"
    # 刪除本地資料目錄（如果需要）
    read -p "是否刪除本地資料目錄 /data/evolution/? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm -rf /data/evolution/
        echo -e "${GREEN}✓ 本地資料已刪除${NC}"
    fi
else
    # 一般重建
    echo -e "${BLUE}🛑 停止容器...${NC}"
    docker-compose down
fi

echo ""
echo -e "${BLUE}🔄 拉取最新映像檔...${NC}"
docker-compose pull

echo ""
echo -e "${BLUE}🏗️  重建並啟動服務...${NC}"
docker-compose up -d --build

echo ""
echo -e "${BLUE}⏳ 等待服務啟動...${NC}"
sleep 5

# 檢查服務狀態
echo ""
echo -e "${BLUE}🔍 檢查服務狀態...${NC}"
docker-compose ps

# 檢查容器健康狀況
echo ""
echo -e "${BLUE}🏥 檢查容器健康狀況...${NC}"

# 檢查 API
if docker ps | grep -q "evolution_api"; then
    echo -e "${GREEN}✓ API 容器運作中${NC}"

    # 等待 API 啟動
    echo -e "${BLUE}⏳ 等待 API 完全啟動（約 10 秒）...${NC}"
    sleep 10

    # 測試 API 連線
    API_URL=$(grep "SERVER_URL=" .env | cut -d'=' -f2)
    if curl -s "${API_URL}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API 回應正常${NC}"
        echo -e "${GREEN}✓ 訪問: ${API_URL}${NC}"
    else
        echo -e "${YELLOW}⚠️  API 尚未完全啟動，請稍後再試${NC}"
    fi
else
    echo -e "${RED}✗ API 容器未運作${NC}"
fi

# 檢查 Redis
if docker ps | grep -q "evolution_redis"; then
    echo -e "${GREEN}✓ Redis 容器運作中${NC}"
else
    echo -e "${RED}✗ Redis 容器未運作${NC}"
fi

# 檢查 Postgres
if docker ps | grep -q "evolution_postgres"; then
    echo -e "${GREEN}✓ PostgreSQL 容器運作中${NC}"
else
    echo -e "${RED}✗ PostgreSQL 容器未運作${NC}"
fi

# 清理資源
if [ "$CLEAN_RESOURCES" = true ]; then
    echo ""
    echo -e "${BLUE}🧹 清理未使用的 Docker 資源...${NC}"
    docker system prune -f
    echo -e "${GREEN}✓ 清理完成${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}    重建完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 顯示實用指令
echo -e "${BLUE}實用指令:${NC}"
echo "  查看日誌:     docker logs -f evolution_api"
echo "  停止服務:     docker-compose down"
echo "  重新啟動:     docker-compose restart"
echo "  進入容器:     docker exec -it evolution_api sh"
echo ""

# 顯示日誌
if [ "$SHOW_LOGS" = true ]; then
    echo -e "${BLUE}📋 顯示 API 日誌（按 Ctrl+C 退出）...${NC}"
    echo ""
    docker logs -f evolution_api
fi
