// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CuadraCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CuadraCore", targets: ["CuadraCore"])
    ],
    targets: [
        .target(name: "CuadraCore"),
        .testTarget(name: "CuadraCoreTests", dependencies: ["CuadraCore"])
    ]
)
