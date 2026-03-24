# Production Dockerfile for WorkbenchIQ FastAPI Backend
# Python 3.10-slim base image (matches minimum requirement from pyproject.toml)

FROM python:3.10-slim AS builder

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies required for Python packages
# - gcc, g++, make: for compiling native extensions (asyncpg, numpy, etc.)
# - libpq-dev: PostgreSQL client library headers (asyncpg)
# - curl: for health checks
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for Docker layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose port 8000 (FastAPI default)
EXPOSE 8000

# Health check (readiness probe)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health/ready || exit 1

# Start application with Gunicorn + Uvicorn workers
# Configuration from scripts/startup.sh:
# - 2 workers (adjust based on CPU cores: recommended 2-4 * num_cores)
# - Uvicorn worker class for async support
# - Bind to all interfaces on port 8000
# - 600s timeout for long-running Azure AI operations
ENV PORT=8000
CMD ["gunicorn", "-w", "2", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8000", "--timeout", "600", "api_server:app"]
