# bugzilla-readonly-mcp

`bugzilla-readonly-mcp` is a read-only Model Context Protocol (MCP) server for Bugzilla.
It exposes bug lookup/search tools and does not provide write/mutation actions.

## Features

- Read bug details by ID
- Read bug comments (public by default, optional private comments)
- Search bugs using Bugzilla quicksearch syntax
- Return server and bug URLs
- Return runtime server info
- Return current request headers with API key masked
- Provide a prompt template for summarizing bug comments

## Requirements

- Python `3.13`
- Network access to your Bugzilla instance
- Bugzilla API key with least-privilege access

## Install

From source:

```bash
git clone https://github.com/larrychannon/bugzilla-readonly-mcp.git
cd bugzilla-readonly-mcp
uv sync --extra dev
```

## Run (HTTP transport)

```bash
PYTHONPATH=src uv run bugzilla-readonly-mcp \
  --transport http \
  --bugzilla-server https://bugzilla.example.com \
  --host 127.0.0.1 \
  --port 8000
```

Endpoint:

```text
http://127.0.0.1:8000/mcp/
```

## Configuration

CLI arguments:

- `--bugzilla-server` (required): base Bugzilla URL
- `--host` (default `127.0.0.1`)
- `--port` (default `8000`)
- `--api-key-header` (default `ApiKey`)
- `--transport` (`http` or `stdio`, default `http`)
- `--api-key` (optional for HTTP, required for stdio unless `BUGZILLA_API_KEY` is set)

Environment variables:

- `BUGZILLA_SERVER`
- `MCP_HOST`
- `MCP_PORT`
- `MCP_API_KEY_HEADER`
- `MCP_TRANSPORT`
- `BUGZILLA_API_KEY`
- `LOG_LEVEL`

## Authentication

- HTTP transport: client requests should include an API key header (default `ApiKey`).
- stdio transport: provide API key using `--api-key` or `BUGZILLA_API_KEY`.

Example HTTP request:

```bash
curl -X POST http://127.0.0.1:8000/mcp/ \
  -H "ApiKey: YOUR_API_KEY_HERE" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"server_url"},"id":1}'
```

## Codex Auto-Start (stdio)

Option 1: run from local clone.

```toml
[mcp_servers.bugzilla_readonly]
command = "bash"
args = ["-lc", "cd '/ABSOLUTE/PATH/bugzilla-readonly-mcp' && PYTHONPATH=src uv run bugzilla-readonly-mcp --transport stdio --bugzilla-server https://bugzilla.example.com --api-key \"$BUGZILLA_API_KEY\""]
env = { BUGZILLA_API_KEY = "YOUR_API_KEY" }
```

Option 2: run directly from GitHub with `uvx`.

```toml
[mcp_servers.bugzilla_readonly]
command = "uvx"
args = ["--from", "git+https://github.com/larrychannon/bugzilla-readonly-mcp", "bugzilla-readonly-mcp", "--transport", "stdio", "--bugzilla-server", "https://bugzilla.example.com"]
env = { BUGZILLA_API_KEY = "YOUR_API_KEY" }
```

## MCP tools

- `bug_info(id: int)`
- `bug_comments(id: int, include_private_comments: bool = False)`
- `bugs_quicksearch(query: str, status: str = "ALL", include_fields: str = "id,product,component,assigned_to,status,resolution,summary,last_change_time", limit: int = 50, offset: int = 0)`
- `learn_quicksearch_syntax()`
- `server_url()`
- `bug_url(bug_id: int)`
- `mcp_server_info()`
- `get_current_headers()`

Prompt:

- `summarize_bug_comments(id: int)`

## Security Notes

- The server forwards API keys to Bugzilla as `api_key` query parameter (Bugzilla REST behavior).
- `get_current_headers()` masks the configured API key header value before returning headers.
- Use TLS and trusted network boundaries.

## Docker (optional)

Build:

```bash
docker build -t bugzilla-readonly-mcp .
```

Run:

```bash
docker run -p 8000:8000 bugzilla-readonly-mcp \
  --bugzilla-server https://bugzilla.example.com \
  --host 0.0.0.0 \
  --port 8000
```
