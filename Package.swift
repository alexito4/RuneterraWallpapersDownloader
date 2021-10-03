// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "RuneterraWallpapersDownloader",
    platforms: [.macOS(.v10_13)],
    products: [
        .executable(
            name: "runeterrawallpaper",
            targets: ["CLI"]
        ),
        .library(
            name: "RuneterraWallpapersDownloader",
            targets: ["RuneterraWallpapersDownloader"]
        )
    ],
    dependencies: [
//        .package(url: "https://github.com/marmelroy/Zip", from: "2.1.1"),
        // https://github.com/marmelroy/Zip/pull/221
        .package(url: "https://github.com/maparoni/Zip.git", .revisionItem("059e7346082d02de16220cd79df7db18ddeba8c3")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "CLI",
            dependencies: [
                "RuneterraWallpapersDownloader",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "RuneterraWallpapersDownloader",
            dependencies: ["Zip"]
        ),
        .testTarget(
            name: "RuneterraWallpapersDownloaderTests",
            dependencies: ["RuneterraWallpapersDownloader"]
        ),
    ]
)
