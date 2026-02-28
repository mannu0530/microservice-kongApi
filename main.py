"""
Main FastAPI application for the user microservice.

Provides REST API endpoints for user authentication and management.
"""
from datetime import datetime
from typing import Optional

# FastAPI and related imports
from fastapi import FastAPI, Depends, HTTPException, status, Header
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

# SQLAlchemy session
from sqlalchemy.orm import Session

# Import database functions
from database import (
    get_db,
    init_database,
    get_user_by_username,
    create_user,
    get_all_users
)

# Import authentication functions
from auth import (
    hash_password,
    verify_password,
    create_jwt_token,
    verify_jwt_token,
    get_token_from_header
)

# Import configuration
from config import config


# ============================================================================
# Pydantic Models (Request/Response Schemas)
# ============================================================================

class LoginRequest(BaseModel):
    """Request model for login endpoint."""
    username: str = Field(..., min_length=1, max_length=50, description="Username")
    password: str = Field(..., min_length=1, description="Password")


class LoginResponse(BaseModel):
    """Response model for successful login."""
    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Token expiration in minutes")


class TokenVerifyResponse(BaseModel):
    """Response model for token verification."""
    valid: bool = Field(..., description="Whether token is valid")
    username: Optional[str] = Field(None, description="Username from token")
    user_id: Optional[str] = Field(None, description="User ID from token")
    expires_at: Optional[str] = Field(None, description="Token expiration time")


class UserResponse(BaseModel):
    """Response model for user data."""
    id: int
    username: str
    email: Optional[str]
    is_active: bool
    created_at: Optional[str]
    
    class Config:
        from_attributes = True


class UsersListResponse(BaseModel):
    """Response model for users list."""
    users: list[UserResponse]
    total: int


class HealthResponse(BaseModel):
    """Response model for health check."""
    status: str
    timestamp: str
    database: str


class ErrorResponse(BaseModel):
    """Response model for errors."""
    detail: str


# ============================================================================
# FastAPI Application Setup
# ============================================================================

# Create FastAPI application
app = FastAPI(
    title="User Microservice",
    description="A minimal FastAPI-based user microservice with JWT authentication",
    version="1.0.0",
    docs_url="/docs",  # Swagger UI
    redoc_url="/redoc"  # ReDoc documentation
)


# ============================================================================
# Application Lifecycle Events
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """
    Initialize application on startup.
    
    - Initialize database and create tables
    - Print configuration info
    """
    print("=" * 60)
    print("Starting User Microservice")
    print("=" * 60)
    
    # Initialize database (create tables if they don't exist)
    init_database()
    
    # Create a default admin user if no users exist
    # This is useful for initial testing
    from database import SessionLocal, User
    db = SessionLocal()
    try:
        # Check if any users exist
        existing_users = db.query(User).all()
        
        if not existing_users or len(existing_users) == 0:
            # Create default admin user
            admin_password = hash_password("admin123")
            admin_user = create_user(db, "admin", admin_password, "admin@example.com")
            print(f"[STARTUP] Created default admin user: {admin_user.username}")
    except Exception as e:
        print(f"[STARTUP] Could not create default user: {str(e)}")
    finally:
        db.close()
    
    print(f"[CONFIG] JWT Secret: {config.JWT_SECRET[:10]}...")
    print(f"[CONFIG] JWT Expiration: {config.JWT_EXPIRATION_MINUTES} minutes")
    print(f"[CONFIG] Database: {config.DATABASE_URL}")
    print("=" * 60)


# ============================================================================
# API Endpoints
# ============================================================================

@app.get("/", tags=["Root"])
async def root():
    """
    Root endpoint - basic welcome message.
    
    Returns:
        Welcome message
    """
    return {
        "message": "Welcome to User Microservice",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get(
    "/health",
    response_model=HealthResponse,
    tags=["Health"],
    summary="Health check endpoint",
    description="Public endpoint that returns service health status"
)
async def health_check():
    """
    Health check endpoint.
    
    Returns the current health status of the service.
    No authentication required.
    
    Returns:
        HealthResponse: Service status information
    """
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        database="connected"
    )


