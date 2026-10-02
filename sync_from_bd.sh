#!/bin/sh
# Refresh the vendored module and its samples from the ButterflyDreaming tree.
#
# Vendoring is deliberate — a developer should be able to open the module, read
# it and break it without a server — but the cost is DRIFT, and this project has
# paid it before: two copies of an earlier module diverged and polish landed in
# only one of them. So the copy is refreshed by one deliberate command, and the
# commit it came from is written down.
#
# COPY-DOWN, NOT A MERGE. Local changes to music_module.html are discarded.
set -e
BD="${BD_REPO:-$HOME/butterflydreaming_graphviewer1}"
SRC="$BD/M_DroneFrac"

[ -f "$SRC/music_module.html" ] || { echo "no module at $SRC — set BD_REPO to your BD checkout" >&2; exit 1; }

cp "$SRC/music_module.html" ./music_module.html
cp "$SRC/make_manifest.py" "$SRC/make_organ_pads.sh" "$SRC/make_sample_pads.py" ./

# The SAMPLES, which are part of the module and easy to forget when vendoring
# an .html file. Forgetting them is silent: Tone.loaded() never resolves, so
# Play simply stays disabled while every control that needs only the script
# text lights up normally. That reads as a broken library and is a missing
# directory. Only the .mp3s and the records — never the 20 MB of raw .wav
# masters, which nothing serves.
mkdir -p ./sources
cp "$SRC"/sources/*.mp3 ./sources/
cp "$SRC"/sources/manifest.json "$SRC"/sources/SOURCES.md ./sources/

{
  echo "music_module.html and sources/ were copied from ButterflyDreaming:"
  echo "  source : M_DroneFrac/"
  echo "  samples: $(ls -1 ./sources/*.mp3 | wc -l | tr -d ' ') .mp3 files, $(du -ch ./sources/*.mp3 | tail -1 | cut -f1)"
  echo "  commit : $(git -C "$BD" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  echo "  dated  : $(git -C "$BD" log -1 --format=%cd --date=short 2>/dev/null || echo unknown)"
  echo "  taken  : $(date -u +%Y-%m-%dT%H:%MZ)"
  echo
  echo "Refresh with ./sync_from_bd.sh — a copy-down, not a merge."
  echo "Licence and provenance for every sample: sources/SOURCES.md"
} > MODULE_SOURCE.txt

echo "module refreshed:"
sed 's/^/  /' MODULE_SOURCE.txt
