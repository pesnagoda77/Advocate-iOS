// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Advocate",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "Advocate",
            targets: ["Advocate"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Advocate",
            path: ".",
            exclude: ["README.md", "AppStore", "Tests"],
            swiftSettings: [
                .enableExperimentalFeature("SwiftData")
            ]
        )
    ]
)