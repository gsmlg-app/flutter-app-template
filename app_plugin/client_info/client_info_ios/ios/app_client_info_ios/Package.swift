// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "app_client_info_ios",
    platforms: [.iOS("12.0")],
    products: [
        .library(name: "app-client-info-ios", targets: ["app_client_info_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "app_client_info_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
