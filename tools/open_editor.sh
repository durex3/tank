#!/bin/sh
# Start from the actual project root, independent of the terminal/IDE launch cwd.
set -eu
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$PROJECT_ROOT"
GODOT_EXECUTABLE=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}
if [ ! -x "$GODOT_EXECUTABLE" ]; then
    printf '%s\n' 'Godot executable missing; set GODOT_BIN to your Godot 4.7.2 executable.' >&2
    exit 1
fi
exec "$GODOT_EXECUTABLE" --editor --path "$PROJECT_ROOT" "$@"
