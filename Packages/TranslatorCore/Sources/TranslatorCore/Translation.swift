import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Sendable, Identifiable {
    case korean = "ko"
    case english = "en"
    public var id: String { rawValue }
    public var title: String { self == .korean ? "한국어" : "English" }
}

public enum ProcessingMode: String, CaseIterable, Codable, Sendable, Identifiable {
    case offline
    case online
    case personalAPI
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .offline: return "오프라인"
        case .online: return "온라인"
        case .personalAPI: return "개인 API"
        }
    }
}

public struct TranslationRequest: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let text: String
    public let source: AppLanguage
    public let target: AppLanguage

    public init(id: UUID = UUID(), text: String, source: AppLanguage, target: AppLanguage) {
        self.id = id
        self.text = text
        self.source = source
        self.target = target
    }

    public func validate() throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationFailure.emptyText
        }
        guard source != target else { throw TranslationFailure.sameLanguage }
        guard text.count <= 8_000 else { throw TranslationFailure.textTooLong }
    }
}

public struct TranslationResult: Codable, Equatable, Sendable {
    public let requestID: UUID
    public let text: String
    public let provider: TranslationProvider
    public init(requestID: UUID, text: String, provider: TranslationProvider) {
        self.requestID = requestID
        self.text = text
        self.provider = provider
    }
}

public enum TranslationFailure: Error, LocalizedError, Equatable {
    case emptyText, sameLanguage, textTooLong
    case networkForbidden, networkUnavailable, wrongProvider
    case engineNotConfigured, needsForeground, unsupportedDevice

    public var errorDescription: String? {
        switch self {
        case .emptyText: return "번역할 문장을 입력하세요."
        case .sameLanguage: return "서로 다른 두 언어를 선택하세요."
        case .textTooLong: return "문장을 8,000자 이하로 나누어 입력하세요."
        case .networkForbidden: return "오프라인 모드에서는 외부 서버로 전송할 수 없습니다."
        case .networkUnavailable: return "인터넷 연결을 확인하세요."
        case .wrongProvider: return "선택한 모드와 번역 엔진이 일치하지 않습니다."
        case .engineNotConfigured: return "이 번역 방식은 아직 연결되지 않았습니다."
        case .needsForeground: return "iPhone에서 앱을 열어 번역을 계속하세요."
        case .unsupportedDevice: return "이 엔진은 iPhone에서 실행해야 합니다."
        }
    }
}
