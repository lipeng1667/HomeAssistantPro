// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HomeAssistantPro",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.0.0")
    ],
    targets: [
        .target(
            name: "HomeAssistantPro",
            dependencies: [
                .product(name: "SocketIO", package: "socket.io-client-swift")
            ]
        )
    ]
)