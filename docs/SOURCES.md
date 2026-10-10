# 조사 출처와 라이선스 확인

조회 기준일: 2026-10-11. 공식 문서와 저장소를 우선했습니다. 릴리스·모델·라이선스·서비스 제한은 실제 도입 시 선택한 버전으로 다시 확인합니다.

| 출처 | 확인 목적 |
| --- | --- |
| [google-gemma/gemma-translator](https://github.com/google-gemma/gemma-translator) | 원본 구조, Gemma 4 E2B, 음성 흐름 |
| [원본 backend/server.py](https://raw.githubusercontent.com/google-gemma/gemma-translator/main/backend/server.py) | Python 서버, 프록시 허용 대상 |
| [원본 download_model.sh](https://raw.githubusercontent.com/google-gemma/gemma-translator/main/download_model.sh) | 모델 종류와 다운로드 준비 |
| [LiteRT-LM Swift](https://developers.google.com/edge/litert-lm/swift) | Swift iOS API와 CPU/GPU 실행 경로 |
| [LiteRT-LM Package.swift](https://github.com/google-ai-edge/LiteRT-LM/blob/main/Package.swift) | Swift 플랫폼 지원, watchOS 미선언 |
| [Gemma 4 E2B LiteRT 모델 카드](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm) | 모델 크기와 런타임 설명 |
| [Apple Translation WWDC24](https://developer.apple.com/videos/play/wwdc2024/10117/) | 로컬 번역, 언어 지원과 다운로드 |
| [TranslationSession.Configuration](https://developer.apple.com/documentation/translation/translationsession/configuration) | 번역 작업 시작과 재실행 |
| [LanguageAvailability](https://developer.apple.com/documentation/translation/languageavailability) | 언어쌍 지원·설치 상태 |
| [SpeechAnalyzer WWDC25](https://developer.apple.com/videos/play/wwdc2025/277/) | 긴 스트리밍 전사, watchOS 제외 |
| [Argmax Swift](https://github.com/argmaxinc/argmax-oss-swift) | WhisperKit/SpeakerKit 로컬 후보 |
| [Moonshine 모델 목록](https://moonshine-voice.readthedocs.io/en/latest/models/available-models/) | 한국어 스트리밍 여부·모델별 라이선스 |
| [Gemini Live Translate](https://ai.google.dev/gemini-api/docs/live-api/live-translate) | 음성 번역 Preview 후보 |
| [Gemini Live Transcribe](https://ai.google.dev/gemini-api/docs/live-api/live-transcribe) | 세션 제한과 화자 분리 제한 |
| [Gemini Transcribe](https://ai.google.dev/gemini-api/docs/transcribe) | 파일 전사·후처리 후보 |
| [Watch SE 3 사양](https://support.apple.com/en-us/125094) | Watch 모델과 하드웨어 |
| [WatchConnectivity](https://developer.apple.com/documentation/watchconnectivity/transferring-data-with-watch-connectivity) | 즉시 요청/최신 상태/파일 전송 |
| [Apple 장시간 작업](https://developer.apple.com/documentation/BackgroundTasks/performing-long-running-tasks-on-ios-and-ipados) | iOS 26 작업과 조건부 GPU 지원 |
| [Xcode 요구사항](https://developer.apple.com/xcode/system-requirements) | Mac·SDK·기기 연결 조건 |
| [XcodeGen Project Spec](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md) | JSON 프로젝트 생성과 copy 규칙 |
| [XcodeGen Watch 수정 제안](https://github.com/yonaskolb/XcodeGen/pull/1614) | 현대 Watch 포함 경로 문제 추적 |
| [GitHub macOS runner 이미지](https://github.com/actions/runner-images) | 수동 macOS CI 실행 환경 |

## 라이선스와 도입 경계

현재 프로젝트는 별도로 작성한 시작 코드이며 원본 코드·모델 파일·음성 데이터를 가져오지 않았습니다. 저장소에 프로젝트 자체의 공개 라이선스를 지정하는 일은 배포 범위 결정 시 진행합니다.

라이브러리 코드의 라이선스와 모델 가중치의 이용 조건은 별개로 확인합니다. LiteRT-LM 도입과 Gemma 모델 재배포에는 각각의 해당 조건을 확인하고 필요한 고지/모델 이용 약관을 포함해야 합니다. 원본 다운로드 스크립트 실행을 앱의 모델 재배포 권한으로 해석하지 않습니다.

Moonshine 한국어 모델의 비상업 조건, WhisperKit/SpeakerKit 코드와 실제 모델의 조건, 온라인 서비스의 저장·요금·개인정보 정책은 선택한 엔진별 도입 확인 항목입니다. 현재는 해당 모델을 다운로드하거나 포함하지 않았습니다.
