// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "app_client_info_macos",
    platforms: [.macOS("10.14")],
    products: [
        .library(name: "app-client-info-macos", targets: ["app_client_info_macos"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "app_client_info_macos",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
