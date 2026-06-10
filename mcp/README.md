# MCP servers

Model Context Protocol (MCP) servers maintained by CodeCrafters Automation.

Each server lives in its own subdirectory here (e.g. `mcp/<server-name>/`). A server can be:

- **Standalone** — run directly via its own command / package, and wired into Claude Code (or any MCP client) through that client's MCP config.
- **Bundled into a plugin** — a plugin under [`../plugins/`](../plugins/) can declare `mcpServers` in its `plugin.json` and reference files here with `${CLAUDE_PLUGIN_ROOT}`.

Nothing in this directory is part of the plugin marketplace catalog (`../.claude-plugin/marketplace.json`) unless a plugin explicitly references it.

_No servers yet._
