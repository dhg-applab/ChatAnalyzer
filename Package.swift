// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ChatAnalyzer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "ChatAnalyzer", targets: ["ChatAnalyzer"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.16")
    ],
    targets: [
        .target(
            name: "ChatAnalyzer",
            dependencies: ["ZIPFoundation"],
            resources: [
                .process("MachineLearning/Utils/stop_words_de.txt"),
                .process("MachineLearning/Utils/stop_words_en.txt")
            ]
        )
    ]
)
