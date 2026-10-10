import Foundation
import XCTest
@testable import TranslatorCore

final class WatchProtocolTests: XCTestCase {
    private func request(_ text: String = "내일 오전 열 시에 만나요.") -> WatchRequest {
        WatchRequest(translation: TranslationRequest(text: text, source: .korean, target: .english))
    }

    func testRoundTripPreservesKoreanAndCorrelationID() throws {
        let original = request()
        XCTAssertEqual(try WatchCodec.decodeRequest(WatchCodec.encode(original)), original)
    }

    func testMultibyteKoreanUsesByteLimit() {
        XCTAssertThrowsError(try WatchCodec.encode(request(String(repeating: "가", count: 667)))) {
            XCTAssertEqual($0 as? WatchProtocolError, .oversizedText)
        }
    }

    func testDecodeRejectsFutureProtocolVersion() throws {
        let invalid = WatchRequest(version: 2, translation: request().translation)
        let data = try JSONEncoder().encode(invalid)
        XCTAssertThrowsError(try WatchCodec.decodeRequest(data)) {
            XCTAssertEqual($0 as? WatchProtocolError, .unsupportedVersion)
        }
    }

    func testRejectsLargeDataBeforeJSONDecoding() {
        XCTAssertThrowsError(try WatchCodec.decodeRequest(Data(repeating: 0, count: 8_193))) {
            XCTAssertEqual($0 as? WatchProtocolError, .oversizedPayload)
        }
    }

    func testRejectsWhitespaceOnlyRequest() {
        XCTAssertThrowsError(try WatchCodec.encode(request(" \n\t "))) {
            XCTAssertEqual($0 as? TranslationFailure, .emptyText)
        }
    }

    func testRejectsSameLanguage() {
        let invalid = WatchRequest(translation: TranslationRequest(text: "hello", source: .english, target: .english))
        XCTAssertThrowsError(try WatchCodec.encode(invalid)) {
            XCTAssertEqual($0 as? TranslationFailure, .sameLanguage)
        }
    }

    func testResponseRoundTripKeepsTerminalStatus() throws {
        let original = WatchResponse(requestID: UUID(), status: .needsForeground, text: "iPhone 앱을 열어 주세요.")
        XCTAssertEqual(try WatchCodec.decodeResponse(WatchCodec.encode(original)), original)
    }

    func testResponseRejectsUnknownVersion() throws {
        let invalid = WatchResponse(version: 99, requestID: UUID(), status: .completed, text: "hello")
        XCTAssertThrowsError(try WatchCodec.decodeResponse(JSONEncoder().encode(invalid))) {
            XCTAssertEqual($0 as? WatchProtocolError, .unsupportedVersion)
        }
    }

    func testLedgerRejectsDuplicatesAndEvictsOldest() {
        var ledger = RequestLedger(capacity: 2)
        let first = UUID(), second = UUID(), third = UUID()
        XCTAssertTrue(ledger.insert(first))
        XCTAssertFalse(ledger.insert(first))
        XCTAssertTrue(ledger.insert(second))
        XCTAssertTrue(ledger.insert(third))
        XCTAssertFalse(ledger.insert(second))
        XCTAssertTrue(ledger.insert(first))
    }
}
