#!/usr/bin/env bash
set -euo pipefail

cmd=(bare ./node_modules/.bin/blind-peer-bare)

control_args=(
  --control-socket /home/blind-peer/.blind-peer.sock
)

# Subcommands only accept their own flags, so pass just the control socket, e.g. for HEALTHCHECK:
# docker-entrypoint.sh readiness-probe
if [[ "${1:-}" == "readiness-probe" ]]; then
  shift
  exec "${cmd[@]}" readiness-probe "${control_args[@]}" "$@"
fi

args=(
  --storage /home/blind-peer/store
  "${control_args[@]}"
)

if [[ -n "${BLIND_PEER_ARGS_FILE:-}" ]]; then
  if [[ ! -f "$BLIND_PEER_ARGS_FILE" ]]; then
    echo "BLIND_PEER_ARGS_FILE not found: ${BLIND_PEER_ARGS_FILE}" >&2
    exit 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -n "$line" ]] || continue

    read -r -a line_args <<< "$line"
    args+=("${line_args[@]}")
  done < "$BLIND_PEER_ARGS_FILE"
fi

exec "${cmd[@]}" "${args[@]}" "$@"
