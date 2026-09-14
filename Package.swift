// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "wispr-tap",
  platforms: [.macOS(.v11)],
  targets: [
    .systemLibrary(name: "MultitouchSupport", path: "Sources/wispr-tap/MultitouchSupport"),
    .executableTarget(
      name: "wispr-tap",
      dependencies: ["MultitouchSupport"],
      linkerSettings: [
        .linkedFramework("MultitouchSupport"),
        .unsafeFlags(["-F/System/Library/PrivateFrameworks"]),
      ]
    ),
  ]
)
