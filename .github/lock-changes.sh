#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Writes the pull request body for a flake.lock update: every input that moved, with a link to its
# commits, and the coreboot commits that touch code bootleg patches or depends on.
# Usage: lock-changes.sh <old flake.lock> <new flake.lock>
set -euo pipefail

old=$1 new=$2
rev() { jq -r --arg n "$2" '.nodes[$n].locked.rev // empty' "$1"; }

echo "Weekly \`nix flake update\`. The build check on this pull request shows whether bootleg's patches"
echo "still apply. Before merging, drop the patches upstream now contains."
echo
echo '| Input | From | To | Commits |'
echo '|---|---|---|---|'
for n in $(jq -r '.nodes.root.inputs | keys[]' "$new"); do
  a=$(rev "$old" "$n") b=$(rev "$new" "$n")
  [ "$a" = "$b" ] && continue
  url=$(jq -r --arg n "$n" '.nodes[$n].locked | .url // "https://github.com/\(.owner)/\(.repo)"' "$new")
  case $url in
    https://review.coreboot.org/*) link=https://review.coreboot.org/plugins/gitiles/${url#https://review.coreboot.org/}/+log/$a..$b ;;
    *) link=$url/compare/$a...$b ;;
  esac
  echo "| $n | \`${a:0:12}\` | \`${b:0:12}\` | [log]($link) |"
done

a=$(rev "$old" coreboot) b=$(rev "$new" coreboot)
[ "$a" = "$b" ] && exit 0
git clone -q --bare --filter=blob:none https://review.coreboot.org/coreboot /tmp/coreboot.git
echo
echo '### coreboot commits in code bootleg touches'
echo
log=$(git -C /tmp/coreboot.git log --oneline --no-decorate "$a..$b" -- \
  src/soc/intel/skylake src/mainboard/dell src/drivers/efi src/security/tpm payloads/external/edk2)
echo "$(git -C /tmp/coreboot.git rev-list --count "$a..$b") commits in total, $(printf '%s' "$log" | grep -c .) of them here:"
echo
echo '```'
echo "${log:-(none)}"
echo '```'
