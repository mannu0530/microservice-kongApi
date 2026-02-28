"""
Authentication module for the user microservice.

Handles JWT token generation/verification and password hashing using bcrypt.
"""
from datetime import datetime, timedelta
from typing import Optional

# JWT for token handling
import jwt
from jwt.exceptions import InvalidTokenError, ExpiredSignatureError

# bcrypt for password hashing
import bcrypt

# Import configuration
from config import config


def hash_password(password: str) -> str:
    """
    Hash a password using bcrypt.
    
    Args:
        password: Plain text password to hash
        
    Returns:
        Hashed password as string
    """
    # Convert password to bytes (bcrypt requires bytes)
    password_bytes = password.encode('utf-8')
    
    # Generate salt and hash the password
    # rounds=12 is a good balance between security and performance
    salt = bcrypt.gensalt(rounds=12)
    hashed = bcrypt.hashpw(password_bytes, salt)
    
    # Return as string
    return hashed.decode('utf-8')


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a password against a bcrypt hash.
    
    Args:
        plain_password: Plain text password to verify
        hashed_password: Stored bcrypt hash to compare against
        
    Returns:
        True if password matches, False otherwise
    """
    try:
        # Convert both to bytes
        password_bytes = plain_password.encode('utf-8')
        hashed_bytes = hashed_password.encode('utf-8')
        
        # Use bcrypt's checkpw function
        return bcrypt.checkpw(password_bytes, hashed_bytes)
    except Exception as e:
        print(f"[AUTH ERROR] Password verification failed: {str(e)}")
        return False


def create_jwt_token(username: str, user_id: int) -> str:
    """
    Create a JWT token for a user.
    
    Args:
        username: Username to include in the token payload
        user_id: User's ID to include in the token payload
        
    Returns:
        JWT token as string
    """
    # Calculate expiration time
    expiration = datetime.utcnow() + timedelta(minutes=config.JWT_EXPIRATION_MINUTES)
    
    # Create payload with standard claims
    # Include 'iss' (issuer) for Kong JWT plugin compatibility
    payload = {
        "sub": str(user_id),  # subject - typically user ID
        "username": username,
        "iss": "user-microservice",  # issuer - required for Kong JWT plugin
        "exp": expiration,  # expiration time
        "iat": datetime.utcnow()  # issued at time
    }
    
    # Create JWT token using HS256 algorithm
    token = jwt.encode(
        payload,
        config.JWT_SECRET,
        algorithm=config.JWT_ALGORITHM
    )
    
    print(f"[AUTH] Created JWT token for user: {username}, expires at: {expiration}")
    
    return token


def verify_jwt_token(token: str) -> Optional[dict]:
    """
    Verify and decode a JWT token.
    
    Args:
        token: JWT token string to verify
        
    Returns:
        Decoded payload if valid, None if invalid
    """
    try:
        # Decode and verify the token
        payload = jwt.decode(
            token,
            config.JWT_SECRET,
            algorithms=[config.JWT_ALGORITHM]
        )
        
        print(f"[AUTH] Token verified successfully for user: {payload.get('username')}")
        return payload
        
    except ExpiredSignatureError:
        print("[AUTH] Token has expired")
        return None
        
    except InvalidTokenError as e:
        print(f"[AUTH] Invalid token: {str(e)}")
        return None
        
    except Exception as e:
        print(f"[AUTH ERROR] Token verification failed: {str(e)}")
        return None


def get_token_from_header(authorization: str) -> Optional[str]:
    """
    Extract JWT token from Authorization header.
    
    Expected format: "Bearer <token>"
    
    Args:
        authorization: Authorization header value
        
    Returns:
        Token string if present, None otherwise
    """
    if not authorization:
        return None
    
    # Check for Bearer scheme
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        return None
    
    return parts[1]
