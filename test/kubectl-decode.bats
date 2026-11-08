#!/usr/bin/env bats
#
# Tests for kubectl-decode. kubectl is replaced by test/bin/kubectl, a stub
# that records its arguments and replays canned output, so no cluster is
# needed. Run with: bats test/

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    PLUGIN="$REPO_ROOT/kubectl-decode"

    # The plugin runs with an isolated PATH: the kubectl stub plus only the
    # tools it needs, so results don't depend on the host (e.g. whether yq is
    # installed). bats itself keeps the normal PATH.
    TOOLS="$BATS_TEST_TMPDIR/tools"
    mkdir -p "$TOOLS"
    local tool
    for tool in bash cat column jq; do
        ln -s "$(command -v "$tool")" "$TOOLS/$tool"
    done
    PLUGIN_PATH="$REPO_ROOT/test/bin:$TOOLS"

    export FAKE_KUBECTL_ARGS="$BATS_TEST_TMPDIR/kubectl-args"
    export FAKE_KUBECTL_STDOUT="$BATS_TEST_TMPDIR/kubectl-stdout"
    export FAKE_KUBECTL_STDERR="$BATS_TEST_TMPDIR/kubectl-stderr"
    export FAKE_KUBECTL_EXIT=0
    : > "$FAKE_KUBECTL_STDOUT"
    : > "$FAKE_KUBECTL_STDERR"
}

# fake_secret KEY VALUE [KEY VALUE ...]
# Writes a Secret manifest whose .data holds the base64 of each VALUE.
fake_secret() {
    local data='{}' key value
    while [[ $# -gt 0 ]]; do
        key="$1" value="$2"
        shift 2
        data="$(jq -c --arg k "$key" --arg v "$value" '. + {($k): ($v | @base64)}' <<< "$data")"
    done
    jq -n --argjson data "$data" \
        '{apiVersion: "v1", kind: "Secret", metadata: {name: "my-secret"}, data: $data}' \
        > "$FAKE_KUBECTL_STDOUT"
}

# decode ARGS...: run the plugin under the isolated PATH.
decode() {
    env PATH="$PLUGIN_PATH" "$PLUGIN" "$@"
}

kubectl_args() {
    cat "$FAKE_KUBECTL_ARGS"
}

@test "--help prints usage and exits 0" {
    run decode --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--namespace"* ]]
}

@test "version prints the plugin version" {
    run decode version
    [ "$status" -eq 0 ]
    [ "$output" = "0.1.0" ]
}

@test "config prints KUBECONFIG" {
    KUBECONFIG=/tmp/some-kubeconfig run decode config
    [ "$status" -eq 0 ]
    [ "$output" = "/tmp/some-kubeconfig" ]
}

@test "fails with a clear error when jq is missing" {
    rm "$TOOLS/jq"
    run decode my-secret
    [ "$status" -eq 1 ]
    [[ "$output" == *"jq is not installed"* ]]
}

@test "missing secret name exits 1 and lists secrets in the namespace" {
    echo "NAME        TYPE     DATA   AGE" > "$FAKE_KUBECTL_STDOUT"
    run decode -n kube-system
    [ "$status" -eq 1 ]
    [[ "$output" == *"Missing name of secret"* ]]
    [[ "$output" == *"NAME        TYPE"* ]]
    [ "$(kubectl_args)" = "$(printf '%s\n' get secrets -n kube-system)" ]
}

@test "passes secret name, namespace and context to kubectl" {
    fake_secret user admin
    run decode my-secret -n prod --context staging
    [ "$status" -eq 0 ]
    [ "$(kubectl_args)" = "$(printf '%s\n' get secret my-secret -o json -n prod --context staging)" ]
}

@test "json output decodes every value" {
    fake_secret user admin password 's3cr3t!'
    run decode my-secret
    [ "$status" -eq 0 ]
    [ "$(jq -r .user <<< "$output")" = "admin" ]
    [ "$(jq -r .password <<< "$output")" = 's3cr3t!' ]
}

@test "json output preserves multi-line values" {
    fake_secret cert $'-----BEGIN CERT-----\nabc\n-----END CERT-----'
    run decode my-secret -o json
    [ "$status" -eq 0 ]
    [ "$(jq -r .cert <<< "$output")" = $'-----BEGIN CERT-----\nabc\n-----END CERT-----' ]
}

@test "yaml output without yq falls back to block scalars" {
    fake_secret user admin cert $'line1\nline2'
    run decode my-secret -o yaml
    [ "$status" -eq 0 ]
    [[ "$output" == *"Install 'yq'"* ]]
    [[ "$output" == *$'user: |\n  admin'* ]]
    [[ "$output" == *$'cert: |\n  line1\n  line2'* ]]
}

@test "table output shows one row per key" {
    fake_secret user admin password hunter2
    run decode my-secret -o table
    [ "$status" -eq 0 ]
    [[ "$output" == *"KEY"*"VALUE"* ]]
    [[ "$output" =~ user[[:space:]]+admin ]]
    [[ "$output" =~ password[[:space:]]+hunter2 ]]
}

@test "rejects an unknown output format" {
    fake_secret user admin
    run decode my-secret -o xml
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid output format 'xml'"* ]]
}

@test "reports kubectl failures and exits 1" {
    echo 'Error from server (NotFound): secrets "nope" not found' > "$FAKE_KUBECTL_STDERR"
    export FAKE_KUBECTL_EXIT=1
    run decode nope
    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to retrieve secret 'nope'"* ]]
    [[ "$output" == *"NotFound"* ]]
}

@test "a secret with no data decodes to nothing in every format" {
    # e.g. `kubectl create secret generic empty`: the API omits .data entirely
    echo '{"apiVersion": "v1", "kind": "Secret", "metadata": {"name": "empty"}, "type": "Opaque"}' \
        > "$FAKE_KUBECTL_STDOUT"

    run decode empty -o json
    [ "$status" -eq 0 ]
    [ "$output" = "{}" ]

    run decode empty -o yaml
    [ "$status" -eq 0 ]
    [[ "$output" != *"error"* ]]

    run decode empty -o table
    [ "$status" -eq 0 ]
    [[ "$output" != *"error"* ]]
    [[ "$output" == *"KEY"*"VALUE"* ]]
}
