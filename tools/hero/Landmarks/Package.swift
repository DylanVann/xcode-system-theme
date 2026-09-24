// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Landmarks",
    platforms: [.macOS(.v15)],
    products: [.library(name: "Landmarks", targets: ["Landmarks"])],
    targets: [.target(name: "Landmarks")]
)