@app.post(
    "/login",
    response_model=LoginResponse,
    tags=["Authentication"],
    summary="User login",
    description="Authenticate user and return JWT token",
    responses={
        200: {"model": LoginResponse, "description": "Login successful"},
        401: {"model": ErrorResponse, "description": "Invalid credentials"},
        404: {"model": ErrorResponse, "description": "User not found"}
    }
)
async def login(
    request: LoginRequest,
    db: Session = Depends(get_db)
):
    """
    Login endpoint.
    
    Accepts username and password, validates credentials,
    and returns a JWT token if successful.
    
    Args:
        request: LoginRequest with username and password
        db: Database session (injected by FastAPI)
        
    Returns:
        LoginResponse with JWT token
        
    Raises:
        HTTPException: 401 if credentials are invalid
    """
    print(f"[LOGIN] Attempting login for user: {request.username}")
    
    # Look up user by username
    user = get_user_by_username(db, request.username)
    
    # If user doesn't exist, return 404
    if not user:
        print(f"[LOGIN] User not found: {request.username}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check if user account is active
    if not user.is_active:
        print(f"[LOGIN] User account is inactive: {request.username}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account is inactive"
        )
    
    # Verify password against stored hash
    if not verify_password(request.password, user.hashed_password):
        print(f"[LOGIN] Invalid password for user: {request.username}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    # Generate JWT token
    token = create_jwt_token(user.username, user.id)
    
    print(f"[LOGIN] Login successful for user: {user.username}")
    
    return LoginResponse(
        access_token=token,
        token_type="bearer",
        expires_in=config.JWT_EXPIRATION_MINUTES
    )


@app.get(
    "/verify",
    response_model=TokenVerifyResponse,
    tags=["Authentication"],
    summary="Verify JWT token",
    description="Validate JWT token and return status",
    responses={
        200: {"model": TokenVerifyResponse, "description": "Token valid"},
        401: {"model": ErrorResponse, "description": "Token invalid or expired"}
    }
)
async def verify_token(
    authorization: Optional[str] = Header(None, description="Authorization header with Bearer token")
):
    """
    Verify JWT token endpoint.
    
    Validates the JWT token provided in the Authorization header
    and returns the token status.
    
    Args:
        authorization: Authorization header with Bearer token
        
    Returns:
        TokenVerifyResponse with token status
        
    Raises:
        HTTPException: 401 if token is missing or invalid
    """
    # Extract token from header
    token = get_token_from_header(authorization)
    
    # If no token provided
    if not token:
        print("[VERIFY] No token provided")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No token provided",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    # Verify the token
    payload = verify_jwt_token(token)
    
    # If token is invalid
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    # Return token information
    return TokenVerifyResponse(
        valid=True,
        username=payload.get("username"),
        user_id=payload.get("sub"),
        expires_at=datetime.fromtimestamp(payload.get("exp", 0)).isoformat()
    )


@app.get(
    "/users",
    response_model=UsersListResponse,
    tags=["Users"],
    summary="Get all users",
    description="Retrieve list of all active users",
    responses={
        200: {"model": UsersListResponse, "description": "Users retrieved"},
        401: {"model": ErrorResponse, "description": "Authentication required"}
    }
)
async def get_users(
    authorization: Optional[str] = Header(None, description="Authorization header with Bearer token"),
    db: Session = Depends(get_db)
):
    """
    Get all users endpoint.
    
    Protected endpoint that requires a valid JWT token.
    Returns a list of all active users.
    
    Args:
        authorization: Authorization header with Bearer token
        db: Database session (injected by FastAPI)
        
    Returns:
        UsersListResponse with list of users
        
    Raises:
        HTTPException: 401 if token is missing or invalid
    """
    # Extract and verify token
    token = get_token_from_header(authorization)
    
    if not token:
        print("[USERS] No token provided")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    # Verify the token
    payload = verify_jwt_token(token)
    
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    # Get all users from database
    users = get_all_users(db)
    
    print(f"[USERS] Retrieved {len(users)} users")
    
    # Convert to response model
    user_responses = [
        UserResponse(
            id=user.id,
            username=user.username,
            email=user.email,
            is_active=user.is_active,
            created_at=user.created_at
        )
        for user in users
    ]
    
    return UsersListResponse(
        users=user_responses,
        total=len(user_responses)
    )


# ============================================================================
# Exception Handlers
# ============================================================================

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """
    Custom exception handler for HTTP exceptions.
    
    Returns JSON error response.
    """
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """
    Custom exception handler for general exceptions.
    
    Returns JSON error response with 500 status.
    """
    print(f"[ERROR] Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"}
    )


# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    
    # Run the application
    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG
    )
