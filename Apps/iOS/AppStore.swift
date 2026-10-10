import Combine
import Foundation
import UIKit
import TranslatorCore

@MainActor
final class AppStore: ObservableObject {
    enum Tab: Hashable { case text, conversation, meeting, settings }
    @Published var selectedTab: Tab = .text
    @Published var mode: ProcessingMode = .offline
    @Published var source: AppLanguage = .korean
    @Published var target: AppLanguage = .english
    @Published var input = ""
    @Published private(set) var activeRequest: TranslationRequest?
    @Published private(set) var output = ""
    @Published private(set) var message = ""
    let companion = CompanionLink()
    private var ledger = RequestLedger()

    var isBusy: Bool { activeRequest != nil }

    init() {
        companion.onRequest = { [weak self] request in
            self?.acceptWatchRequest(request)
                ?? WatchResponse(requestID: request.translation.id, status: .unavailable,
                                 text: "iPhone 앱을 열어 주세요.")
        }
    }

    func translateInput() {
        let request = TranslationRequest(text: input, source: source, target: target)
        do { try start(request) }
        catch { message = error.localizedDescription }
    }

    func swapLanguages() {
        guard !isBusy else { return }
        (source, target) = (target, source)
    }

    func finish(requestID: UUID, translatedText: String) {
        guard activeRequest?.id == requestID else { return }
        output = translatedText
        message = ""
        activeRequest = nil
        companion.publish(WatchResponse(requestID: requestID, status: .completed,
                                        text: watchPreview(translatedText)))
    }

    func fail(requestID: UUID, text: String, status: WatchResponseStatus = .unavailable) {
        guard activeRequest?.id == requestID else { return }
        message = text
        activeRequest = nil
        companion.publish(WatchResponse(requestID: requestID, status: status, text: watchPreview(text)))
    }

    func enteredBackground() {
        guard let request = activeRequest else { return }
        fail(requestID: request.id, text: "앱을 다시 열고 번역을 요청하세요.", status: .needsForeground)
    }

    private func start(_ request: TranslationRequest) throws {
        guard !isBusy else { return }
        try request.validate()
        guard mode == .offline else { throw TranslationFailure.engineNotConfigured }
        try RoutePolicy.validate(mode: mode, provider: .appleTranslation,
            context: ExecutionContext(isForeground: UIApplication.shared.applicationState == .active,
                                      engineConfigured: true))
        output = ""
        message = ""
        activeRequest = request
        selectedTab = .text
    }

    private func acceptWatchRequest(_ request: WatchRequest) -> WatchResponse {
        let id = request.translation.id
        guard UIApplication.shared.applicationState == .active else {
            return WatchResponse(requestID: id, status: .needsForeground,
                                 text: "iPhone에서 앱을 열고 다시 요청하세요.")
        }
        guard !isBusy else {
            return WatchResponse(requestID: id, status: .busy, text: "현재 번역 중입니다. 잠시 후 다시 요청하세요.")
        }
        do {
            try request.translation.validate()
            guard mode == .offline else { throw TranslationFailure.engineNotConfigured }
            guard ledger.insert(id) else {
                return WatchResponse(requestID: id, status: .rejected, text: "이미 처리한 요청입니다. 새로 요청하세요.")
            }
            try start(request.translation)
            source = request.translation.source
            target = request.translation.target
            input = request.translation.text
            return WatchResponse(requestID: id, status: .accepted, text: "iPhone에서 번역 중")
        } catch {
            return WatchResponse(requestID: id, status: .unavailable, text: error.localizedDescription)
        }
    }

    /// A bounded preview keeps WatchConnectivity messages small even with JSON escaping.
    private func watchPreview(_ text: String) -> String {
        var preview = ""
        var bytes = 0
        for character in text {
            let next = String(character)
            guard bytes + next.utf8.count <= 1_000 else { break }
            preview += next
            bytes += next.utf8.count
        }
        return preview == text ? preview : preview + "… (전체 결과는 iPhone에서 확인)"
    }
}
