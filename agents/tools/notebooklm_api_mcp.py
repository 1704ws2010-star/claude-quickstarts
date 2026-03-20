#!/usr/bin/env python3

"""NotebookLM MCP Server using direct API access.

This module provides an MCP server for NotebookLM that uses direct API calls
instead of the nlm CLI. This works around authentication issues and provides
more direct control over API requests.

The server exposes tools for:
- Notebook management (list, create, delete, get)
- Source management (add, list, sync)
- Audio generation and retrieval
- AI insights generation
"""

import json
import logging
import os
import sys
from typing import Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger(__name__)

try:
    import mcp.server.stdio
    from mcp.types import Tool, TextContent, ToolResult
    from notebooklm_api import NotebookLMAPI
except ImportError as e:
    logger.error(f"Failed to import required modules: {e}")
    sys.exit(1)


class NotebookLMMCPServer:
    """MCP Server for NotebookLM with direct API access."""

    def __init__(self):
        """Initialize the MCP server."""
        self.api: NotebookLMAPI | None = None
        self.server = mcp.server.stdio.StdioServer()
        self._register_tools()

    def _get_api(self) -> NotebookLMAPI:
        """Get or create the API client."""
        if not self.api:
            try:
                self.api = NotebookLMAPI()
            except ValueError as e:
                raise RuntimeError(f"Failed to initialize NotebookLM API: {e}")
        return self.api

    def _register_tools(self) -> None:
        """Register all available tools."""
        tools = [
            self._create_tool(
                "notebook_list",
                "List all NotebookLM notebooks",
                {},
                self.handle_notebook_list,
            ),
            self._create_tool(
                "notebook_create",
                "Create a new NotebookLM notebook",
                {
                    "name": {"type": "string", "description": "Notebook name"},
                    "description": {
                        "type": "string",
                        "description": "Optional notebook description",
                    },
                },
                self.handle_notebook_create,
            ),
            self._create_tool(
                "notebook_get",
                "Get details of a specific notebook",
                {
                    "notebook_id": {
                        "type": "string",
                        "description": "The notebook ID",
                    }
                },
                self.handle_notebook_get,
            ),
            self._create_tool(
                "notebook_delete",
                "Delete a notebook",
                {
                    "notebook_id": {
                        "type": "string",
                        "description": "The notebook ID",
                    }
                },
                self.handle_notebook_delete,
            ),
            self._create_tool(
                "source_add",
                "Add a source to a notebook",
                {
                    "notebook_id": {
                        "type": "string",
                        "description": "The notebook ID",
                    },
                    "source_url": {
                        "type": "string",
                        "description": "URL or file path of the source",
                    },
                },
                self.handle_source_add,
            ),
            self._create_tool(
                "source_list",
                "List sources in a notebook",
                {
                    "notebook_id": {
                        "type": "string",
                        "description": "The notebook ID",
                    }
                },
                self.handle_source_list,
            ),
            self._create_tool(
                "source_sync",
                "Sync sources in a notebook",
                {
                    "notebook_id": {
                        "type": "string",
                        "description": "The notebook ID",
                    }
                },
                self.handle_source_sync,
            ),
            self._create_tool(
                "notebook_insights",
                "Get AI insights for a notebook",
                {
                    "notebook_id": {
                        "type": "string",
                        "description": "The notebook ID",
                    }
                },
                self.handle_notebook_insights,
            ),
            self._create_tool(
                "audio_generate",
                "Generate audio notes for a notebook",
                {
                    "notebook_id": {
                        "type": "string",
                        "description": "The notebook ID",
                    }
                },
                self.handle_audio_generate,
            ),
            self._create_tool(
                "audio_get",
                "Get generated audio for a notebook",
                {
                    "notebook_id": {
                        "type": "string",
                        "description": "The notebook ID",
                    }
                },
                self.handle_audio_get,
            ),
        ]

        for tool in tools:
            self.server.add_tool(tool.name, tool.handler)

    @staticmethod
    def _create_tool(
        name: str,
        description: str,
        input_schema: dict,
        handler,
    ) -> Tool:
        """Create a tool definition."""
        return Tool(
            name=name,
            description=description,
            inputSchema={
                "type": "object",
                "properties": input_schema,
                "required": list(input_schema.keys()) if input_schema else [],
            },
            handler=handler,
        )

    async def handle_notebook_list(self, **kwargs) -> ToolResult:
        """Handle notebook_list tool."""
        try:
            api = self._get_api()
            result = api.list_notebooks()
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error listing notebooks: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def handle_notebook_create(self, **kwargs) -> ToolResult:
        """Handle notebook_create tool."""
        try:
            api = self._get_api()
            name = kwargs.get("name")
            description = kwargs.get("description", "")

            if not name:
                raise ValueError("notebook name is required")

            result = api.create_notebook(name, description)
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error creating notebook: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def handle_notebook_get(self, **kwargs) -> ToolResult:
        """Handle notebook_get tool."""
        try:
            api = self._get_api()
            notebook_id = kwargs.get("notebook_id")

            if not notebook_id:
                raise ValueError("notebook_id is required")

            result = api.get_notebook(notebook_id)
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error getting notebook: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def handle_notebook_delete(self, **kwargs) -> ToolResult:
        """Handle notebook_delete tool."""
        try:
            api = self._get_api()
            notebook_id = kwargs.get("notebook_id")

            if not notebook_id:
                raise ValueError("notebook_id is required")

            result = api.delete_notebook(notebook_id)
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error deleting notebook: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def handle_source_add(self, **kwargs) -> ToolResult:
        """Handle source_add tool."""
        try:
            api = self._get_api()
            notebook_id = kwargs.get("notebook_id")
            source_url = kwargs.get("source_url")

            if not notebook_id or not source_url:
                raise ValueError("notebook_id and source_url are required")

            result = api.add_source(notebook_id, source_url)
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error adding source: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def handle_source_list(self, **kwargs) -> ToolResult:
        """Handle source_list tool."""
        try:
            api = self._get_api()
            notebook_id = kwargs.get("notebook_id")

            if not notebook_id:
                raise ValueError("notebook_id is required")

            result = api.list_sources(notebook_id)
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error listing sources: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def handle_source_sync(self, **kwargs) -> ToolResult:
        """Handle source_sync tool."""
        try:
            api = self._get_api()
            notebook_id = kwargs.get("notebook_id")

            if not notebook_id:
                raise ValueError("notebook_id is required")

            result = api.sync_sources(notebook_id)
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error syncing sources: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def handle_notebook_insights(self, **kwargs) -> ToolResult:
        """Handle notebook_insights tool."""
        try:
            api = self._get_api()
            notebook_id = kwargs.get("notebook_id")

            if not notebook_id:
                raise ValueError("notebook_id is required")

            result = api.get_insights(notebook_id)
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error getting insights: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def handle_audio_generate(self, **kwargs) -> ToolResult:
        """Handle audio_generate tool."""
        try:
            api = self._get_api()
            notebook_id = kwargs.get("notebook_id")

            if not notebook_id:
                raise ValueError("notebook_id is required")

            result = api.generate_audio(notebook_id)
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error generating audio: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def handle_audio_get(self, **kwargs) -> ToolResult:
        """Handle audio_get tool."""
        try:
            api = self._get_api()
            notebook_id = kwargs.get("notebook_id")

            if not notebook_id:
                raise ValueError("notebook_id is required")

            result = api.get_audio(notebook_id)
            return ToolResult(
                content=[TextContent(type="text", text=json.dumps(result, indent=2))],
                is_error=False,
            )
        except Exception as e:
            logger.error(f"Error getting audio: {e}")
            return ToolResult(
                content=[TextContent(type="text", text=f"Error: {e}")],
                is_error=True,
            )

    async def run(self) -> None:
        """Run the MCP server."""
        async with self.server:
            logger.info("NotebookLM MCP Server started")
            await self.server.wait()


async def main():
    """Main entry point."""
    server = NotebookLMMCPServer()
    await server.run()


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
