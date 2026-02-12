# bugzilla-readonly-mcp

`bugzilla-readonly-mcp` is a Model Context Protocol (MCP) server for integrating AI tools with Bugzilla in a controlled, read-only workflow.

Reference: adapted from [openSUSE/mcp-bugzilla](https://github.com/openSUSE/mcp-bugzilla).

## What this server provides

- Read Bug details by ID
- Read Bug comments (public by default, optional private comments)
- Search Bugs using Bugzilla quicksearch syntax
- Return server and bug URLs
- Return runtime server info
- Return current request headers with API key masked
- Provide a prompt template for summarizing Bug comments

## Requirements

- Python `3.13`
- Network access to your Bugzilla instance
- Bugzilla API key with least-privilege access

## Installation

### From source

```bash
git clone <your-repo-url>
cd bugzilla-readonly-mcp
uv sync --extra dev
```

### Run

```bash
PYTHONPATH=src uv run bugzilla-readonly-mcp \
  --transport http \
  --bugzilla-server https://bugzilla.example.com \
  --host 127.0.0.1 \
  --port 8000
```

Server endpoint:

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
- `--api-key` (optional for HTTP; required for stdio if no headers)

Environment variable equivalents:

- `BUGZILLA_SERVER`
- `MCP_HOST`
- `MCP_PORT`
- `MCP_API_KEY_HEADER`
- `MCP_TRANSPORT`
- `BUGZILLA_API_KEY`
- `LOG_LEVEL`

## Authentication

Every request must include an API key header (default header name is `ApiKey`).

Example request:

```bash
curl -X POST http://127.0.0.1:8000/mcp/ \
  -H "ApiKey: YOUR_API_KEY_HERE" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"server_url"},"id":1}'
```

## Codex Auto-Start (Command Mode)

If you want this server to start automatically when Codex launches, run it in `stdio` mode through Codex MCP config:

```toml
[mcp_servers.bugzilla_readonly]
command = "bash"
args = ["-lc", "cd '/Users/clchan/Documents/Coding/Bugzilla MCP for Release Notes/mcp-bugzilla' && PYTHONPATH=src uv run bugzilla-readonly-mcp --transport stdio --bugzilla-server https://bugzilla.example.com --api-key \"$BUGZILLA_API_KEY\""]
env = { BUGZILLA_API_KEY = "YOUR_API_KEY" }
```

This keeps startup in Codex (not system login), like Serena/context7 command servers.

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

## Security notes

- API keys are sent upstream to Bugzilla as query parameter `api_key` by the current implementation.
- `get_current_headers()` masks the configured API key header value before returning headers.
- Run behind trusted network boundaries and TLS.

## Docker (optional)

Build locally:

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
