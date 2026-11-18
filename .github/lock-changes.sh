#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

old=$1 new=$2
rev() { jq -r --arg n "$2" '.nodes[$n].locked.rev // empty' "$1"; }

echo "Weekly \`nix flake update\`. The build check on this pull request shows whether bootleg's patches"
echo "still apply. Before merging, drop the patches upstream now contains."
echo
echo "Don't push to this branch: the next weekly run resets it. Fix patches on a branch made from"
echo "this one, and merge that instead."
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
echo '### coreboot commits in files bootleg patches'
echo
mapfile -t files < <(sed -n 's|^+++ b/||p' patches/coreboot/* boards/*/patches/* | sort -u)
log=$(git -C /tmp/coreboot.git log --oneline --no-decorate "$a..$b" -- "${files[@]}")
echo "$(git -C /tmp/coreboot.git rev-list --count "$a..$b") commits in total, $(printf '%s' "$log" | grep -c .) of them here:"
echo
echo '```'
echo "${log:-(none)}"
echo '```'
