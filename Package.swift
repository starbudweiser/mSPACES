// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "mSPACES",
    platforms: [.macOS(.v13)],
    targets: [.executableTarget(name: "mSPACES", path: "Sources/mSPACES")]
)
