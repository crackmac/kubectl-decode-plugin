# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a kubectl plugin that decodes base64-encoded values in Kubernetes secrets. It's implemented as a bash script that follows the kubectl plugin naming convention (`kubectl-decode`). The plugin provides multiple output formats, namespace/context support, and helpful error messages.

## Architecture

The plugin is a single bash script (`kubectl-decode`) with the following structure:

1. **Dependency checks** - Validates that `kubectl` and `jq` are installed before proceeding
2. **Argument parsing** - Uses a `while` loop with `case` statement to parse flags and arguments:
   - `-h/--help` - Shows usage information
   - `-n/--namespace` - Specifies Kubernetes namespace
   - `--context` - Specifies Kubernetes context
   - `-o/--output` - Specifies output format (json, yaml, table)
3. **Secret retrieval** - Builds and executes kubectl command with appropriate flags
4. **Error handling** - Captures kubectl exit codes and provides helpful error messages
5. **Output formatting** - Decodes base64 values and formats according to selected output type

The plugin uses the standard kubectl plugin mechanism - any executable named `kubectl-<plugin-name>` in the PATH becomes available as `kubectl <plugin-name>`.

## Commands

### Installation
```bash
# Make the script executable
chmod +x kubectl-decode

# Move to a directory in your PATH
mv kubectl-decode /usr/local/bin/
```

### Usage Examples
```bash
# Basic usage
kubectl decode <secret-name>

# With namespace
kubectl decode <secret-name> -n kube-system

# With output format
kubectl decode <secret-name> -o yaml
kubectl decode <secret-name> -o table

# With context
kubectl decode <secret-name> --context prod-cluster

# Combined flags
kubectl decode <secret-name> -n dev --context staging -o table

# Special commands
kubectl decode version    # Show version
kubectl decode config     # Show KUBECONFIG path
kubectl decode --help     # Show help
```

## Dependencies

- **kubectl** (required) - Kubernetes command-line tool
- **jq** (required) - JSON processor for parsing and decoding
- **yq** (optional) - Improves YAML output formatting
- **column** (usually pre-installed) - For table formatting
- **bash** - The script interpreter

## Key Features

### Output Formats
- **json** (default) - Returns decoded values as JSON object
- **yaml** - Converts to YAML format (uses yq if available, falls back to jq)
- **table** - Human-readable table with KEY and VALUE columns

### Error Handling
- Dependency validation on startup
- kubectl command error capture with helpful messages
- Automatic secret listing when no secret name provided
- Invalid output format detection

### Namespace/Context Support
The plugin properly passes namespace and context flags through to both:
- Secret retrieval commands
- Secret listing commands (when no name provided)

## Testing

Manual testing workflow:
1. Test dependency checks by temporarily renaming `jq` or `kubectl`
2. Test basic secret decoding: `kubectl decode <secret-name>`
3. Test all output formats: `-o json`, `-o yaml`, `-o table`
4. Test namespace support: `-n <namespace>`
5. Test context support: `--context <context>`
6. Test error cases:
   - No secret name (should list available secrets)
   - Non-existent secret (should show kubectl error)
   - Invalid output format (should show format error)
7. Test special commands: `version`, `config`, `--help`

Since this is a bash script, there are no automated tests currently. Testing requires access to a Kubernetes cluster with secrets.
