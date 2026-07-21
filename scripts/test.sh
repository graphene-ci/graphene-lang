#!/usr/bin/env bash
# Schema tests: every tests/valid/*.pkl must eval; every
# tests/invalid/*.pkl must fail eval. Uses the pinned pkl from bin/.
set -u
cd "$(dirname "$0")/.."
PKL=bin/pkl
fail=0

for f in tests/valid/*.pkl; do
  if out=$("$PKL" eval "$f" 2>&1); then
    echo "PASS  $f"
  else
    echo "FAIL  $f (expected success)"
    echo "$out" | sed 's/^/      /'
    fail=1
  fi
done

for f in tests/invalid/*.pkl; do
  if out=$("$PKL" eval "$f" 2>&1); then
    echo "FAIL  $f (expected eval error, got success)"
    fail=1
  else
    echo "PASS  $f"
  fi
done

exit $fail
