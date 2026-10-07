// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LidBlur",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LidBlur",
            path: "Sources/LidBlur"
        )
    ]
)
