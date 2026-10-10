#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$task_root"
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen is required. Install it with: brew install xcodegen" >&2
  exit 1
fi
python3 scripts/check_scaffold.py
xcodegen generate --spec project.json
python3 scripts/check_scaffold.py --generated
echo "Open MeetingTranslator.xcodeproj in Xcode."
