#!/usr/bin/env bash
# Deploy-only start script (Render). The project itself is unchanged:
# stand-in (dev model double, clearly labelled in the UI) + demo console + optional key-backed live console
# + the public gate (the only exposed listener). No secret is ever printed.
set -e
cd "$(dirname "$0")"
[ -f data/results.csv ] || cp report/results.csv data/results.csv

python3 src/standin.py &
sleep 1

# Demo console (no key): replay of recorded real answers + labelled stand-in Relay Lab.
python3 deploy/run_console.py &
sleep 1

# Live console (real model) only when the key is provided via environment. The key is written
# to a private file for the console process only; it is never echoed or logged.
if [ -n "$GROQ_API_KEY" ]; then
  umask 077
  KEYFILE="$(mktemp /tmp/.relay_key.XXXXXX)"
  printf '%s' "$GROQ_API_KEY" > "$KEYFILE"
  export GROQ_KEY_FILE="$KEYFILE"
  unset GROQ_API_KEY
  export LIVE_ENABLED=1
  CONSOLE_PORT=8421 python3 deploy/run_console.py &
  sleep 1
fi

exec python3 deploy/http_gate.py
