#!/usr/bin/env bash
# Runs the generator over a set of real header-only C libraries and
# checks that every generated binding compiles cleanly.
#
# Usage: tests/stress/run.sh [workdir]   (default: build/stress)
set -uo pipefail
cd "$(dirname "$0")/../.."

work="${1:-build/stress-run}"
mkdir -p "$work/headers" "$work/out"

c3c build stress || exit 1

fail=0
while read -r url cargs; do
  case "$url" in ''|\#*) continue ;; esac
  name=$(basename "$url" .h)
  header="$work/headers/$name.h"
  [ -f "$header" ] || curl -sSLf "$url" -o "$header" || { echo "$name: FETCH FAILED"; fail=1; continue; }

  if ! ./build/stress "$header" "$name" "$work/out/$name.c3" $cargs >/dev/null 2>"$work/out/$name.err"; then
    echo "$name: GENERATE FAILED"
    sed -n '1,3p' "$work/out/$name.err"
    fail=1
    continue
  fi

  issues=$(c3c compile --lib std "$work/out/$name.c3" 2>&1 | grep -ciE 'error:|deprecated')
  if [ "$issues" -ne 0 ]; then
    echo "$name: COMPILE FAILED ($issues issues)"
    c3c compile --lib std "$work/out/$name.c3" 2>&1 | grep -iE 'error:|deprecated' | head -3
    fail=1
  else
    echo "$name: ok ($(wc -l < "$work/out/$name.c3" | tr -d ' ') lines)"
  fi
done < tests/stress/headers.txt

exit $fail
