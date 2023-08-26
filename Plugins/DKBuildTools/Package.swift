// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let package = Package(
    name: "SwiftDevToolsPlugin",
    platforms: [.macOS(.v11)],
    products: [
        /// In addition to the current package "SwiftDevToolsPlugin", other packages can also use following products
        .executable(name: "tuist-grapher", targets: ["tuist-grapher"]),
        .executable(name: "tuist-bootstrap", targets: ["tuist-bootstrap"]),
        .plugin(name: "DocGenerator", targets: ["DocGenerator"]),
        .plugin(name: "SwiftLinter", targets: ["SwiftLinter"]),
        .plugin(name: "ExecutableArchiver", targets: ["ExecutableArchiver"]),
        .plugin(name: "SourceGen", targets: ["SourceGen"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
        .package(url: "https://github.com/tuist/ProjectAutomation", from: Version(3, 15, 0)),
        .package(url: "https://github.com/apple/swift-format", exact: Version(0, 50700, 1)),
        .package(url: "https://github.com/SwiftGen/SwiftGen", exact: Version(6, 6, 2)),
        //.package(url: "https://github.com/apple/swift-tools-support-core", exact: Version(0, 2, 7))
    ],
    targets: [
        /// Command Plugins
        /// https://github.com/apple/swift-evolution/blob/main/proposals/0332-swiftpm-command-plugins.md
        /// Plugins can access command-line tools like `zip`, `docc`, `xcodebuild` directly via `try context.tool(named: "zip")` but third party tools
        /// like `swift-format` will need to be exposed to `context` as a dependency. See `SwiftLinter` plugin target as an example below
        .plugin(
            name: "DocGenerator",
            capability: .command(
                /// You can use existing intent or create a custom one. If you use existing intent then you have to use pre-defined commands to invoke the plugin
                // intent: .documentationGeneration(),
                intent: .custom(
                    verb: "create-doc",
                    description: "Creates a .zip containing release builds of products"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "This command generates documentation in .builds directory. Write permission is needed!")
                ]
            ),
            path: "Sources/Plugins/Command/DocGenerator"
        ),
        .plugin(
            name: "SwiftLinter",
            capability: .command(
                intent: .custom(
                    verb: "lint",
                    description: "Creates a .zip containing release builds of products"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "This command reformats source files. Write permission is needed!")
                ]
            ),
            dependencies: [
                /// This will provide `SwiftLinter` plugin target access to `swift-format` tool
                /// You don't need to import this tool in `SwiftLinter` target as we will locate the build tool via `context`
                .product(name: "swift-format", package: "swift-format")
            ],
            path: "Sources/Plugins/Command/SwiftLinter"
        ),
        .plugin(
            name: "ExecutableArchiver",
            capability: .command(
                intent: .custom(
                    verb: "create-archive",
                    description: "Creates a .zip containing release builds of products"
                )
            ),
            path: "Sources/Plugins/Command/ExecutableArchiver"
        ),
        /// BuildTool Plugins
        /// Build plugins need to be attached to a target so that SPM can pass context of that target to the plugin before it builds the target
        /// Package plugin that tells SwiftPM how to run `swiftgen` based on
        /// the configuration file. Client targets use this plugin by listing it in their `plugins` parameter.
        .plugin(
            name: "SourceGen",
            capability: .buildTool(),
            dependencies: [
                .product(name: "swiftgen", package: "SwiftGen")
            ],
            path: "Sources/Plugins/BuildTool/SourceGen"
        ),
        /// Executable Targets
        .executableTarget(
            name: "tuist-bootstrap",
            dependencies: [
                .product(name: "ProjectAutomation", package: "ProjectAutomation"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                //.product(name: "TSCUtility", package: "swift-tools-support-core")
            ],
            path: "Sources/ExecutableTargets/Tuist/Bootstrap"
        ),
        .executableTarget(
            name: "tuist-grapher",
            dependencies: [
                .product(name: "ProjectAutomation", package: "ProjectAutomation"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                //.product(name: "TSCUtility", package: "swift-tools-support-core")
                .target(name: "CoreUtils")
            ],
            path: "Sources/ExecutableTargets/Tuist/Graph"
        ),
        .target(
            name: "CoreUtils",
            dependencies: [],
            resources: [.copy("Resources")],
            plugins: [.plugin(name: "SourceGen")]
        ),
        .testTarget(
            name: "tuist-bootstrap-tests",
            dependencies: ["tuist-bootstrap"],
            path: "Tests/tuist-bootstrap-tests"
        ),
    ]
)
