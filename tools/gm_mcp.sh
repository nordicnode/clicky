#!/usr/bin/env bash
# Launch the GameMaker resource MCP against THIS checkout, not whichever
# project the client last remembered. The old desktop entry pointed at
# /home/mikey/Desktop/dev/gmsgame/GameMakerProject/GameMakerProject.yyp, so the
# server opened the wrong .yyp and could not see Clicky's resources.
#
# The version is pinned: `@latest` re-resolves against the npm registry on
# every launch, which is slow and fails offline (the client then reports
# "Connection closed"). 2.4.1 is the installed, cached build.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project="$root/Clicky/Clicky.yyp"

if [ ! -f "$project" ]; then
    echo "gm_mcp: no GameMaker project at $project" >&2
    exit 1
fi

cd "$root"
exec npx -y @gamemaker/gm-cli@2.4.1 resourcetool mcp "$project" "$@"
