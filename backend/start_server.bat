@echo off
echo ================================
echo  ShopCompare API Server
echo ================================
cd /d "%~dp0"
echo.
echo 正在启动服务 (端口 8000)...
echo.
echo 模拟器访问: http://localhost:8000
echo 真机访问: http://你的局域网IP:8000
echo API文档: http://localhost:8000/docs
echo 状态检查: http://localhost:8000/api/v1/crawler/status
echo.
echo 后台爬虫会在启动后3秒自动运行
echo ================================
echo.
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
pause
