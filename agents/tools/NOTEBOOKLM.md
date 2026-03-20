# NotebookLM MCP Server Integration

This directory includes two approaches to integrate NotebookLM with Claude agents:

1. **Direct API approach** (`notebooklm_api_mcp.py`) - Recommended for most users
2. **CLI wrapper approach** (`notebooklm_mcp.py`) - Uses the `notebooklm-mcp-cli` package

## Setup

### Option 1: Direct API (Recommended)

The direct API approach works around authentication issues by making direct HTTP requests to NotebookLM:

#### 1. Install Dependencies

```bash
pip install requests mcp
```

#### 2. Set Up Authentication

Save your authentication cookies to `~/.notebooklm/cookies.txt`:

```bash
mkdir -p ~/.notebooklm
# Paste your cookies (from browser) into this file:
echo "SID=...; SAPISID=...; APISID=..." > ~/.notebooklm/cookies.txt
```

Or set them via environment variable:

```bash
export NOTEBOOKLM_COOKIES="SID=...; SAPISID=...; APISID=..."
```

#### 3. Configure Your Agent

Add the direct API MCP server to your agent:

```python
from agents.agent import Agent

agent = Agent(
    name="NotebookLM Assistant",
    system="You are an AI assistant with access to NotebookLM.",
    mcp_servers=[
        {
            "type": "stdio",
            "command": "python3",
            "args": ["agents/tools/notebooklm_api_mcp.py"]
        }
    ]
)
```

### Option 2: CLI Wrapper

The NotebookLM MCP server is provided by the `notebooklm-mcp-cli` package:

```bash
pip install notebooklm-mcp-cli
```

#### 4. Test the Connection

Test your setup with a simple Python script:

```python
from agents.tools.notebooklm_api import NotebookLMAPI

api = NotebookLMAPI()
notebooks = api.list_notebooks()
print(notebooks)
```

If this works, you're ready to use the MCP server with your agent!

### Troubleshooting Direct API

**403 Forbidden Error:** Your cookies may be expired or invalid. Get fresh cookies from your browser:
1. Open https://notebooklm.google.com
2. Open DevTools (F12) → Application → Cookies
3. Copy relevant cookies (SID, SAPISID, APISID, etc.)
4. Update `~/.notebooklm/cookies.txt`

**Connection Error:** Verify:
- You have internet connectivity
- `requests` is installed: `pip install requests`
- Your cookies are properly formatted

### CLI Wrapper Approach

If you prefer using the official nlm CLI:

#### 1. Install Dependencies

```bash
pip install notebooklm-mcp-cli
```

#### 2. Configure Your Agent

```python
from agents.agent import Agent

agent = Agent(
    name="NotebookLM Assistant",
    system="You are an AI assistant with access to NotebookLM.",
    mcp_servers=[
        {
            "type": "stdio",
            "command": "python3",
            "args": ["agents/tools/notebooklm_mcp.py"]
        }
    ]
)
```

#### 3. Authenticate

When you first use NotebookLM tools, you'll be guided to authenticate with Google:

1. The agent will ask you to log in to NotebookLM
2. A Chrome browser window will open automatically
3. Sign in with your Google account
4. Your session will persist for future conversations

**Important**: Your Google credentials never leave your machine. Authentication happens locally using browser login.

## Available Tools

### Direct API Tools (Recommended)

The direct API MCP server exposes the following core tools:

- **Notebook Management**:
  - `notebook_list` - List all notebooks
  - `notebook_create` - Create a new notebook
  - `notebook_get` - Get notebook details
  - `notebook_delete` - Delete a notebook

- **Source Management**:
  - `source_add` - Add source to notebook
  - `source_list` - List sources in notebook
  - `source_sync` - Sync notebook sources

- **AI Analysis**:
  - `notebook_insights` - Get AI insights for notebook

- **Audio Generation**:
  - `audio_generate` - Generate audio notes
  - `audio_get` - Get generated audio

### CLI Tools (CLI Wrapper)

The `notebooklm-mcp-cli` based server exposes 35+ tools including:

- Full notebook management (create, list, delete, get)
- Source management (add, delete, sync)
- Audio generation for research summaries
- Insights and research analysis
- Studio artifact creation
- And more!

## Example Usage

```python
# Create a notebook with research documents
user_input = """
Create a NotebookLM notebook called 'AI Research' and add these sources:
- https://arxiv.org/abs/2401.00000
- https://github.com/anthropics/anthropic-sdk-python

Then generate audio notes about the key topics.
"""

response = agent.run(user_input)
```

## Troubleshooting

### Command not found: notebooklm-mcp

Make sure `notebooklm-mcp-cli` is installed in your Python environment:

```bash
pip install notebooklm-mcp-cli
which notebooklm-mcp  # Verify installation
```

### Authentication fails

- Clear your browser cache if you're having login issues
- Try logging in again: the agent will prompt you when needed
- Session cookies are stored locally in your home directory

### Server connection issues

Ensure the MCP server is properly configured in your agent:

```python
# Verify the path to notebooklm_mcp.py
import os
mcp_path = os.path.join(os.path.dirname(__file__), "agents/tools/notebooklm_mcp.py")
print(f"MCP script exists: {os.path.exists(mcp_path)}")
```

## Architecture

### Direct API Approach (Recommended)

```
Claude Agent
    ↓
MCPConnection (stdio)
    ↓
notebooklm_api_mcp.py
    ↓
notebooklm_api.py (direct HTTP client)
    ↓
Google NotebookLM API
```

This approach:
- ✅ Works around nlm CLI authentication issues
- ✅ Makes direct HTTPS requests with cookies
- ✅ Provides immediate feedback
- ✅ No browser automation required (for running)
- ❌ Requires manual cookie management

### CLI Wrapper Approach

```
Claude Agent
    ↓
MCPConnection (stdio)
    ↓
notebooklm_mcp.py (wrapper)
    ↓
notebooklm-mcp (official MCP server)
    ↓
Google NotebookLM API
```

This approach:
- ✅ Official NotebookLM CLI
- ✅ Full feature set (35+ tools)
- ✅ Automatic authentication
- ❌ May encounter 403 authentication errors on some accounts
- ❌ Requires Chrome/Chromium for browser-based login

## Choosing an Approach

**Use Direct API if:**
- You're getting 403 errors with the CLI
- You prefer managing authentication yourself
- You don't need advanced features

**Use CLI Wrapper if:**
- Authentication works for your account
- You need advanced features (studio artifacts, etc.)
- You prefer official support
