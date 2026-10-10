import SwiftUI
import TranslatorCore

struct SettingsView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var companion: CompanionLink

    var body: some View {
        NavigationStack {
            Form {
                Section("처리 방식") {
                    Picker("모드", selection: $store.mode) {
                        ForEach(ProcessingMode.allCases) { Text($0.title).tag($0) }
                    }
                    .disabled(store.isBusy)
                    Text("오프라인: 기기 안에서 처리\n온라인: 앱 서비스 이용 예정\n개인 API: 직접 지정한 서비스 이용 예정")
                        .font(.footnote)
                    Text("온라인과 개인 API는 아직 연결되지 않았습니다.")
                        .foregroundStyle(.secondary)
                }
                Section("Apple Watch") {
                    Text(companion.connectionText)
                    Text("Watch에서 짧은 문장을 입력하고 iPhone에서 번역한 결과를 확인할 수 있습니다. 현재는 iPhone 앱이 열려 있어야 합니다.")
                        .font(.footnote)
                }
                Section("기록") {
                    Text("현재 버전은 번역문을 자동 저장하지 않습니다. 공유 버튼으로 필요한 결과를 저장하세요.")
                        .font(.footnote)
                }
            }
            .navigationTitle("설정")
        }
    }
}
