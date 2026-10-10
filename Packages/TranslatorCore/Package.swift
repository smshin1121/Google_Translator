// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TranslatorCore",
    platforms: [.iOS("26.0"), .watchOS("26.0"), .macOS(.v13)],
    products: [.library(name: "TranslatorCore", targets: ["TranslatorCore"])],
    targets: [
        .target(name: "TranslatorCore"),
        .testTarget(name: "TranslatorCoreTests", dependencies: ["TranslatorCore"])
    ]
)
