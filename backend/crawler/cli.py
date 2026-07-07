import sys
import os

backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, backend_dir)

from app.database import SessionLocal
from crawler.scheduler import run_sync


def main():
    print('ShopCompare Crawler v0.3')
    print('=' * 40)

    db = SessionLocal()
    try:
        count = run_sync(db)
        if count < 10:
            print(f'[WARN] 数据量不足 ({count}条), 建议检查网络或数据源配置')
        else:
            print(f'[OK] 爬取完成, 共 {count} 条商品')
    except Exception as e:
        print(f'[ERROR] 爬取失败: {e}')
    finally:
        db.close()


if __name__ == '__main__':
    main()
