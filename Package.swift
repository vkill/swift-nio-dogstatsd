// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "NIODatadogStatsd",
    products: [
        .library(name: "NIODatadogStatsd", targets: ["NIODatadogStatsd"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.8.0"),
        .package(url: "https://github.com/vkill/swift-dogstatsd.git", .branch("master")),
    ],
    targets: [
        .target(name: "NIODatadogStatsd", dependencies: ["NIO", "DatadogStatsd"]),
        .testTarget(name: "NIODatadogStatsdTests", dependencies: ["NIODatadogStatsd"]),
    ]
)
