# Krew Distribution Guide

This guide explains how to distribute kubectl-decode via Krew, the kubectl plugin manager.

## Prerequisites

1. Create a GitHub repository for this plugin
2. Create a GitHub release with a version tag (e.g., `v0.1.0`)
3. Install Krew: https://krew.sigs.k8s.io/docs/user-guide/setup/install/

## Steps to Publish

### 1. Create a GitHub Release

```bash
# Tag your release
git tag v0.1.0
git push origin v0.1.0

# Create a release on GitHub with the tag
# Download URL will be: https://github.com/crackmac/kubectl-decode-plugin/archive/v0.1.0.tar.gz
```

### 2. Calculate SHA256

```bash
# Download the release tarball
wget https://github.com/crackmac/kubectl-decode-plugin/archive/v0.1.0.tar.gz

# Calculate SHA256
sha256sum v0.1.0.tar.gz

# Update the sha256 field in .krew.yaml with this value
```

### 3. Update .krew.yaml

Replace the following placeholders in `.krew.yaml`:
- `crackmac` - Your GitHub username
- `REPLACE_WITH_ACTUAL_SHA256` - The SHA256 hash from step 2

### 4. Test Locally

```bash
# Install the plugin locally to test
kubectl krew install --manifest=.krew.yaml --archive=v0.1.0.tar.gz

# Test the plugin
kubectl decode --help
```

### 5. Submit to Krew Index

Fork and clone the krew-index repository:
```bash
git clone https://github.com/kubernetes-sigs/krew-index.git
cd krew-index
```

Copy your `.krew.yaml` to the plugins directory:
```bash
cp /path/to/kubectl-decode-plugin/.krew.yaml plugins/decode.yaml
```

Create a pull request to the krew-index repository following their guidelines:
https://krew.sigs.k8s.io/docs/developer-guide/release/

## Installation After Publishing

Once merged into the krew-index, users can install with:
```bash
kubectl krew install decode
```

## Updating the Plugin

For new releases:
1. Update version in `.krew.yaml` and `kubectl-decode` script
2. Create a new GitHub release
3. Calculate new SHA256
4. Submit updated manifest to krew-index

## Alternative: Custom Plugin Index

If you don't want to publish to the official krew-index, users can install directly:

```bash
kubectl krew install --manifest-url=https://raw.githubusercontent.com/crackmac/kubectl-decode-plugin/master/.krew.yaml
```

## References

- Krew Developer Guide: https://krew.sigs.k8s.io/docs/developer-guide/
- Krew Plugin Naming: https://krew.sigs.k8s.io/docs/developer-guide/plugin-naming/
- krew-index Repository: https://github.com/kubernetes-sigs/krew-index
