# kubectl-decode

A kubectl plugin that decodes base64-encoded values in Kubernetes secrets, making them easily readable.

## Features

- 🔓 Decode all secret values with a single command
- 📋 Multiple output formats: JSON, YAML, and table
- 🎯 Namespace and context support
- 📝 Helpful error messages with secret listing
- ✅ Dependency validation on startup

## Dependencies

- **kubectl** - Kubernetes command-line tool ([installation guide](https://kubernetes.io/docs/tasks/tools/))
- **jq** - JSON processor ([installation guide](https://stedolan.github.io/jq/download/))
- **yq** (optional) - For better YAML formatting ([installation guide](https://github.com/mikefarah/yq))

## Installation

### Option 1: Manual Installation

1. Download or clone this repository
2. Make the script executable:
   ```bash
   chmod +x kubectl-decode
   ```
3. Move it to a directory in your PATH:
   ```bash
   mv kubectl-decode /usr/local/bin/
   # or
   mv kubectl-decode ~/bin/
   ```

### Option 2: Via Krew (Future)

Once published to the Krew plugin index:
```bash
kubectl krew install decode
```

See [KREW_DISTRIBUTION.md](KREW_DISTRIBUTION.md) for information on publishing to Krew.

## Usage

### Basic Usage

Decode a secret in the current namespace:
```bash
kubectl decode my-secret
```

### Output Formats

**JSON format (default):**
```bash
kubectl decode docker-registry
# or explicitly
kubectl decode docker-registry -o json
```

Output:
```json
{
  ".dockerconfigjson": "{\n  \"auths\": {\n    \"docker.io\": {\n      \"auth\": \"dXNlcjpwYXNz\"\n    }\n  }\n}"
}
```

**YAML format:**
```bash
kubectl decode my-secret -o yaml
```

**Table format (human-readable):**
```bash
kubectl decode my-secret -o table
```

Output:
```
KEY                VALUE
---                -----
username           admin
password           super-secret-password
database           production-db
```

### Namespace and Context

**Specify namespace:**
```bash
kubectl decode my-secret -n kube-system
kubectl decode my-secret --namespace production
```

**Specify context:**
```bash
kubectl decode my-secret --context staging-cluster
```

**Combine flags:**
```bash
kubectl decode my-secret -n dev --context staging -o table
```

### Other Commands

**Show help:**
```bash
kubectl decode --help
```

**Show version:**
```bash
kubectl decode version
```

**Show current KUBECONFIG:**
```bash
kubectl decode config
```

### Error Handling

If you don't specify a secret name, the plugin will show available secrets:
```bash
$ kubectl decode
Error: Missing name of secret
Run 'kubectl decode --help' for usage information

Available secrets:
NAME                 TYPE                                  DATA   AGE
docker-registry      kubernetes.io/dockerconfigjson        1      5d
my-secret            Opaque                                3      2d
```

## Reference

Based on the [kubectl plugin documentation](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/#writing-kubectl-plugins)