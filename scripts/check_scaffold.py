#!/usr/bin/env python3
"""Dependency-free structure checks. Does not compile Swift or emulate a device."""
import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent

def require(condition, message):
    if not condition:
        raise ValueError(message)

def check():
    spec = json.loads((ROOT / "project.json").read_text(encoding="utf-8"))
    phone = spec["targets"]["MeetingTranslator"]
    watch = spec["targets"]["MeetingTranslatorWatch"]
    require(phone["platform"] == "iOS", "Phone platform mismatch")
    require(watch["platform"] == "watchOS", "Watch platform mismatch")
    require(watch["type"] == "application", "Watch must use the modern single target")
    require(phone["deploymentTarget"] == watch["deploymentTarget"] == "26.0", "Deployment target mismatch")
    require(watch["info"]["properties"]["WKApplication"] is True, "WKApplication is required")
    require(watch["info"]["properties"]["WKCompanionAppBundleIdentifier"] == "$(IPHONE_BUNDLE_IDENTIFIER)",
            "Companion bundle identifier mismatch")
    embed = next(d for d in phone["dependencies"] if d.get("target") == "MeetingTranslatorWatch")
    require(embed["embed"] and not embed["link"], "Invalid Watch dependency")
    require(embed["copy"]["destination"] == "plugins", "Watch embedding destination mismatch")
    for target in spec["targets"].values():
        for source in target["sources"]:
            require((ROOT / source["path"]).is_dir(), "Source directory missing: " + source["path"])
        for dependency in target["dependencies"]:
            if "package" in dependency:
                require(dependency["package"] == "TranslatorCore", "Unexpected heavy app dependency")
    require("UIBackgroundModes" not in phone["info"]["properties"], "Background modes require actual recording implementation")
    for package in spec["packages"].values():
        require((ROOT / package["path"] / "Package.swift").is_file(), "Package manifest missing")
    for filename in [
        "README.md", "docs/REQUIREMENTS.md", "docs/ARCHITECTURE.md", "docs/ROADMAP.md",
        "docs/MAC_SETUP.md", "docs/DEVICE_VALIDATION.md", "docs/FEASIBILITY.md",
        "docs/SOURCES.md", "Config/Base.xcconfig",
    ]:
        require((ROOT / filename).is_file(), "Required file missing: " + filename)
    ignored = (ROOT / ".gitignore").read_text(encoding="utf-8")
    for sensitive in ["Config/Local.xcconfig", "*.litertlm", "recordings/", "transcripts/", ".env"]:
        require(sensitive in ignored, "Missing ignore rule: " + sensitive)
    tests = list((ROOT / "Packages/TranslatorCore/Tests").rglob("*.swift"))
    require(len(tests) >= 2, "Core tests missing")
    evaluation = json.loads((ROOT / "eval/ko-en-cases.json").read_text(encoding="utf-8"))
    ids = [case["id"] for case in evaluation["cases"]]
    require(len(ids) >= 16 and len(ids) == len(set(ids)), "Evaluation IDs/count invalid")
    require({case["source"] for case in evaluation["cases"]} == {"ko", "en"}, "Both directions required")
    print("PASS: project structure, platform isolation, Watch embedding spec, ignore rules, evaluation fixtures")

def check_generated():
    pbx = ROOT / "MeetingTranslator.xcodeproj/project.pbxproj"
    require(pbx.is_file(), "Generate the Xcode project first")
    content = pbx.read_text(encoding="utf-8")
    phases = re.findall(r"[A-F0-9]{24}\s*/\*[^\n]*?\*/\s*=\s*\{[^{}]*isa = PBXCopyFilesBuildPhase;[^{}]*\};",
                        content, re.DOTALL)
    watch_phases = [p for p in phases if "MeetingTranslatorWatch.app" in p]
    require(len(watch_phases) == 1, "Expected exactly one phase embedding the Watch app")
    require("dstSubfolderSpec = 13;" in watch_phases[0], "Modern Watch app must embed in PlugIns")
    require(re.search(r'dstPath = ""\s*;', watch_phases[0]) is not None, "Unexpected Watch embed subpath")
    print("PASS: generated Watch copy phase (PlugIns, empty subpath)")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated", action="store_true")
    arguments = parser.parse_args()
    try:
        check()
        if arguments.generated:
            check_generated()
    except (ValueError, OSError, KeyError, StopIteration, json.JSONDecodeError) as error:
        print("FAIL:", error, file=sys.stderr)
        sys.exit(1)
