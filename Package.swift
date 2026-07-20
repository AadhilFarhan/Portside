// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Portside",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PortsideCore"),
        .executableTarget(
            name: "Portside",
            dependencies: ["PortsideCore"]
        ),
        .testTarget(
            name: "PortsideCoreTests",
            dependencies: ["PortsideCore"]
        ),
    ]
)
