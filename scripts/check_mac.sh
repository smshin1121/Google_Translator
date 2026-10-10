#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$task_root"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Run this build check on macOS with full Xcode installed." >&2
  exit 1
fi
xcodebuild -version
python3 scripts/check_scaffold.py
swift test --package-path Packages/TranslatorCore
bash scripts/generate_project.sh
xcodebuild -project MeetingTranslator.xcodeproj -scheme MeetingTranslator \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/iOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -project MeetingTranslator.xcodeproj -scheme MeetingTranslatorWatch \
  -configuration Debug -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath build/watchOS CODE_SIGNING_ALLOWED=NO build
