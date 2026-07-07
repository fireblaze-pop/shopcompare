from app.services.auth_service import hash_password, verify_password


def test_hash_and_verify_password():
    password = "test123456"
    hashed = hash_password(password)
    assert hashed != password
    assert verify_password(password, hashed) is True


def test_verify_wrong_password():
    hashed = hash_password("correct123")
    assert verify_password("wrong123", hashed) is False


def test_hash_is_deterministic_but_unique_on_each_call():
    password = "test123456"
    hash1 = hash_password(password)
    hash2 = hash_password(password)
    assert hash1 != hash2
    assert verify_password(password, hash1) is True
    assert verify_password(password, hash2) is True


def test_empty_password():
    hashed = hash_password("")
    assert verify_password("", hashed) is True


def test_long_password():
    long_password = "a" * 128
    hashed = hash_password(long_password)
    assert verify_password(long_password, hashed) is True
