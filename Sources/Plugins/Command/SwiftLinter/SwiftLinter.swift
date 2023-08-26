//
//  SwiftLinter.swift
//  
//
//  Created by Shahzad Majeed on 12/29/22.
//

/// This plugin uses `https://github.com/apple/swift-format` package to format and lint the code
/// 
/// Note: This source code is copied from following swift-evolution proposal
/// Source: https://github.com/apple/swift-evolution/blob/main/proposals/0332-swiftpm-command-plugins.md
///
/// Example:
/// `swift package --verbose --allow-writing-to-package-directory lint`
/// OR via plugin `swift package --verbose --verbose plugin --allow-writing-to-package-directory lint`
/// The configuration is added to `.swift-format.json` file which is based on https://github.com/apple/swift-format/blob/main/Documentation/Configuration.md
/// Note: `--allow-writing-to-package-directory` is passed for disk IO permissions, otherwise package will ask you for permissions if `stdin` is attached to a `TTY`
/// List all available plugins with `swift package plugin --list` or do `swift package describe` to see all information about a package

import PackagePlugin
import Foundation

@main
struct SwiftLinter: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        // We'll be invoking `swift-format`, so start by locating it.
        let swiftFormatTool = try context.tool(named: "swift-format")
        
        // By convention, use a configuration file in the package directory.
        let configFile = context.package.directory.appending(".swift-format.json")
        
        // Iterate over the targets in the package.
        for target in context.package.targets {
            // Skip any type of target that doesn't have source files.
            // Note: We could choose to instead emit a warning or error here.
            guard let target = target as? SourceModuleTarget else { continue }
            
            // Invoke `swift-format` on the target directory, passing a configuration
            // file from the package directory.
            let swiftFormatExec = URL(fileURLWithPath: swiftFormatTool.path.string)
            let swiftFormatArgs = [
                "--configuration", "\(configFile)",
                "--in-place",
                "--recursive",
                "\(target.directory)"
            ]
            let process = try Process.run(swiftFormatExec, arguments: swiftFormatArgs)
            process.waitUntilExit()
            
            // Check whether the subprocess invocation was successful.
            if process.terminationReason == .exit && process.terminationStatus == 0 {
                print("Formatted the source code in \(target.directory).")
            }
            else {
                let problem = "\(process.terminationReason):\(process.terminationStatus)"
                Diagnostics.error("swift-format invocation failed: \(problem)")
            }
        }
    }
}
