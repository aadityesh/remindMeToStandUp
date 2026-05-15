// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Standup",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Standup",
            path: "Sources/Standup"
        )
    ]
)
