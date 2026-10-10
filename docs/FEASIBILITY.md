# iPhone 15 Pro · Watch SE 3 타당성

조사 기준일: 2026-10-11. 아래는 공식 자료에 근거한 개발 판단이며 실기기 측정 결과는 아닙니다.

## iPhone

구현 경로는 있습니다. 원본은 React/Vite UI, Python 음성 서버, LiteRT-LM 번역 서버를 결합한 데스크톱/Raspberry Pi 데모입니다. 모바일에서는 SwiftUI UI, iOS 오디오 수명 주기, 네이티브 추론/번역, 저장·권한 처리를 구성해야 합니다. 원본 프록시는 localhost 대상에 제한되어 있어 온라인 서비스 확장 시 별도 어댑터가 필요합니다. [원본 저장소](https://github.com/google-gemma/gemma-translator), [서버 코드](https://raw.githubusercontent.com/google-gemma/gemma-translator/main/backend/server.py)

Google LiteRT-LM은 공식 Swift API와 iOS CPU/GPU 실행 경로를 제공합니다. 따라서 Gemma 4 E2B를 사용하기 위해 반드시 Core ML로 변환할 필요는 없습니다. 다만 Swift API는 초기 공개 단계이고, iPhone 15 Pro의 최종 속도와 안정성은 직접 확인해야 합니다. [공식 Swift 문서](https://developers.google.com/edge/litert-lm/swift)

공개 모델은 약 2.6GB의 .litertlm 파일이며 런타임 메모리·캐시·추론 컨텍스트는 파일 크기와 별개입니다. 패키지 다운로드 크기를 iPhone의 실제 RAM 사용량으로 단정하지 않습니다. [모델 카드](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm)

초기 텍스트 기능은 Apple Translation으로 빠르게 검증하고 Gemma를 별도 엔진으로 비교합니다. 언어 지원을 런타임으로 조회하고 다운로드한 언어팩으로 오프라인 동작을 확인합니다. [Apple Translation 소개](https://developer.apple.com/videos/play/wwdc2024/10117/)

## 음성과 회의

iOS 26 SpeechAnalyzer/SpeechTranscriber는 긴 전사와 스트리밍 처리를 검토할 수 있는 공식 경로입니다. 한국어 지원은 설치 기기의 supportedLocales/isAvailable로 확인해야 합니다. 이 API는 watchOS를 지원하지 않습니다. WhisperKit은 다른 로컬 전사 후보입니다. [Apple SpeechAnalyzer 소개](https://developer.apple.com/videos/play/wwdc2025/277/), [Argmax Swift 프로젝트](https://github.com/argmaxinc/argmax-oss-swift)

원본 Moonshine의 한국어 모델은 비스트리밍 모델이며 별도의 비상업 라이선스 조건이 있습니다. 원본 설정을 그대로 적용하기 전에 언어·스트리밍·배포 조건을 점검해야 합니다. [Moonshine 모델 목록](https://moonshine-voice.readthedocs.io/en/latest/models/available-models/)

회의록과 회의장 통역은 별도 기능 개발이 필요합니다. 화자 분리, 겹침 발화, 원거리 소음, 장시간 열·배터리, 정확한 타임스탬프는 단순 번역 데모만으로 검증되지 않습니다.

온라인 라이브 번역 후보인 Gemini Live Translate는 Preview이며 음성 중심입니다. 텍스트 번역 어댑터와 따로 다룹니다. Live Transcribe는 10분 세션 제한과 실시간 화자 분리 미지원이 있어 장시간 회의에는 재연결·파일 후처리가 필요합니다. [Live Translate](https://ai.google.dev/gemini-api/docs/live-api/live-translate), [Live Transcribe](https://ai.google.dev/gemini-api/docs/live-api/live-transcribe)

## Watch SE 3

SE 3는 S10을 사용하는 Watch이며 iPhone 연동 앱의 입력·결과·상태·햅틱 화면으로 사용할 수 있습니다. [Apple SE 3 사양](https://support.apple.com/en-us/125094)

| 방식 | 판단 | 범위 |
| --- | --- | --- |
| iPhone 연결, 오프라인 처리 | 우선 구현 | iPhone에 모델/언어팩 준비, Watch는 짧은 요청과 결과 |
| iPhone 연결, 온라인/API | 후속 구현 가능 | 네트워크·인증과 선택 모드를 iPhone에서 처리 |
| Watch 짧은 녹음→iPhone | 후속 구현 가능 | 파일 보존·전송 확인·재연결 필요 |
| Watch 단독 온라인 | 실험 후보 | Watch 네트워크와 배터리, 서비스 인증을 별도 검증 |
| Watch 단독 Gemma 추론 | 현재 구현 경로로 채택하지 않음 | 공식 LiteRT-LM Swift 패키지에 watchOS 플랫폼 없음 |

Watch의 시스템 번역 앱이나 받아쓰기 지원은 서드파티 앱의 동일 API/오프라인 동작을 보장하지 않습니다. WatchConnectivity의 즉시 메시지는 reachable 조건에 의존합니다. 일반 Watch 요청으로 백그라운드 iPhone GPU를 항상 사용할 수 있다고 가정하지 않습니다. [WatchConnectivity](https://developer.apple.com/documentation/watchconnectivity/transferring-data-with-watch-connectivity), [LiteRT-LM Package.swift](https://github.com/google-ai-edge/LiteRT-LM/blob/main/Package.swift)

## 현재 개발 환경

사용자 보고 iOS 26.6.2, Xcode 26.4.0, watchOS 26.0을 기준으로 설정합니다. Apple 요구사항 표에서 Xcode 26.4 계열은 macOS Tahoe 26.2 이상을 요구하므로 Mac의 설치 환경과 기기 연결을 확인합니다. iPhone OS가 SDK보다 새롭다는 이유만으로 실행 불가라고 단정하지 않습니다. [Xcode 요구사항](https://developer.apple.com/xcode/system-requirements)

이번 작업 환경은 Windows이며 Swift와 Xcode가 없어 iOS·Watch 코드의 빌드/서명/성능 검증은 완료하지 않았습니다.
