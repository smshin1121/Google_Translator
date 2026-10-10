# 구조와 구현 결정

## 기본 구성

~~~mermaid
flowchart LR
  P[iPhone 입력과 오디오] --> R[처리 모드와 실행 가능 여부 확인]
  W[Watch 입력과 짧은 요청] --> WC[WatchConnectivity]
  WC --> R
  R --> L[로컬 엔진]
  R --> M[온라인 서비스]
  R --> B[개인 API]
  L --> O[번역 결과와 회의 기록]
  M --> O
  B --> O
  O --> V[iPhone 자막과 음성]
  O --> WC
  WC --> WR[Watch 결과와 알림]
~~~

현재 코드의 실행 경로는 iPhone Apple Translation 텍스트 번역입니다. 모델 처리, 회의 녹음, 서버 호출은 후속 구현입니다.

## 모듈

TranslatorCore는 Foundation만 사용하는 Swift 패키지입니다. 언어, 모드, 번역 요청/응답, 실행 정책, 회의 구간/회의록 데이터, 엔진 계약과 Watch 메시지를 포함합니다. 실제 Apple SDK와 대규모 모델은 이 패키지에 넣지 않습니다.

Apps/iOS는 Apple Translation의 SwiftUI translationTask에 연결합니다. 동일 요청 ID로 시작/완료/오류를 구분하고, 앱이 백그라운드로 이동하면 요청을 종료하고 재요청을 안내합니다. 모델 다운로드와 언어 지원은 Apple 런타임에 의존합니다. iOS 26.4 이상에서는 lowLatency 전략을 명시해 기존 언어팩 기반 경로로 검증하며, 이전 배포 버전은 기존 초기화 API를 사용합니다. [Apple 번역 전략](https://developer.apple.com/documentation/translation/translationsession/strategy)

Apps/watchOS는 입력과 결과를 표시합니다. 현재는 텍스트와 시스템 입력기를 제공하며, 앱 자체의 마이크 녹음은 아직 없습니다. 무거운 추론 라이브러리를 Watch 타깃에 연결하지 않습니다.

## 엔진 확장

| 단계 | 로컬 후보 | 온라인 후보 | 구현 규칙 |
| --- | --- | --- | --- |
| 전사 | SpeechAnalyzer/SpeechTranscriber, WhisperKit | 스트리밍/파일 전사 API | 확정 구간과 시간을 유지 |
| 번역 | Apple Translation, LiteRT-LM Gemma 4 E2B | 제공자별 텍스트 API | 엔진 교체와 개인정보 경로를 분리 |
| 회의록 | Gemma의 제한된 구간 요약 | 구조화 요약 API | 구간별 요약 후 통합, 근거 ID 검증 |
| 음성 출력 | AVSpeechSynthesizer 등 | 필요 시 TTS API | 출력 중 마이크 입력과 중복 번역 조정 |

Gemma를 선택하면 Google 공식 Swift 패키지를 iOS 전용 어댑터로 연결합니다. 현재 LiteRT-LM Swift는 초기 공개 단계이고 watchOS 플랫폼을 선언하지 않습니다. 도입 시 버전과 모델 checksum을 고정하고 엔진 초기화·컨텍스트·캐시 수명·JSON 파싱·취소를 검증합니다. [공식 Swift 안내](https://developers.google.com/edge/litert-lm/swift)

온라인/개인 API 어댑터는 서로 다른 자격 증명 소유자를 갖습니다. 앱 공용 비밀 키는 앱 바이너리에 포함하지 않고 서비스 서버가 보관합니다. 개인 키는 Keychain에 저장하고 Watch 메시지나 로그에 넣지 않습니다. endpoint는 HTTPS 기본, 시간 제한·요청 취소·사용량 안내·응답 크기 제한을 갖추어야 합니다.

## 회의 데이터

녹음은 짧은 파일 청크, 전사는 추가 가능한 확정 구간, 부분 인식은 임시 UI 상태로 분리할 계획입니다. 녹음 청크와 구간을 먼저 저장하고 번역/요약은 나중에 재처리할 수 있도록 합니다. 중단 이후 복구 가능한 인덱스를 함께 기록합니다.

각 TranscriptSegment에 ID, 시작/종료 밀리초, 원문, 확정 여부, 선택적 화자와 번역문을 둡니다. MinuteItem은 sourceSegmentIDs를 포함하고 담당자·기한은 optional입니다. 장시간 회의를 한 번에 모델 컨텍스트에 넣지 않습니다.

원본 오디오 보관 여부·삭제·내보내기는 사용자 설정으로 제공할 계획입니다. 기본 저장 위치는 앱의 보호된 디렉터리이며 회의 음성/전사를 Git에 넣지 않습니다. 현재 앱은 번역 결과를 메모리에서만 표시합니다.

## Watch 연결

즉시 요청은 sendMessageData를 사용하고, 응답은 빠른 accepted/실패 알림 후 updateApplicationContext로 최신 결과를 보냅니다. applicationContext는 최신 상태 하나를 유지하므로 전체 회의록 보관이나 이벤트 큐로 사용하지 않습니다. [Apple 전송 지침](https://developer.apple.com/documentation/watchconnectivity/transferring-data-with-watch-connectivity)

프로토콜 version 1, 요청 UUID, 메시지 상한 8,192바이트, 입력 상한 UTF-8 2,000바이트를 둡니다. 실행 중 iPhone은 최근 128개 ID를 중복 검사합니다. Watch는 요청 ID가 다른 응답을 대기 중 결과에 적용하지 않고 30초 이후 확인 안내를 표시합니다.

현재 Watch 요청은 iPhone 앱이 활성 상태일 때만 처리합니다. iPhone 번역 결과의 최신 짧은 미리보기를 Watch로 보내며, 긴 결과는 iPhone에서 확인합니다. 영구 요청 저장·녹음 파일 전송·확인 응답·재전송은 WAT-02/03 단계에서 구현합니다.

## 백그라운드

일반 백그라운드 상태에서 GPU 추론을 계속 실행할 수 있다고 가정하지 않습니다. iOS 26의 BGContinuedProcessingTask는 사용자가 앱 전면에서 시작한 작업을 계속하도록 지원하며, GPU 사용에는 지원 기기·자원 확인과 entitlement가 추가로 필요합니다. Watch 메시지 수신만으로 이 조건이 충족되지 않습니다. [Apple 장시간 작업 안내](https://developer.apple.com/documentation/BackgroundTasks/performing-long-running-tasks-on-ios-and-ipados)

RoutePolicy는 활성 continued task와 GPU 허용을 입력받는 계약만 제공합니다. 실제 권한·스케줄러 통합은 구현하지 않았습니다. CPU 경로도 OS 실행 시간을 먼저 확보해야 합니다. 오프라인 실패는 대기/전면 실행 안내로 처리합니다.

회의 녹음 구현 시 정상 오디오 사용 목적의 background audio를 추가하고 전화·알람·오디오 경로 변화·권한 취소를 처리합니다. 현재 골격에는 background mode를 선언하지 않습니다.
