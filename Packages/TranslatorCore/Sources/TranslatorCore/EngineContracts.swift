import Foundation

public protocol TextTranslationEngine: Sendable {
    var provider: TranslationProvider { get }
    func translate(_ request: TranslationRequest) async throws -> TranslationResult
}

public struct TranscriptSegment: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let startMilliseconds: Int64
    public let endMilliseconds: Int64
    public let text: String
    public let isFinal: Bool
    public let speakerID: String?
    public let translation: String?

    public init(id: UUID = UUID(), startMilliseconds: Int64, endMilliseconds: Int64,
                text: String, isFinal: Bool, speakerID: String? = nil, translation: String? = nil) {
        self.id = id
        self.startMilliseconds = startMilliseconds
        self.endMilliseconds = endMilliseconds
        self.text = text
        self.isFinal = isFinal
        self.speakerID = speakerID
        self.translation = translation
    }
}

public struct MinuteItem: Codable, Equatable, Sendable {
    public let text: String
    public let sourceSegmentIDs: [UUID]
    public let assignee: String?
    public let dueDate: String?
    public init(text: String, sourceSegmentIDs: [UUID], assignee: String? = nil, dueDate: String? = nil) {
        self.text = text
        self.sourceSegmentIDs = sourceSegmentIDs
        self.assignee = assignee
        self.dueDate = dueDate
    }
}

public struct MeetingMinutes: Codable, Equatable, Sendable {
    public let summary: [MinuteItem]
    public let decisions: [MinuteItem]
    public let actionItems: [MinuteItem]
    public init(summary: [MinuteItem], decisions: [MinuteItem], actionItems: [MinuteItem]) {
        self.summary = summary
        self.decisions = decisions
        self.actionItems = actionItems
    }
}

public protocol MinutesEngine: Sendable {
    func summarize(finalSegments: [TranscriptSegment]) async throws -> MeetingMinutes
}

public protocol SpeechOutputEngine: Sendable {
    func speak(_ text: String, language: AppLanguage) async throws
}
