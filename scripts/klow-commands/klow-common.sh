#!/bin/bash
# klow-common.sh - Shared functions for all klow-* commands
# Source this file: source /home/klowalski/bin/klow-common.sh

# ============================================================================
# CONFIGURATION
# ============================================================================

KLOW_HOME="/home/klowalski"
KLOW_CONFIG="$KLOW_HOME/.config"
KLOW_LOGS="$KLOW_HOME/logs"
KLOW_BLOCKED_PATHS="$KLOW_CONFIG/blocked-paths.txt"
KLOW_MANIFEST="$KLOW_CONFIG/manifest.yaml"

# Windows paths (via WSL2 mount)
WINDOWS_USER="Daniel"
WINDOWS_HOME="/mnt/c/Users/$WINDOWS_USER"
KLOW_WORKSPACE="$WINDOWS_HOME/Desktop/KlowalskiWorkspace"
KLOW_TRASH="$WINDOWS_HOME/Desktop/KlowalskiTrash"

# ============================================================================
# LOGGING
# ============================================================================

klow_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local logfile="$KLOW_LOGS/audit-$(date '+%Y-%m-%d').log"

    echo "[$timestamp] [$level] $message" >> "$logfile"
}

klow_log_action() {
    local action="$1"
    local details="$2"
    klow_log "ACTION" "$action: $details"
}

klow_log_error() {
    local message="$1"
    klow_log "ERROR" "$message"
    echo "ERROR: $message" >&2
}

klow_log_denied() {
    local reason="$1"
    klow_log "DENIED" "$reason"
    echo "ACCESS DENIED: $reason" >&2
}

# ============================================================================
# PATH VALIDATION
# ============================================================================

# Default blocked patterns (hardcoded for security)
BLOCKED_PATTERNS=(
    "*.ssh*"
    "*/.ssh/*"
    "*.env"
    "*/.env"
    "*.env.*"
    "*credential*"
    "*secret*"
    "*password*"
    "*/AppData/*"
    "/mnt/c/Windows/*"
    "/mnt/c/Program Files/*"
    "/mnt/c/Program Files (x86)/*"
    "*/node_modules/*"
    "*/.git/objects/*"
)

is_path_blocked() {
    local path="$1"
    local resolved_path=$(realpath -m "$path" 2>/dev/null || echo "$path")

    # Check hardcoded patterns
    for pattern in "${BLOCKED_PATTERNS[@]}"; do
        if [[ "$resolved_path" == $pattern ]]; then
            return 0  # Blocked
        fi
    done

    # Check custom blocked paths file
    if [[ -f "$KLOW_BLOCKED_PATHS" ]]; then
        while IFS= read -r blocked; do
            [[ -z "$blocked" || "$blocked" == \#* ]] && continue
            if [[ "$resolved_path" == $blocked* ]] || [[ "$resolved_path" == *"$blocked"* ]]; then
                return 0  # Blocked
            fi
        done < "$KLOW_BLOCKED_PATHS"
    fi

    return 1  # Not blocked
}

validate_path() {
    local path="$1"
    local operation="$2"

    # Check if path exists (for read operations)
    if [[ "$operation" == "read" ]] && [[ ! -e "$path" ]]; then
        klow_log_error "Path does not exist: $path"
        return 1
    fi

    # Check blocklist
    if is_path_blocked "$path"; then
        klow_log_denied "Blocked path: $path"
        return 1
    fi

    return 0
}

# Check if path is within allowed write areas
is_writable_path() {
    local path="$1"
    local resolved=$(realpath -m "$path" 2>/dev/null || echo "$path")

    # Only workspace and trash are writable
    if [[ "$resolved" == "$KLOW_WORKSPACE"* ]] || [[ "$resolved" == "$KLOW_TRASH"* ]]; then
        return 0
    fi

    return 1
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

require_args() {
    local min="$1"
    local actual="$2"
    local usage="$3"

    if [[ "$actual" -lt "$min" ]]; then
        echo "Usage: $usage"
        exit 1
    fi
}

confirm_action() {
    local prompt="$1"
    echo -n "$prompt [y/N]: "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

human_size() {
    local bytes="$1"
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))K"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$((bytes / 1048576))M"
    else
        echo "$((bytes / 1073741824))G"
    fi
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Ensure log directory exists
mkdir -p "$KLOW_LOGS" 2>/dev/null

# Log script invocation (called by each klow-* command)
klow_init() {
    local cmd="$1"
    shift
    klow_log "INVOKE" "$cmd $*"
}
