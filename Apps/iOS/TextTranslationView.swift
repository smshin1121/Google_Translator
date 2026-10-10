import SwiftUI
import Translation
import TranslatorCore

struct TextTranslationView: View {
    @ObservedObject var store: AppStore
    @State private var configuration: TranslationSession.Configuration?
    @State private var configuredRequestID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("번역 방향") {
                    HStack {
                        Picker("원문", selection: $store.source) {
                            ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                        }
                        Button(action: store.swapLanguages) {
                            Image(systemName: "arrow.left.arrow.right")
                        }
                        .accessibilityLabel("언어 바꾸기")
                        Picker("번역", selection: $store.target) {
                            ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                        }
                    }
                    .disabled(store.isBusy)
                }
                Section("원문") {
                    TextEditor(text: $store.input)
                        .frame(minHeight: 150)
                        .accessibilityLabel("번역할 문장")
                        .disabled(store.isBusy)
                    Button(action: store.translateInput) {
                        HStack {
                            if store.isBusy { ProgressView() }
                            Text(store.isBusy ? "번역 중" : "번역하기")
                        }
                    }
                    .disabled(store.isBusy || store.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if !store.output.isEmpty {
                    Section("번역문") {
                        Text(store.output).textSelection(.enabled)
                        ShareLink(item: store.output) { Label("공유", systemImage: "square.and.arrow.up") }
                    }
                }
                if !store.message.isEmpty {
                    Section { Text(store.message).foregroundStyle(.orange) }
                }
                Section {
                    Text("현재 방식: \(store.mode.title)")
                    Text("기기 내에서 번역합니다. 처음 사용하는 언어는 Apple 언어팩 다운로드가 필요하며, 준비 후에는 인터넷 없이 번역할 수 있습니다.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("온라인과 개인 API 번역은 준비 중입니다.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("텍스트 번역")
        }
        .onChange(of: store.activeRequest?.id) { _, _ in configureActiveRequest() }
        .onAppear { configureActiveRequest() }
        .translationTask(configuration) { @MainActor session in
            guard let request = store.activeRequest else { return }
            do {
                let availability = makeAvailability()
                let status = await availability.status(
                    from: Locale.Language(identifier: request.source.rawValue),
                    to: Locale.Language(identifier: request.target.rawValue))
                guard status != .unsupported else {
                    store.fail(requestID: request.id, text: "이 기기에서 해당 언어쌍을 지원하지 않습니다.")
                    return
                }
                let response = try await session.translate(request.text)
                store.finish(requestID: request.id, translatedText: response.targetText)
            } catch is CancellationError {
                store.fail(requestID: request.id, text: "번역이 중단되었습니다. 다시 요청하세요.")
            } catch {
                store.fail(requestID: request.id, text: "번역을 완료하지 못했습니다. 언어팩 설치와 기기 상태를 확인하세요.")
            }
        }
    }

    private func configureActiveRequest() {
        guard let request = store.activeRequest else {
            configuration = nil
            configuredRequestID = nil
            return
        }
        guard configuredRequestID != request.id else { return }
        configuredRequestID = request.id
        configuration = makeConfiguration(request)
    }

    private func makeConfiguration(_ request: TranslationRequest) -> TranslationSession.Configuration {
        let source = Locale.Language(identifier: request.source.rawValue)
        let target = Locale.Language(identifier: request.target.rawValue)
        if #available(iOS 26.4, *) {
            return TranslationSession.Configuration(source: source, target: target, preferredStrategy: .lowLatency)
        }
        return TranslationSession.Configuration(source: source, target: target)
    }

    private func makeAvailability() -> LanguageAvailability {
        if #available(iOS 26.4, *) {
            return LanguageAvailability(preferredStrategy: .lowLatency)
        }
        return LanguageAvailability()
    }
}
