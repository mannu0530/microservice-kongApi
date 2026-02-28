# =============================================================================
# Lightweight Production Dockerfile for User Microservice
# =============================================================================
# Optimized for minimal image size (~150MB vs ~1GB)
# =============================================================================

# Use slim Python base image
FROM python:3.11-slim-bookworm

# Set environment variables for minimal image
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_PREFER_BINARY=1

# Create non-root user for security
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/bash --create-home appuser

# Set working directory
WORKDIR /app

# Install dependencies in a single layer (system-wide, not user)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    rm -rf /var/lib/cache/* /var/lib/apt/lists/*

# Copy application code
COPY --chown=appuser:appgroup . .

# Create data directory and set ownership
RUN mkdir -p /app/data && chown -R appuser:appgroup /app/data

# Switch to non-root user
USER appuser

# Add pip installed binaries to PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Expose the application port
EXPOSE 8000

# Run the application using python -m uvicorn
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
