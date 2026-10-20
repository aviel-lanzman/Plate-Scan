#!/usr/bin/env bash
# Rebuilds the product demo video: video/remotion/out/platescan-demo.mp4
# (1080x1350, 30 fps, no audio). See video/README.md.
# Needs Flutter, Node 22+, ffmpeg and Google Chrome.
set -euo pipefail
cd "$(dirname "$0")"
CHROME=${CHROME:-/usr/bin/google-chrome}
HF="npx -y hyperframes@0.8.181"
export HYPERFRAMES_NO_TELEMETRY=1 DO_NOT_TRACK=1 HYPERFRAMES_SKIP_SKILLS=1

# Shared inputs: the Heebo font and the app icon.
mkdir -p remotion/public/fonts remotion/public/photos remotion/public/hf hyperframes/assets/fonts
cp assets/fonts/Heebo-*.ttf remotion/public/fonts/
cp assets/fonts/Heebo-*.ttf hyperframes/assets/fonts/
cp ../assets/icon/icon.png remotion/public/icon.png
cp ../assets/icon/icon.png hyperframes/assets/icon.png

# 1. The synthetic car photos that stand in for scan photos (Remotion stills).
(cd remotion && npm ci --silent)
for i in 1 2 3; do
  (cd remotion && npx remotion still src/index.ts CarPhoto "public/photos/car-$i.jpg" \
    --frame=$(((i - 1) * 20)) --browser-executable="$CHROME" --log=error)
done

# 2. The real result screen with demo data, rendered by a Flutter widget test.
(cd .. && flutter test video/flutter_shots/screens_test.dart)

# 3. Intro and outro (HyperFrames).
(cd hyperframes && $HF render -o renders/intro.mp4 -f 30 -q delivery --quiet &&
  $HF render -c compositions/outro.html -o renders/outro.mp4 -f 30 -q delivery --quiet)
cp hyperframes/renders/intro.mp4 hyperframes/renders/outro.mp4 remotion/public/hf/

# 4. The whole video (Remotion).
(cd remotion && npx remotion render src/index.ts PlateScanDemo out/platescan-demo.mp4 \
  --codec=h264 --crf=18 --browser-executable="$CHROME" --log=error)
echo "Done: video/remotion/out/platescan-demo.mp4"
