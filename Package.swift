// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StatusChecker",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "StatusChecker",
            path: "Sources/StatusChecker"
        )
    ]
)
