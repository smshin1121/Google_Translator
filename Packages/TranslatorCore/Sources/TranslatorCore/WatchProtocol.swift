import Foundation

public struct WatchRequest: Codable, Equatable, Sendable {
    public let version: Int
    public let translation: TranslationRequest
    public init(version: Int = 1, translation: TranslationRequest) {
        self.version = version
        self.translation = translation
    }
}

public enum WatchResponseStatus: String, Codable, Sendable {
    case accepted, completed, needsForeground, unavailable, busy, rejected
}

public struct WatchResponse: Codable, Equatable, Sendable {
    public let version: Int
    public let requestID: UUID
    public let status: WatchResponseStatus
    public let text: String
    public init(version: Int = 1, requestID: UUID, status: WatchResponseStatus, text: String) {
        self.version = version
        self.requestID = requestID
        self.status = status
        self.text = text
    }
}

public enum WatchProtocolError: Error, Equatable {
    case unsupportedVersion, oversizedPayload, oversizedText
}

public enum WatchCodec {
    public static let maximumPayloadBytes = 8_192
    public static let maximumTextBytes = 2_000
    public static func encode(_ request: WatchRequest) throws -> Data {
        try validate(request)
        let data = try JSONEncoder().encode(request)
        guard data.count <= maximumPayloadBytes else { throw WatchProtocolError.oversizedPayload }
        return data
    }
    public static func decodeRequest(_ data: Data) throws -> WatchRequest {
        guard data.count <= maximumPayloadBytes else { throw WatchProtocolError.oversizedPayload }
        let request = try JSONDecoder().decode(WatchRequest.self, from: data)
        try validate(request)
        return request
    }
    public static func encode(_ response: WatchResponse) throws -> Data {
        guard response.version == 1 else { throw WatchProtocolError.unsupportedVersion }
        let data = try JSONEncoder().encode(response)
        guard data.count <= maximumPayloadBytes else { throw WatchProtocolError.oversizedPayload }
        return data
    }
    public static func decodeResponse(_ data: Data) throws -> WatchResponse {
        guard data.count <= maximumPayloadBytes else { throw WatchProtocolError.oversizedPayload }
        let response = try JSONDecoder().decode(WatchResponse.self, from: data)
        guard response.version == 1 else { throw WatchProtocolError.unsupportedVersion }
        return response
    }
    private static func validate(_ request: WatchRequest) throws {
        guard request.version == 1 else { throw WatchProtocolError.unsupportedVersion }
        guard request.translation.text.utf8.count <= maximumTextBytes else {
            throw WatchProtocolError.oversizedText
        }
        try request.translation.validate()
    }
}

/// Memory-only, bounded duplicate detection for a running phone session.
public struct RequestLedger {
    private var order: [UUID] = []
    private var known: Set<UUID> = []
    private let capacity: Int
    public init(capacity: Int = 128) { self.capacity = max(1, capacity) }
    public mutating func insert(_ id: UUID) -> Bool {
        guard known.insert(id).inserted else { return false }
        order.append(id)
        if order.count > capacity { known.remove(order.removeFirst()) }
        return true
    }
}
