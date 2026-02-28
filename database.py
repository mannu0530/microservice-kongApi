"""
Database module for the user microservice.

Handles SQLite database connection and user model using SQLAlchemy ORM.
Auto-creates database and tables at startup.
"""
import os
from typing import Generator, Optional

# SQLAlchemy for ORM
from sqlalchemy import create_engine, Column, Integer, String, Boolean
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from sqlalchemy.exc import SQLAlchemyError

# Import configuration
from config import config


# Create SQLAlchemy engine
# Note: check_same_thread=False allows SQLite to be used across multiple threads
engine = create_engine(
    f"sqlite:///{config.DATABASE_URL}",
    connect_args={"check_same_thread": False},
    echo=config.DEBUG  # Log SQL queries in debug mode
)

# Create SessionLocal class for creating database sessions
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class for declarative models
Base = declarative_base()


class User(Base):
    """
    User model for storing user information.
    
    Attributes:
        id: Primary key, auto-incremented integer
        username: Unique username for the user
        hashed_password: Bcrypt-hashed password
        email: User's email address (optional)
        is_active: Whether the user account is active
        created_at: Timestamp when the user was created
    """
    __tablename__ = "users"
    
    # Primary key
    id = Column(Integer, primary_key=True, index=True)
    
    # Username - unique and indexed for fast lookups
    username = Column(String(50), unique=True, index=True, nullable=False)
    
    # Hashed password - stores bcrypt hash
    hashed_password = Column(String(255), nullable=False)
    
    # Email - optional field
    email = Column(String(100), unique=True, index=True, nullable=True)
    
    # Account status
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Creation timestamp
    created_at = Column(String(50), nullable=True)
    
    def __repr__(self):
        """String representation of the user."""
        return f"<User(id={self.id}, username='{self.username}')>"


def get_database_directory() -> str:
    """
    Get the directory path for the database file.
    
    Returns:
        str: Absolute path to the database directory
    """
    # Get the directory where the database file should be stored
    db_path = config.DATABASE_URL
    db_dir = os.path.dirname(db_path)
    
    # If no directory specified, use current directory
    if not db_dir:
        db_dir = "."
    
    return db_dir


def init_database() -> None:
    """
    Initialize the database by creating all tables.
    
    This function is called at application startup to ensure
    the database and tables exist before any operations.
    """
    # Create database directory if it doesn't exist
    db_dir = get_database_directory()
    if db_dir and db_dir != ".":
        os.makedirs(db_dir, exist_ok=True)
        print(f"[DATABASE] Created database directory: {db_dir}")
    
    # Create all tables defined in Base
    # This uses SQLAlchemy's create_all which is idempotent
    # (it won't recreate tables if they already exist)
    Base.metadata.create_all(bind=engine)
    print(f"[DATABASE] Database initialized at: {config.DATABASE_URL}")
    print(f"[DATABASE] Tables created: {list(Base.metadata.tables.keys())}")


def get_db() -> Generator[Session, None, None]:
    """
    Dependency function for getting database sessions.
    
    This function is used as a FastAPI dependency to provide
    database sessions to route handlers.
    
    Yields:
        Session: SQLAlchemy database session
    """
    db = SessionLocal()
    try:
        yield db
    except SQLAlchemyError as e:
        # Rollback on any database error
        db.rollback()
        print(f"[DATABASE ERROR] {str(e)}")
        raise
    finally:
        # Always close the session
        db.close()


def get_user_by_username(db: Session, username: str) -> Optional[User]:
    """
    Retrieve a user from the database by username.
    
    Args:
        db: Database session
        username: Username to search for
        
    Returns:
        User object if found, None otherwise
    """
    return db.query(User).filter(User.username == username).first()


def create_user(db: Session, username: str, hashed_password: str, email: str = None) -> User:
    """
    Create a new user in the database.
    
    Args:
        db: Database session
        username: Username for the new user
        hashed_password: Bcrypt-hashed password
        email: Optional email address
        
    Returns:
        Created User object
    """
    # Create new user object
    user = User(
        username=username,
        hashed_password=hashed_password,
        email=email,
        is_active=True
    )
    
    # Add to database and commit
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return user


def get_all_users(db: Session) -> list[User]:
    """
    Retrieve all active users from the database.
    
    Args:
        db: Database session
        
    Returns:
        List of User objects
    """
    return db.query(User).filter(User.is_active == True).all()
