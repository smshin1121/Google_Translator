import Combine
import Foundation
import WatchConnectivity
import TranslatorCore

@MainActor
final class CompanionLink: NSObject, ObservableObject {
    @Published private(set) var isReachable = false
    @Published private(set) var connectionText = "연결 확인 중"
    @Published private(set) var response: WatchResponse?
    @Published private(set) var waiting = false
    var onRequest: ((WatchRequest) -> WatchResponse)?
    private var pendingID: UUID?

    func activate() {
        guard WCSession.isSupported() else {
            connectionText = "이 기기에서는 Watch 연결을 사용할 수 없습니다."
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ request: WatchRequest) {
        guard !waiting else { return }
        guard WCSession.default.activationState == .activated, WCSession.default.isReachable else {
            response = WatchResponse(requestID: request.translation.id, status: .unavailable,
                                     text: "연결된 iPhone에서 앱을 열어 주세요.")
            return
        }
        do {
            let data = try WatchCodec.encode(request)
            pendingID = request.translation.id
            waiting = true
            response = nil
            WCSession.default.sendMessageData(data, replyHandler: { [weak self] data in
                Task { @MainActor in self?.receiveReply(data) }
            }, errorHandler: { [weak self] _ in
                Task { @MainActor in
                    self?.failPending(requestID: request.translation.id,
                                      message: "연결이 끊겼습니다. iPhone 앱을 열고 다시 요청하세요.")
                }
            })
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                self?.failPending(requestID: request.translation.id,
                                  message: "응답을 기다리는 시간이 길어졌습니다. iPhone 앱을 확인하세요.")
            }
        } catch {
            response = WatchResponse(requestID: request.translation.id, status: .rejected,
                                     text: "문장을 짧게 나누어 다시 입력하세요.")
        }
    }

    func publish(_ response: WatchResponse) {
        guard WCSession.default.activationState == .activated else { return }
        do {
            let data = try WatchCodec.encode(response)
            try WCSession.default.updateApplicationContext(["translationResponse": data])
        } catch {
            connectionText = "결과 동기화에 실패했습니다. iPhone에서 결과를 확인하세요."
        }
    }

    private func receiveReply(_ data: Data) {
        guard let incoming = try? WatchCodec.decodeResponse(data), pendingID == incoming.requestID else { return }
        receive(data)
    }

    private func receive(_ data: Data) {
        guard let incoming = try? WatchCodec.decodeResponse(data) else { return }
        if let pendingID, incoming.requestID != pendingID { return }
        if response?.requestID == incoming.requestID,
           response?.status == .completed, incoming.status == .accepted { return }
        response = incoming
        if incoming.status != .accepted {
            waiting = false
            pendingID = nil
        }
    }

    private func failPending(requestID: UUID, message: String) {
        guard pendingID == requestID else { return }
        response = WatchResponse(requestID: requestID, status: .unavailable, text: message)
        waiting = false
        pendingID = nil
    }

    private func refreshConnection() {
        isReachable = WCSession.default.isReachable
        connectionText = isReachable ? "iPhone 연결됨" : "iPhone 앱을 열어 주세요."
        if let data = WCSession.default.receivedApplicationContext["translationResponse"] as? Data {
            receive(data)
        }
    }
}

extension CompanionLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor [weak self] in self?.refreshConnection() }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor [weak self] in self?.refreshConnection() }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["translationResponse"] as? Data else { return }
        Task { @MainActor [weak self] in self?.receive(data) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data,
                             replyHandler: @escaping (Data) -> Void) {
        guard let request = try? WatchCodec.decodeRequest(messageData) else {
            let rejection = WatchResponse(requestID: UUID(), status: .rejected, text: "요청 형식을 확인하세요.")
            replyHandler((try? WatchCodec.encode(rejection)) ?? Data())
            return
        }
        Task { @MainActor [weak self] in
            let response = self?.onRequest?(request)
                ?? WatchResponse(requestID: request.translation.id, status: .unavailable,
                                 text: "iPhone 앱을 열어 주세요.")
            replyHandler((try? WatchCodec.encode(response)) ?? Data())
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
