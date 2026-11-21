#!/bin/bash
# Strip the com.apple.quarantine xattr from the project (files synced via iCloud
# can arrive quarantined). Runs against this script's own directory, no sudo needed.
cd "$(dirname "$0")" || exit 1
# Skip .git: its object files are read-only, so xattr can't touch them (and they
# don't need de-quarantining). Redirect stderr to hide the harmless "no such
# xattr" messages on files that were never quarantined.
find . -path ./.git -prune -o -print0 | xargs -0 xattr -d com.apple.quarantine 2>/dev/null
exit 0
