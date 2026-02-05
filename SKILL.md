---
name: windows-pc-organizer
description: Access a Windows PC remotely via SSH to organize files, manage desktop, and perform system tasks. Use when needing to: (1) organize or clean up files on the remote PC, (2) read/move/delete files on Windows desktop or folders, (3) check system status, (4) schedule shutdowns, or (5) work with designated workspace folders. Requires Tailscale network access and prior setup.
---

# Windows PC Organizer

Remote access to a Windows PC via SSH through Tailscale VPN for file organization tasks.

## Connection

```bash
ssh -p 2222 agent@<TAILSCALE_IP>
```

- **Port**: 2222 (WSL SSH)
- **User**: agent (restricted shell)
- **Network**: Tailscale only
- **Auth**: Ed25519 key

> Replace `<TAILSCALE_IP>` with the target PC's Tailscale IP address.

## Environment

Restricted shell (`rbash`) with only `klow-*` commands available. Standard shell commands are not directly accessible.

## Available Commands

| Command | Purpose |
|---------|---------|
| `klow-help` | List all commands |
| `klow-status` | System status (uptime, disk, memory) |
| `klow-list <path>` | List directory contents |
| `klow-tree <path>` | Directory tree view |
| `klow-read <file>` | Read file contents |
| `klow-workspace` | Manage workspace folder |
| `klow-organize` | File organization tools |
| `klow-mark-delete <file>` | Move to trash with manifest |
| `klow-manifest` | Create/view deletion manifests |
| `klow-shutdown [minutes]` | Schedule PC shutdown |
| `klow-shutdown-cancel` | Cancel scheduled shutdown |

## Key Paths

| Location | WSL Path | Access |
|----------|----------|--------|
| Desktop | `/mnt/c/Users/<USER>/Desktop` | Read |
| Workspace | `/mnt/c/Users/<USER>/Desktop/AgentWorkspace` | Read/Write |
| Trash | `/mnt/c/Users/<USER>/Desktop/AgentTrash` | Write only |
| Downloads | `/mnt/c/Users/<USER>/Downloads` | Read |
| Documents | `/mnt/c/Users/<USER>/Documents` | Read |

> Replace `<USER>` with the Windows username.

## Workflow: Organizing Files

1. **Survey**: `klow-list /mnt/c/Users/<USER>/Desktop`
2. **Inspect**: `klow-read <file>` for text files
3. **Organize**: Move to workspace with `klow-organize`
4. **Delete**: `klow-mark-delete <file>` creates manifest and moves to trash

The PC owner reviews trash and permanently deletes when ready.

## Workflow: Creating Manifests

When marking files for deletion, create a manifest explaining:
- What the file is
- Why it's being deleted
- Any dependencies or concerns

```bash
klow-mark-delete /mnt/c/Users/<USER>/Desktop/old-file.zip
# Follow prompts to create manifest
```

## Security Notes

- Restricted to `klow-*` commands only
- Cannot access system directories or sensitive paths
- All actions logged to `/home/agent/logs/`
- PC owner can revoke access instantly
- Firewall allows Tailscale connections only

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection refused | PC may be off or sleeping |
| Connection timeout | Check Tailscale is running on both ends |
| Permission denied | Verify SSH key is correct |
| Command not found | Use only `klow-*` commands |
| Path blocked | Check blocked-paths.txt for restrictions |
