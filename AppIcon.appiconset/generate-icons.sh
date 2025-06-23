#!/usr/bin/env bash
set -e

# source file
SRC="AppIcon-1024.png"

# declare an array of "filename width height"
icons=(
  "Icon-20@1x.png 20 20"
  "Icon-20@2x.png 40 40"
  "Icon-20@3x.png 60 60"
  "Icon-29@1x.png 29 29"
  "Icon-29@2x.png 58 58"
  "Icon-29@3x.png 87 87"
  "Icon-40@1x.png 40 40"
  "Icon-40@2x.png 80 80"
  "Icon-40@3x.png 120 120"
  "Icon-60@2x.png 120 120"
  "Icon-60@3x.png 180 180"
  "Icon-76@1x.png 76 76"
  "Icon-76@2x.png 152 152"
  "Icon-83.5@2x.png 167 167"
  "Icon-1024@1x.png 1024 1024"
)

for entry in "${icons[@]}"; do
  set -- $entry
  filename=$1; w=$2; h=$3
  echo "Generating $filename ($w×$h)…"
  sips --resampleHeightWidth $h $w "$SRC" --out "$filename" >/dev/null
done

echo "All icons generated in AppIcon.appiconset 🚀"
