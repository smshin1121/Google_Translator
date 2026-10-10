# Mac mini 개발 시작

## 필요한 환경

- 전체 Xcode 앱과 iOS/watchOS SDK. 현재 프로젝트 최소 배포 버전은 26.0입니다.
- Xcode 26.4 계열의 macOS 요구사항을 확인합니다. [Apple 시스템 요구사항](https://developer.apple.com/xcode/system-requirements)
- XcodeGen 2.46.0 이상. [공식 XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Python 3와 Git. Python 스크립트는 추가 패키지를 요구하지 않습니다.

## 준비

~~~bash
git clone https://github.com/smshin1121/Google_Translator.git
cd Google_Translator
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
xcrun --sdk watchos --show-sdk-version
brew install xcodegen
cp Config/Local.xcconfig.example Config/Local.xcconfig
~~~

첫 실행에서는 Xcode를 열어 자체 초기 설정과 라이선스 안내를 완료해야 할 수 있습니다. Command Line Tools만 선택되어 있다면 Xcode → Settings → Locations에서 전체 Xcode를 선택합니다.

Config/Local.xcconfig에 DEVELOPMENT_TEAM과 본인에게 고유한 IPHONE_BUNDLE_IDENTIFIER를 설정합니다. WATCH_BUNDLE_IDENTIFIER는 iPhone ID 아래 .watch로 유지합니다. 이 로컬 파일은 Git에서 제외됩니다. Xcode UI에서만 번들 ID를 바꾸면 다음 생성 때 덮어써질 수 있으므로 설정 파일을 사용합니다.

## 프로젝트 생성과 빌드

~~~bash
bash scripts/generate_project.sh
open MeetingTranslator.xcodeproj
bash scripts/check_mac.sh
~~~

project.json이 프로젝트의 원본이고 .xcodeproj는 생성 결과라 Git에서 제외됩니다. Swift 버전 설정은 5 모드로 두어 초기 WatchConnectivity delegate 통합의 동시성 전환 범위를 제한합니다. 이후 Swift 6 엄격 모드 검증을 따로 수행합니다.

현재 Watch는 단일 application 타깃으로 구성합니다. XcodeGen의 현대 Watch 포함 경로 관련 이슈를 고려해 dependency copy를 plugins로 지정했습니다. 생성 스크립트는 Watch 앱만 포함하는 copy phase가 PlugIns(13), 빈 subpath인지 검사합니다. 이는 프로젝트 형식 검사이며 실제 Xcode SDK 검증을 대신하지 않습니다. [XcodeGen dependency copy 명세](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md#dependency), [관련 수정 제안](https://github.com/yonaskolb/XcodeGen/pull/1614)

## iPhone · Watch 설치

1. Mac과 iPhone을 연결하고 필요한 신뢰·개발자 모드 안내를 기기에서 직접 처리합니다.
2. MeetingTranslator scheme과 iPhone 15 Pro를 선택하고 개발 팀으로 서명해 실행합니다.
3. iPhone 앱에서 한국어↔영어를 번역해 Apple 언어팩 설치 안내를 진행합니다.
4. iPhone과 페어링된 Watch SE 3를 Xcode에서 확인하고 MeetingTranslatorWatch scheme으로 실행합니다.
5. 두 기기에서 앱을 열고 Watch에서 짧은 문장을 입력합니다. iPhone에서 번역 후 Watch에 결과가 도착하는지 확인합니다.
6. iPhone 잠금/백그라운드에서는 현재 요청이 전면 실행 안내로 종료되는지 확인합니다.

iPhone OS/Xcode 연결 오류가 있으면 실제 오류와 Apple 지원 표를 확인한 뒤 Xcode 갱신 여부를 정합니다. 사용자 보고 OS 버전은 기기 설정에서 다시 확인합니다.

## Swift 패키지만 확인

~~~bash
swift test --package-path Packages/TranslatorCore
~~~

처리 경로와 Watch 프로토콜 테스트는 모델 다운로드 없이 실행됩니다. Apple Translation의 실제 모델은 iPhone에서 검증해야 합니다.

## 온라인과 Gemma

현재 비밀 키와 대규모 모델 다운로드는 필요하지 않습니다. 다음 단계에서 Keychain과 서비스 어댑터를 구현한 후 개인 API를 설정합니다. Gemma 모델은 앱의 Application Support 디렉터리에 다운로드·검증·삭제하도록 구현할 계획입니다.

## GitHub Actions

Actions → macOS build check → Run workflow로 수동 실행합니다. 작업은 Swift 패키지 테스트와 두 앱의 시뮬레이터 빌드를 수행합니다. 모델 실행, 기기 페어링, 실기기 품질 평가는 포함하지 않습니다. 계정의 Actions 사용 한도 내에서 실행합니다.
