// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Roast",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Roast", targets: ["Roast"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.5.0")
    ],
    targets: [
        .executableTarget(
            name: "Roast",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: ".",
            exclude: [
                "Package.swift",
                "Info.plist",
                "Roast.entitlements"
            ],
            sources: [
                "App",
                "Monitoring",
                "Data",
                "Analytics",
                "AI",
                "Views",
                "Utilities"
            ],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        )
    ]
)
