FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv

# Install the project into /app
WORKDIR /app

# Enable bytecode compilation for faster startup
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Copy required files for building the dependency environment
COPY pyproject.toml uv.lock README.md /app/

# Sync and install only dependencies (no project code yet)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Add the rest of the source code and install the project itself
ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# ------------------- Runtime Image -------------------
FROM python:3.12-slim-bookworm

WORKDIR /app

# Copy the virtualenv containing all dependencies and the MCP server CLI
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Ensure executables from the venv are first in PATH
ENV PATH="/app/.venv/bin:$PATH"

# Expose the port your MCP server listens on
EXPOSE 8000

# Note: Configure METRICOOL_USER_TOKEN and METRICOOL_USER_ID as runtime env vars in Render (or your chosen host)

# Run the MCP server, binding it to all interfaces
ENTRYPOINT ["mcp-metricool", "--host", "0.0.0.0", "--port", "8000"]
