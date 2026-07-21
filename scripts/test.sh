#!/usr/bin/env bash
# Schema tests: every tests/valid/*.k must evaluate; every
# tests/invalid/*.k must fail eval. Uses the pinned kcl from bin/.
set -u
cd "$(dirname "$0")/.."
KCL=bin/kcl
fail=0

for f in tests/valid/*.k; do
  if out=$("$KCL" run "$f" 2>&1); then
    echo "PASS  $f"
  else
    echo "FAIL  $f (expected success)"
    echo "$out" | sed 's/^/      /' | head -20
    fail=1
  fi
done

for f in tests/invalid/*.k; do
  if out=$("$KCL" run "$f" 2>&1); then
    echo "FAIL  $f (expected eval error, got success)"
    fail=1
  else
    echo "PASS  $f"
  fi
done

exit $fail
