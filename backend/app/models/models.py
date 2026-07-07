from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.database import Base
import datetime


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    phone = Column(String(20), unique=True, nullable=False, index=True)
    password_hash = Column(String(128), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.now)
    updated_at = Column(DateTime, default=datetime.datetime.now, onupdate=datetime.datetime.now)

    favorites = relationship("Favorite", back_populates="user")
    alerts = relationship("Alert", back_populates="user")


class Product(Base):
    __tablename__ = "products"

    id = Column(String(20), primary_key=True)
    name = Column(String(200), nullable=False)
    model_code = Column(String(100))
    brand = Column(String(100), nullable=False)
    category = Column(String(100), nullable=False, index=True)
    image_url = Column(String(500), default="")
    description = Column(Text, default="")
    aggregate_score = Column(Float, default=0)
    aggregate_rating = Column(Float, default=0)
    total_review_count = Column(Integer, default=0)
    lowest_price = Column(Float, default=0)
    highest_price = Column(Float, default=0)
    price_spread = Column(Float, default=0)
    historical_low = Column(Float, default=0)
    publish_date = Column(String(20), default="")
    created_at = Column(DateTime, default=datetime.datetime.now)

    listings = relationship("PlatformListing", back_populates="product")
    price_history = relationship("PriceHistory", back_populates="product")


class PlatformListing(Base):
    __tablename__ = "platform_listings"

    id = Column(Integer, primary_key=True, autoincrement=True)
    product_id = Column(String(20), ForeignKey("products.id"), nullable=False)
    platform = Column(String(50), nullable=False)
    price = Column(Float, nullable=False)
    rating = Column(Float, default=0)
    review_count = Column(Integer, default=0)
    in_stock = Column(Boolean, default=True)
    url = Column(String(500), default="")

    product = relationship("Product", back_populates="listings")


class PriceHistory(Base):
    __tablename__ = "price_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    product_id = Column(String(20), ForeignKey("products.id"), nullable=False)
    date = Column(String(20), nullable=False)
    price = Column(Float, nullable=False)

    product = relationship("Product", back_populates="price_history")


class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    product_id = Column(String(20), ForeignKey("products.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.now)

    user = relationship("User", back_populates="favorites")


class Alert(Base):
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    product_id = Column(String(20), ForeignKey("products.id"), nullable=False)
    target_price = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.now)
    triggered = Column(Boolean, default=False)

    user = relationship("User", back_populates="alerts")
