#!/bin/zsh
# Rates the Microsoft deals 1-32000 Easy, Medium or Hard by solver effort, and writes
# FreeCell/DealDifficulty.txt. See docs/adr/0001-rate-deals-offline-by-solver-effort.md.
#
# Needs a build of Freecell Solver 6.16.0 (https://fc-solve.shlomifish.org, MIT licence).
# Build it with CMake; the build needs the Python module pysol_cards and the Perl modules
# Template, Path::Tiny and Moo.
# Usage: scripts/rate_deals.sh <fc-solve build folder>
#
# fc-solve examines positions with the "video-editing" preset and 4 free cells, and counts
# them. The deals are sorted by that count (then by number) and split into three equal
# thirds. Character n of the output is E, M or H for deal n, or - for a deal with no
# solution (only #11982).
set -euo pipefail
build=${1:?fc-solve build folder}
source_dir=$(sed -n 's/^CMAKE_HOME_DIRECTORY:INTERNAL=//p' "$build/CMakeCache.txt")
out="$(dirname $0)/../FreeCell/DealDifficulty.txt"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

sed "s#^dir=.*#dir=$source_dir/Presets/presets/#" "$build/Presets/presetrc" > "$work/presetrc"
export FREECELL_SOLVER_PRESETRC="$work/presetrc"

# Each job takes every jobs-th deal, so that the slow deals are spread over the jobs.
jobs=$(sysctl -n hw.ncpu)
for i in $(seq 1 $jobs); do
  "$build/summary-fc-solve" $(seq $i $jobs 32000) -- -l ve -mi 2000000 > "$work/part$i.txt" &
done
wait

# Lines look like "617 = Verdict: Solved ; Iters: 188928 ; Length: 99".
cat "$work"/part*.txt | awk '
  { deal = $1; verdict = $4; iters = $7 }
  verdict == "Solved" { print iters, deal; solved++; next }
  verdict == "Unsolved" { next }
  { print "Deal " deal ": " verdict > "/dev/stderr"; failed = 1 }
  END { if (failed) exit 1 }
' | sort -n -k1,1 -k2,2 | awk '
  { order[NR] = $2 }
  END {
    for (n = 1; n <= 32000; n++) rating[n] = "-"
    for (i = 1; i <= NR; i++) rating[order[i]] = (i <= int(NR / 3)) ? "E" : (i <= int(2 * NR / 3)) ? "M" : "H"
    for (n = 1; n <= 32000; n++) printf "%s", rating[n]
    print ""
  }
' > "$out"

print "Wrote $out: $(tr -cd E < $out | wc -c | tr -d ' ') Easy, $(tr -cd M < $out | wc -c | tr -d ' ') Medium, $(tr -cd H < $out | wc -c | tr -d ' ') Hard, $(tr -cd - < $out | wc -c | tr -d ' ') not rated."
