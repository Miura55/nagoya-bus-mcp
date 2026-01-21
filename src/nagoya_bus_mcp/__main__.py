"""Entry point for the Nagoya Bus MCP server."""

import asyncio
import logging
import sys

from nagoya_bus_mcp.mcp.server import Settings, build_mcp_server


def main() -> None:
    """Main entry point for the MCP server."""
    logging.basicConfig(level=logging.INFO, stream=sys.stderr)
    # Use /tmp for cache in containerized environments where home directory may not exist
    import os
    cache_path = os.getenv("CACHE_DB_PATH", "/tmp/hishel_cache.db")
    settings = Settings(
        cache_database_path=cache_path,
    )
    asyncio.run(build_mcp_server(settings).run_async())


if __name__ == "__main__":
    main()
