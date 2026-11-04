// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}",
    platforms: [.iOS("12.0")],
    products: [
        .library(name: "{{package_prefix.paramCase()}}-{{name.paramCase()}}", targets: ["{{package_prefix.snakeCase()}}_{{name.snakeCase()}}"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
