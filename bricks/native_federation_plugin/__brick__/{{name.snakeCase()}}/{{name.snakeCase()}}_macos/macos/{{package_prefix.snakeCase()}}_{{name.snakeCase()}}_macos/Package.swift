// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_macos",
    platforms: [.macOS("10.14")],
    products: [
        .library(name: "{{package_prefix.paramCase()}}-{{name.paramCase()}}-macos", targets: ["{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_macos"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_macos",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
