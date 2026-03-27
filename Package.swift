// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StatusChecker",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "StatusCheckerLib",
            path: "Sources/StatusChecker"
        ),
        .executableTarget(
            name: "StatusChecker",
            dependencies: ["StatusCheckerLib"],
            path: "Sources/StatusCheckerApp"
        ),
        .testTarget(
            name: "StatusCheckerTests",
            dependencies: ["StatusCheckerLib"],
            path: "Tests/StatusCheckerTests"
        )
    ]
)
