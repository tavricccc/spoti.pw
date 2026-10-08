#!/bin/sh
# No simulator needed: compile the geometry used by the redesigned headers.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
binary=$(mktemp "${TMPDIR:-/tmp}/spoti-layout.XXXXXX")
trap 'rm -f "$binary"' EXIT HUP INT TERM
"${CC:-cc}" -std=c11 -Wall -Wextra -Werror "$root/harness/layout/geometry.c" -lm -o "$binary"
"$binary"
