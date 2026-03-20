#!/usr/bin/env python3

"""Direct NotebookLM API client using authentication cookies.

This module provides a direct API client for Google NotebookLM that bypasses
the nlm CLI and uses direct HTTP requests with authentication cookies.

This approach works when the nlm CLI encounters 403 Forbidden errors, as it
uses the raw NotebookLM API endpoints directly.
"""

import json
import logging
import os
from typing import Optional
import requests
from pathlib import Path

logger = logging.getLogger(__name__)


class NotebookLMAPI:
    """Direct API client for Google NotebookLM."""

    BASE_URL = "https://notebooklm.google.com/_/LabsTailwindUi/data/batchexecute"
    COOKIE_FILE = Path.home() / ".notebooklm" / "cookies.txt"

    def __init__(self, cookies: Optional[str] = None):
        """Initialize the NotebookLM API client.

        Args:
            cookies: Cookie string in format "name=value; name2=value2..."
                    If not provided, loads from ~/.notebooklm/cookies.txt
        """
        self.cookies = cookies or self._load_cookies()
        self.session = self._create_session()

    def _load_cookies(self) -> str:
        """Load cookies from file or environment."""
        # Try environment variable first
        if env_cookies := os.environ.get("NOTEBOOKLM_COOKIES"):
            return env_cookies

        # Try cookie file
        if self.COOKIE_FILE.exists():
            with open(self.COOKIE_FILE) as f:
                return f.read().strip()

        raise ValueError(
            "No NotebookLM cookies found. "
            "Set NOTEBOOKLM_COOKIES environment variable or "
            f"save cookies to {self.COOKIE_FILE}"
        )

    def _create_session(self) -> requests.Session:
        """Create an authenticated HTTP session."""
        session = requests.Session()

        # Parse and set cookies
        if self.cookies:
            for cookie_pair in self.cookies.split(";"):
                if "=" in cookie_pair:
                    name, value = cookie_pair.strip().split("=", 1)
                    session.cookies.set(name, value)

        # Set default headers
        session.headers.update({
            "accept": "*/*",
            "accept-language": "en-US,en;q=0.9",
            "content-type": "application/x-www-form-urlencoded;charset=UTF-8",
            "origin": "https://notebooklm.google.com",
            "referer": "https://notebooklm.google.com/",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "x-same-domain": "1",
            "user-agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/146.0.0.0 Safari/537.36"
            ),
        })

        return session

    def _make_request(self, rpc_id: str, request_data: list) -> dict:
        """Make a batchexecute API request.

        Args:
            rpc_id: RPC method ID (e.g., "ZwVcOc" for list notebooks)
            request_data: Request payload as list

        Returns:
            Parsed JSON response
        """
        payload = {
            "f.req": json.dumps([[[rpc_id, json.dumps(request_data), None, "generic"]]])
        }

        try:
            response = self.session.post(
                self.BASE_URL,
                data=payload,
                timeout=30
            )
            response.raise_for_status()

            # Parse response (NotebookLM returns JSONL format)
            text = response.text
            if text.startswith(")]}'\n"):
                text = text[5:]  # Remove XSRF protection prefix

            # Parse JSON lines
            for line in text.strip().split("\n"):
                if line:
                    try:
                        return json.loads(line)
                    except json.JSONDecodeError:
                        continue

            return {"error": "No valid JSON in response"}

        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {e}")
            return {"error": str(e)}

    def list_notebooks(self) -> dict:
        """List all NotebookLM notebooks."""
        # Request format for listing notebooks
        request_data = [
            None,
            [1, None, None, None, None, None, None, None, None, None, [1]]
        ]
        return self._make_request("ZwVcOc", request_data)

    def create_notebook(self, name: str, description: str = "") -> dict:
        """Create a new NotebookLM notebook.

        Args:
            name: Notebook name
            description: Optional notebook description

        Returns:
            API response with created notebook data
        """
        request_data = [
            None,
            [name, description]
        ]
        return self._make_request("RN3aSd", request_data)

    def get_notebook(self, notebook_id: str) -> dict:
        """Get notebook details.

        Args:
            notebook_id: The notebook ID

        Returns:
            Notebook data
        """
        request_data = [notebook_id]
        return self._make_request("FOoV1d", request_data)

    def delete_notebook(self, notebook_id: str) -> dict:
        """Delete a notebook.

        Args:
            notebook_id: The notebook ID

        Returns:
            API response confirming deletion
        """
        request_data = [notebook_id]
        return self._make_request("F1d3Kd", request_data)

    def add_source(self, notebook_id: str, source_url: str) -> dict:
        """Add a source to a notebook.

        Args:
            notebook_id: The notebook ID
            source_url: URL or file path of the source

        Returns:
            API response with added source data
        """
        request_data = [
            notebook_id,
            [source_url]
        ]
        return self._make_request("dW4Zld", request_data)

    def list_sources(self, notebook_id: str) -> dict:
        """List sources in a notebook.

        Args:
            notebook_id: The notebook ID

        Returns:
            List of sources
        """
        request_data = [notebook_id]
        return self._make_request("BxZ8od", request_data)

    def sync_sources(self, notebook_id: str) -> dict:
        """Sync sources in a notebook.

        Args:
            notebook_id: The notebook ID

        Returns:
            Sync status
        """
        request_data = [notebook_id]
        return self._make_request("MZvQld", request_data)

    def get_insights(self, notebook_id: str) -> dict:
        """Get AI insights for a notebook.

        Args:
            notebook_id: The notebook ID

        Returns:
            Insights data
        """
        request_data = [notebook_id]
        return self._make_request("X0ZYod", request_data)

    def generate_audio(self, notebook_id: str) -> dict:
        """Generate audio notes for a notebook.

        Args:
            notebook_id: The notebook ID

        Returns:
            Audio generation status
        """
        request_data = [notebook_id]
        return self._make_request("Y1AZod", request_data)

    def get_audio(self, notebook_id: str) -> dict:
        """Get generated audio for a notebook.

        Args:
            notebook_id: The notebook ID

        Returns:
            Audio data and URLs
        """
        request_data = [notebook_id]
        return self._make_request("Z2BAod", request_data)


def main():
    """Example: List NotebookLM notebooks."""
    try:
        api = NotebookLMAPI()
        result = api.list_notebooks()
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
