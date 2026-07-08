"""Database initialization — creates tables and optional test user.

Demo seed data has been archived to ../archive/seed_data.py.
The project now relies on crawler data exclusively.
"""

from app.database import Base, SessionLocal, engine
from app.models.models import User


def init() -> None:
    """Create all tables if they don't exist."""
    Base.metadata.create_all(bind=engine)
    print('Database tables initialized.')


def seed_test_user() -> None:
    """Create a test user for local development."""
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.phone == '13800000000').first()
        if user is None:
            user = User(
                phone='13800000000',
                password_hash='$2b$12$kCQ.pqPnKU8SbQE4k2.1puaN/hivMW3n5YWBB9hpmvC..H1UkQWWK'
            )
            db.add(user)
            db.commit()
            print('Test user created: 13800000000 / test123456')
        else:
            print('Test user already exists: 13800000000 / test123456')
    finally:
        db.close()


if __name__ == '__main__':
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == 'user':
        seed_test_user()
    else:
        init()
