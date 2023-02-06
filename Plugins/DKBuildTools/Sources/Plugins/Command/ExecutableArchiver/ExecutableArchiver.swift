//
//  ExecutableArchiver.swift
//  
//
//  Created by Shahzad Majeed on 12/29/22.
//

/// This plugin archives given executable for release/distribution purposes
///
/// Note: This source code is copied from following swift-evolution proposal
/// Source: https://github.com/apple/swift-evolution/blob/main/proposals/0332-swiftpm-command-plugins.md
///
/// Example:
/// `swift package --verbose --allow-writing-to-package-directory create-archive Graph Graph-v1.0`
/// OR via plugin `swift package --verbose plugin --allow-writing-to-package-directory create-archive Graph Graph-v1.0`
/// Note: `--allow-writing-to-package-directory` is passed for disk IO permissions, otherwise package will ask you for permissions if `stdin` is attached to a `TTY`
/// List all available plugins with `swift package plugin --list` or do `swift package describe` to see all information about a package


import PackagePlugin
import Foundation

@main
struct ExecutableArchiver: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {
        // Check that we were given the name of a product as the first argument
        // and the name of an archive as the second.
        guard arguments.count == 2 else {
            throw ArchiveError.missingArguments
        }
        let productName = arguments[0]
        let archiveName = arguments[1]
        
        // Ask the plugin host (SwiftPM or an IDE) to build our product.
        let result = try packageManager.build(
            .product(productName),
            parameters: .init(configuration: .release, logging: .concise)
        )
        
        // Check the result. Ideally this would report more details.
        guard result.succeeded else { throw ArchiveError.buildFailed }
        
        // Get the list of built executables from the build result.
        let builtExecutables = result.builtArtifacts.filter{ $0.kind == .executable }
        
        // Decide on the output path for the archive.
        let outputPath = context.pluginWorkDirectory.appending("\(archiveName).zip")
        
        // Use Foundation to run `zip`. The exact details of using the Foundation
        // API aren't relevant; the point is that the built artifacts can be used
        // by the script.
        let zipTool = try context.tool(named: "zip")
        let zipArgs = ["-j", outputPath.string] + builtExecutables.map{ $0.path.string }
        let zipToolURL = URL(fileURLWithPath: zipTool.path.string)
        let process = try Process.run(zipToolURL, arguments: zipArgs)
        process.waitUntilExit()
        
        // Check whether the subprocess invocation was successful.
        if process.terminationReason == .exit && process.terminationStatus == 0 {
            print("Created distribution archive at \(outputPath).")
        }
        else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("zip invocation failed: \(problem)")
        }
    }
}

enum ArchiveError: Error {
    case buildFailed
    case missingArguments
    var description: String {
        switch self {
            case .buildFailed:
                return "Couldn't build product"
            case .missingArguments:
                return "Expected two arguments: product name and archive name"
        }
    }
}
