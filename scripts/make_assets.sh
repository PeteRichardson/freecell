#!/bin/zsh
# Turns the CC0 card SVG files (English pattern, by Dmitry Fomin, Wikimedia Commons)
# into PNG image sets in the asset catalog. Needs rsvg-convert (brew install librsvg).
# Usage: scripts/make_assets.sh <folder with the 52 SVG files>
set -euo pipefail
src=${1:?folder with card SVG files}
cards="$(dirname $0)/../FreeCell/Assets.xcassets/Cards"
mkdir -p "$cards"
print '{"info":{"author":"xcode","version":1}}' > "$cards/Contents.json"
for svg in "$src"/*.svg; do
  name=$(basename "$svg" .svg)
  set="$cards/$name.imageset"
  mkdir -p "$set"
  rsvg-convert -w 450 -h 675 -o "$set/$name.png" "$svg"
  print "{\"images\":[{\"filename\":\"$name.png\",\"idiom\":\"universal\"}],\"info\":{\"author\":\"xcode\",\"version\":1}}" > "$set/Contents.json"
done
print "Made $(ls -d $cards/*.imageset | wc -l | tr -d ' ') card image sets."
