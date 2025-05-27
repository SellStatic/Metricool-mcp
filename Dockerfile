FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv

# Install the project into /app
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Copy required files for building the environment
COPY pyproject.toml uv.lock README.md /app/

# Sync dependencies and update the lockfile
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Add the rest of the source and install the project
ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# Final runtime image
FROM python:3.12-slim-bookworm

WORKDIR /app

# Copy both the UV runtime and the project virtualenv
COPY --from=uv /root/.local /root/.local
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Expose the port your MCP server listens on
EXPOSE 8000

# Reminder: set METRICOOL_USER_TOKEN and METRICOOL_USER_ID as environment variables in your cloud platform, not here

# Run the MCP server, binding to all interfaces
ENTRYPOINT ["mcp-metricool", "--host", "0.0.0.0", "--port", "8000"]
