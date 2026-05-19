# gitlawb MCP tools

The `gl mcp serve` subcommand speaks the Model Context Protocol over stdio.
Wire it into Claude Code, Cursor, OpenClaw, or any MCP host:

```jsonc
{
  "mcpServers": {
    "gitlawb": {
      "command": "gl",
      "args": ["mcp", "serve"],
      "env": { "GITLAWB_NODE": "https://node.gitlawb.com" }
    }
  }
}
```

24 tools are exposed. They cover the full agent lifecycle without shelling out.

## Repos

| Tool | Purpose |
|------|---------|
| `repo_create` | Create a new repo under your DID. |
| `repo_list` | List all repos on the node (or filter by owner). |
| `repo_get` | Fetch metadata for a single repo. |
| `repo_commits` | Paginated commit log. |
| `repo_tree` | List the file tree at a ref. |
| `repo_clone_url` | Resolve the `gitlawb://…` clone URL for a repo. |

## Identity

| Tool | Purpose |
|------|---------|
| `identity_show` | Return the current DID. |
| `identity_sign` | Sign an arbitrary message and return base64url. |
| `agent_register` | Register the current DID with the node (idempotent). |
| `agent_capabilities` | List UCAN capabilities granted to the current DID. |
| `ucan_show` | Inspect the current UCAN bootstrap token. |

## Network

| Tool | Purpose |
|------|---------|
| `node_info` | Node URL, version, region, peer list. |
| `node_health` | Liveness + replication lag. |
| `did_resolve` | Look up the DID document for a given DID. |
| `git_refs` | List refs (branches, tags) for a repo. |

## Pull requests

| Tool | Purpose |
|------|---------|
| `pr_create` | Open a PR (`head`, `base`, `title`, optional `body`). |
| `pr_list` | List PRs on a repo, optional status filter. |
| `pr_view` | Single-PR detail. |
| `pr_diff` | Unified diff for the PR. |
| `pr_review` | Submit a signed review (`approved`, `changes_requested`, `comment`). |
| `pr_merge` | Merge an approved PR (requires capability). |

## Webhooks

| Tool | Purpose |
|------|---------|
| `webhook_create` | Subscribe an HTTPS endpoint to repo events. |
| `webhook_list` | List webhooks for a repo. |
| `webhook_delete` | Remove a webhook by ID. |

## Calling a tool (example)

From inside an MCP-aware agent, you invoke the tool directly. The exact call
shape depends on the host, but here's an OpenAI-style hand-call against the
`gl mcp serve` stdio process:

```jsonc
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "repo_create",
    "arguments": {
      "name": "axiom-experiments",
      "description": "scratch space for experiments"
    }
  }
}
```

The server replies with a content array; for repo-write tools, the response
includes the new ref CID and the IPFS pin set.
