import Foundation

public enum TranslationProvider: String, Codable, Sendable {
    case appleTranslation, gemmaCPU, gemmaGPU, managedService, personalEndpoint
    public var sendsContentToServer: Bool {
        self == .managedService || self == .personalEndpoint
    }
}

public struct ExecutionContext: Sendable {
    public var isPhone: Bool
    public var isForeground: Bool
    public var networkAvailable: Bool
    public var engineConfigured: Bool
    public var continuedProcessingTaskActive: Bool
    public var backgroundGPUGranted: Bool

    public init(isPhone: Bool = true, isForeground: Bool = true,
                networkAvailable: Bool = false, engineConfigured: Bool = false,
                continuedProcessingTaskActive: Bool = false, backgroundGPUGranted: Bool = false) {
        self.isPhone = isPhone
        self.isForeground = isForeground
        self.networkAvailable = networkAvailable
        self.engineConfigured = engineConfigured
        self.continuedProcessingTaskActive = continuedProcessingTaskActive
        self.backgroundGPUGranted = backgroundGPUGranted
    }
}

/// Checks the selected route; never substitutes a remote engine on failure.
/// The adapter must also check OS task eligibility and model/language availability.
public enum RoutePolicy {
    public static func validate(mode: ProcessingMode, provider: TranslationProvider,
                                context: ExecutionContext) throws {
        if mode == .offline && provider.sendsContentToServer {
            throw TranslationFailure.networkForbidden
        }
        if mode == .online && provider != .managedService { throw TranslationFailure.wrongProvider }
        if mode == .personalAPI && provider != .personalEndpoint { throw TranslationFailure.wrongProvider }
        if provider.sendsContentToServer {
            guard context.networkAvailable else { throw TranslationFailure.networkUnavailable }
        } else {
            guard context.isPhone else { throw TranslationFailure.unsupportedDevice }
            if !context.isForeground {
                switch provider {
                case .appleTranslation:
                    throw TranslationFailure.needsForeground
                case .gemmaCPU:
                    guard context.continuedProcessingTaskActive else { throw TranslationFailure.needsForeground }
                case .gemmaGPU:
                    guard context.continuedProcessingTaskActive && context.backgroundGPUGranted else {
                        throw TranslationFailure.needsForeground
                    }
                default: break
                }
            }
        }
        guard context.engineConfigured else { throw TranslationFailure.engineNotConfigured }
    }
}
