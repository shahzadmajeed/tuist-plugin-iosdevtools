//
//  SwiftGen.swift
//  
//
//  Created by Shahzad Majeed on 12/29/22.
//

/// This plugin uses `https://github.com/SwiftGen/SwiftGen` package to generate source code
///
/// Note: This source code is copied from following swift-evolution proposal
/// Source:
/// https://github.com/apple/swift-evolution/blob/main/proposals/0303-swiftpm-extensible-build-tools.md
/// https://github.com/apple/swift-evolution/blob/main/proposals/0325-swiftpm-additional-plugin-apis.md
///
/// The configuration is added to `swiftgen.yml` file which is based on https://github.com/SwiftGen/SwiftGen/blob/stable/Documentation/ConfigFile.md
///
/// Usage: In-order to use this plugin, add it to `plugins` of a target i.e., `plugins: [.plugin(name: "SourceGen")]`

import PackagePlugin

@main
struct SwiftGen: BuildToolPlugin {
    /// This plugin's implementation returns a single `prebuild` command to run `swiftgen`.
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        print("This is SwiftGenPlugin...")
        // This example configures `swiftgen` to take inputs from a `swiftgen.yml` file
        let swiftGenConfigFile = context.package.directory.appending("swiftgen.yml")
        
        // This example configures the command to write to a "GeneratedSources" directory.
        let genSourcesDir = context.pluginWorkDirectory.appending("GeneratedSources")
        
        // Return a command to run `swiftgen` as a pre-build command. It will be run before
        // every build and generates source files into an output directory provided by the
        // build context. This example sets some environment variables that `swiftgen.yml`
        // bases its output paths on.
        let command: Command = .prebuildCommand(
            displayName: "Running SwiftGen",
            executable: try context.tool(named: "swiftgen").path,
            arguments: [
                "config", "run",
                "--config", "\(swiftGenConfigFile)"
            ],
            environment: [
                "PROJECT_DIR": "\(context.package.directory)",
                "TARGET_NAME": "\(target.name)",
                "DERIVED_SOURCES_DIR": "\(genSourcesDir)",
            ],
            outputFilesDirectory: genSourcesDir
        )
        
        return [command]
    }
}
