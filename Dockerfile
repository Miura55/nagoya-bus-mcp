# Build stage: use uv to build wheel and install into a relocatable target dir
FROM ghcr.io/astral-sh/uv:python3.11-bookworm AS build
WORKDIR /app
COPY . /app

RUN uv build

# Install the built wheel into a target directory we can copy into distroless
# Avoid relying on console_scripts paths; we will run via "python -m"
# Use uv pip install with --target to install the wheel and all its dependencies
# The --target option should install all transitive dependencies automatically
RUN uv pip install --no-cache-dir --target=/opt/site-packages /app/dist/*.whl && \
    # Verify that async_timeout is installed (it's a transitive dependency of redis)
    python3 -c "import sys; sys.path.insert(0, '/opt/site-packages'); import async_timeout; print('async_timeout found')" || \
    echo "Warning: async_timeout not found, installing explicitly" && \
    uv pip install --no-cache-dir --target=/opt/site-packages async_timeout


# Runtime stage: distroless has no shell, so do not RUN anything here
FROM gcr.io/distroless/python3-debian12:debug

# Set PYTHONPATH to include the site-packages directory
ENV PYTHONPATH=/opt/site-packages

# Add installed packages
COPY --from=build /opt/site-packages /opt/site-packages

USER nonroot

# Run the module directly to avoid console_script shebang path issues
# distrolessイメージのENTRYPOINTを明示的に設定し、CMDでモジュールを指定
# python3のパスを確認してから設定（distrolessでは/usr/bin/python3が正しいパス）
ENTRYPOINT ["python3"]
CMD ["-m", "nagoya_bus_mcp"]
