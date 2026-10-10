import XCTest
@testable import TranslatorCore

final class RoutePolicyTests: XCTestCase {
    func testOfflineNeverUsesManagedOrPersonalServer() {
        let context = ExecutionContext(networkAvailable: true, engineConfigured: true)
        for provider in [TranslationProvider.managedService, .personalEndpoint] {
            XCTAssertThrowsError(try RoutePolicy.validate(mode: .offline, provider: provider, context: context)) {
                XCTAssertEqual($0 as? TranslationFailure, .networkForbidden)
            }
        }
    }

    func testOfflineAppleTranslationDoesNotRequireInternet() {
        XCTAssertNoThrow(try RoutePolicy.validate(mode: .offline, provider: .appleTranslation,
            context: ExecutionContext(networkAvailable: false, engineConfigured: true)))
    }

    func testPersonalAPIRequiresItsOwnProvider() {
        XCTAssertThrowsError(try RoutePolicy.validate(mode: .personalAPI, provider: .managedService,
            context: ExecutionContext(networkAvailable: true, engineConfigured: true))) {
                XCTAssertEqual($0 as? TranslationFailure, .wrongProvider)
            }
    }

    func testOnlineRequiresManagedProvider() {
        XCTAssertThrowsError(try RoutePolicy.validate(mode: .online, provider: .appleTranslation,
            context: ExecutionContext(networkAvailable: true, engineConfigured: true))) {
                XCTAssertEqual($0 as? TranslationFailure, .wrongProvider)
            }
    }

    func testRemoteNeedsConnectivity() {
        XCTAssertThrowsError(try RoutePolicy.validate(mode: .personalAPI, provider: .personalEndpoint,
            context: ExecutionContext(networkAvailable: false, engineConfigured: true))) {
                XCTAssertEqual($0 as? TranslationFailure, .networkUnavailable)
            }
    }

    func testUnconfiguredProviderFails() {
        XCTAssertThrowsError(try RoutePolicy.validate(mode: .online, provider: .managedService,
            context: ExecutionContext(networkAvailable: true, engineConfigured: false))) {
                XCTAssertEqual($0 as? TranslationFailure, .engineNotConfigured)
            }
    }

    func testWatchCannotRunLocalPhoneEngine() {
        XCTAssertThrowsError(try RoutePolicy.validate(mode: .offline, provider: .gemmaGPU,
            context: ExecutionContext(isPhone: false, engineConfigured: true))) {
                XCTAssertEqual($0 as? TranslationFailure, .unsupportedDevice)
            }
    }

    func testBackgroundGPURequiresBothTaskAndGPUGrant() {
        for (task, gpu) in [(false, false), (true, false), (false, true)] {
            XCTAssertThrowsError(try RoutePolicy.validate(mode: .offline, provider: .gemmaGPU,
                context: ExecutionContext(isForeground: false, engineConfigured: true,
                    continuedProcessingTaskActive: task, backgroundGPUGranted: gpu))) {
                    XCTAssertEqual($0 as? TranslationFailure, .needsForeground)
                }
        }
        XCTAssertNoThrow(try RoutePolicy.validate(mode: .offline, provider: .gemmaGPU,
            context: ExecutionContext(isForeground: false, engineConfigured: true,
                continuedProcessingTaskActive: true, backgroundGPUGranted: true)))
    }

    func testBackgroundCPUAlsoNeedsExecutionBudget() {
        XCTAssertThrowsError(try RoutePolicy.validate(mode: .offline, provider: .gemmaCPU,
            context: ExecutionContext(isForeground: false, engineConfigured: true))) {
                XCTAssertEqual($0 as? TranslationFailure, .needsForeground)
            }
    }

    func testAppleTranslationNeedsVisiblePhoneApp() {
        XCTAssertThrowsError(try RoutePolicy.validate(mode: .offline, provider: .appleTranslation,
            context: ExecutionContext(isForeground: false, engineConfigured: true,
                continuedProcessingTaskActive: true, backgroundGPUGranted: true))) {
                XCTAssertEqual($0 as? TranslationFailure, .needsForeground)
            }
    }
}
