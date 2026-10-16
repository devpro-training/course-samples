#!/usr/bin/env bash
# Draws a course's catalog logo: a 256 pixel rounded tile in its family's colour, shading to a darker one of the same hue, with a short monogram in white.
# One colour per family, so the catalog reads as one set and a course's subject shows before its title is read.
#
# Usage:
#   scripts/make_logo.sh <course-dir> <monogram> <family>
#
# Writes <course-dir>/logo.png, which lab.yaml names with `logo: logo.png`.
# The output depends only on the arguments, so running it again on a course reproduces the committed file.
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: scripts/make_logo.sh <course-dir> <monogram> <family>" >&2
  echo "Families: containers kubernetes gitops iac cloud security delivery development linux demo" >&2
  exit 1
fi

course_dir=$1
text=$2
family=$3

case $family in
  containers)  color='#2563EB' ;;
  kubernetes)  color='#4F46E5' ;;
  gitops)      color='#0D9488' ;;
  iac)         color='#7C3AED' ;;
  cloud)       color='#0284C7' ;;
  security)    color='#DC2626' ;;
  delivery)    color='#EA580C' ;;
  development) color='#16A34A' ;;
  linux)       color='#475569' ;;
  demo)        color='#0E7490' ;;
  *) echo "Unknown family $family" >&2; exit 1 ;;
esac

# The font is named by its file rather than by a name ImageMagick resolves, which differs from one machine to the next.
font=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
command -v convert >/dev/null || { echo "ImageMagick's convert is required: sudo apt install imagemagick" >&2; exit 1; }
[ -f "$font" ] || { echo "$font is required: sudo apt install fonts-dejavu-core" >&2; exit 1; }
[ -d "$course_dir" ] || { echo "No course directory $course_dir" >&2; exit 1; }

dark=$(printf '#%02x%02x%02x' $(( 0x${color:1:2} * 72 / 100 )) $(( 0x${color:3:2} * 72 / 100 )) $(( 0x${color:5:2} * 72 / 100 )))
# Longer monograms get a smaller size, so every one keeps the same margin inside the tile.
case ${#text} in 1|2) size=118 ;; 3) size=92 ;; *) size=74 ;; esac

convert -size 256x256 gradient:"$color"-"$dark" \
  \( -size 256x256 xc:black -fill white -draw "roundrectangle 0,0 255,255 56,56" -alpha off \) \
  -alpha off -compose CopyOpacity -composite -compose Over \
  -font "$font" -pointsize "$size" -fill white -gravity center -annotate +0+4 "$text" \
  -strip PNG32:"$course_dir/logo.png"

echo "$course_dir/logo.png"
