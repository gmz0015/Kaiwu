.PHONY: help lint format check check-all run build

help:
	@echo "make lint       格式、目录、依赖与文档检查"
	@echo "make format     按仓库配置格式化 Swift"
	@echo "make check      静态检查、构建与离线测试"
	@echo "make check-all  macOS 完整检查，包含原生 Xcode 工程"
	@echo "make run        构建并启动 macOS 开发应用"
	@echo "make build      生成 apps/macos/dist/Kaiwu.app"

lint:
	./script/lint.sh
format:
	./script/format.sh --write
check:
	./script/check.sh
check-all:
	./script/check.sh --all
run:
	./script/build_and_run.sh
build:
	./script/build_and_run.sh --build-only
