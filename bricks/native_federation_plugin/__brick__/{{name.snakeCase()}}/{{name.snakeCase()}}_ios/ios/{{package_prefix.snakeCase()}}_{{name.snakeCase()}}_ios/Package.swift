// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_ios",
    platforms: [.iOS("12.0")],
    products: [
        .library(name: "{{package_prefix.paramCase()}}-{{name.paramCase()}}-ios", targets: ["{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
