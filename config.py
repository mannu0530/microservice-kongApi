"""
Configuration module for the user microservice.

Handles loading configuration from environment variables.
"""
import os
from typing import Optional

# Load environment variables from .env file if present
from dotenv import load_dotenv

# Load .env file if it exists (for local development)
load_dotenv()


class Config:
    """
    Application configuration settings.
    
    All settings are loaded from environment variables with sensible defaults.
    """
    
    # JWT Configuration
    # Secret key for signing JWT tokens - MUST be set via environment variable in production
    JWT_SECRET: str = os.getenv("JWT_SECRET", "dev-secret-key-change-in-production")
    
    # JWT token expiration time in minutes
    JWT_EXPIRATION_MINUTES: int = int(os.getenv("JWT_EXPIRATION_MINUTES", "60"))
    
    # JWT algorithm for signing tokens
    JWT_ALGORITHM: str = "HS256"
    
    # Database Configuration
    # SQLite database file path (relative to project root)
    DATABASE_URL: str = os.getenv("DATABASE_URL", "user_service/users.db")
    
    # Server Configuration
    # Host address to bind the server to
    HOST: str = os.getenv("HOST", "0.0.0.0")
    
    # Port number to bind the server to
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # Debug mode
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"


# Create a singleton instance of the config
config = Config()
