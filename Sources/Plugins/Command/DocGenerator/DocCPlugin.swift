//
//  DocCPlugin.swift
//  
//
//  Created by Shahzad Majeed on 12/29/22.

/// This plugin uses DocC compiler to generate documentation for all targets in this swift package
/// 
/// Note: This source code is copied from following swift-evolution proposal
/// Source: https://github.com/apple/swift-evolution/blob/main/proposals/0332-swiftpm-command-plugins.md
///
/// Example:
/// `swift package --verbose --allow-writing-to-package-directory create-doc`
/// OR via plugin `swift package --verbose plugin --allow-writing-to-package-directory create-doc`
/// Note: `--allow-writing-to-package-directory` is passed for disk IO permissions, otherwise package will ask you for permissions if `stdin` is attached to a `TTY`
/// List all available plugins with `swift package plugin --list` or do `swift package describe` to see all information about a package

import PackagePlugin
import Foundation

/// This Plugin is an example of `command` plugins that can be implemented using `PackagePlugin` framework

@main
struct DocCPlugin: CommandPlugin {
    
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        // We'll be creating commands that invoke `docc`, so start by locating it.
        let doccTool = try context.tool(named: "docc")
        
        // Construct the path of the directory in which to emit documentation.
        let outputDir = context.pluginWorkDirectory.appending("Outputs")
        
        // Iterate over the targets in the package.
        for target in context.package.targets {
            // Only consider those kinds of targets that can have source files.
            guard let target = target as? SourceModuleTarget else { continue }
            
            // Find the first DocC catalog in the target, if there is one (a more
            // robust example would handle the presence of multiple catalogs).
            let doccCatalog = target.sourceFiles.first { $0.path.extension == "docc" }
            
            // Ask SwiftPM to generate or update symbol graph files for the target.
            let symbolGraphInfo = try packageManager.getSymbolGraph(
                for: target,
                options: .init(
                    minimumAccessLevel: .private,
                    includeSynthesized: false,
                    includeSPI: false
                )
            )
            
            // Invoke `docc` with arguments and the optional catalog.
            let doccExec = URL(fileURLWithPath: doccTool.path.string)
            var doccArgs = ["convert"]
            if let doccCatalog = doccCatalog {
                doccArgs += ["\(doccCatalog.path)"]
            }
            doccArgs += [
                "--fallback-display-name", target.name,
                "--fallback-bundle-identifier", target.name,
                "--fallback-bundle-version", "0",
                "--additional-symbol-graph-dir", "\(symbolGraphInfo.directoryPath)",
                "--output-dir", "\(outputDir)",
            ]
            let process = try Process.run(doccExec, arguments: doccArgs)
            process.waitUntilExit()
            
            // Check whether the subprocess invocation was successful.
            if process.terminationReason == .exit && process.terminationStatus == 0 {
                print("Generated documentation at \(outputDir).")
            }
            else {
                let problem = "\(process.terminationReason):\(process.terminationStatus)"
                Diagnostics.error("docc invocation failed: \(problem)")
            }
        }
    }
}
