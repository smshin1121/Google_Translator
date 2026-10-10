# Google Translator — iPhone · Apple Watch

iPhone 15 Pro와 Apple Watch SE 3를 위한 한국어↔영어 번역·회의 도구의 개발 시작점입니다.

저장소: https://github.com/smshin1121/Google_Translator

**현재 단계는 구현 준비 및 초기 코드 작성입니다. Swift/Xcode 빌드와 실기기 동작은 아직 검증하지 않았습니다.**

## 준비한 내용

| 항목 | 현재 상태 |
| --- | --- |
| iPhone 텍스트 번역 | SwiftUI + Apple Translation 연결 코드 작성 |
| 오프라인 정책 | 외부 서버 경로 차단 코드와 Swift 테스트 작성 |
| Watch 동반 앱 | 짧은 문장 요청, 결과 표시, 연결·오류 상태 코드 작성 |
| 온라인 / 개인 API | 모드·엔진 계약 정의, 실제 서비스 연결 예정 |
| Gemma 4 E2B | iOS 실행 경로 조사 완료, 모델 통합·성능 측정 예정 |
| 음성 번역 / 회의록 / 회의장 통역 | 요구사항·설계·검증 기준 준비 |
| 자동 확인 | Python 구조 검사 실행 가능, macOS 빌드 스크립트와 수동 CI 준비 |

오프라인 텍스트 번역은 Apple 언어팩을 먼저 다운로드해야 합니다. Watch 요청은 현재 iPhone 앱이 화면에 열려 있어야 처리합니다. Watch의 시스템 받아쓰기는 별도 기능으로, 오프라인 동작을 보장하지 않습니다.

원본 [google-gemma/gemma-translator](https://github.com/google-gemma/gemma-translator)의 흐름을 참고했으며, 모바일용 네이티브 코드는 별도로 작성했습니다. 원본의 Gemma 4 E2B와 TranslateGemma는 구분합니다.

## Mac에서 시작

Xcode 전체 앱과 XcodeGen이 필요합니다. 자세한 절차는 [MAC_SETUP.md](docs/MAC_SETUP.md)에 있습니다.

~~~bash
git clone https://github.com/smshin1121/Google_Translator.git
cd Google_Translator
brew install xcodegen
cp Config/Local.xcconfig.example Config/Local.xcconfig
bash scripts/generate_project.sh
open MeetingTranslator.xcodeproj
~~~

Config/Local.xcconfig에 개발 팀과 본인에게 고유한 번들 ID를 설정한 뒤 iPhone에 설치합니다. 모델 파일이나 API 키를 저장소에 넣지 않습니다.

~~~bash
python3 scripts/check_scaffold.py
bash scripts/check_mac.sh
~~~

두 번째 명령은 macOS에서만 실행할 수 있습니다. Swift 패키지 테스트와 iOS·watchOS 시뮬레이터 빌드를 검사합니다. 번역 모델과 연결 동작은 [실기기 검증](docs/DEVICE_VALIDATION.md)이 별도로 필요합니다.

GitHub Actions는 workflow_dispatch로 수동 실행하며, 이 저장소에 push하는 것만으로 macOS 작업을 실행하지 않습니다.

## 구조

~~~text
Apps/iOS/                  iPhone 화면과 Apple Translation 연결
Apps/watchOS/              Watch 화면
Apps/Shared/               WatchConnectivity 연결
Packages/TranslatorCore/   처리 정책·데이터·엔진 계약·프로토콜·테스트
Config/                    공통 설정과 로컬 서명 설정 예시
docs/                      타당성·요구사항·설계·개발 순서·실기기 검증
eval/                      한국어↔영어 평가 문장
scripts/                   구조 확인·Mac 프로젝트 생성·빌드 확인
~~~

- [타당성 및 Watch 검토](docs/FEASIBILITY.md)
- [요구사항](docs/REQUIREMENTS.md)
- [구조와 데이터 흐름](docs/ARCHITECTURE.md)
- [개발 순서](docs/ROADMAP.md)
- [개발 준비 상태](docs/STATUS.md)
- [조사 출처와 라이선스 점검](docs/SOURCES.md)
