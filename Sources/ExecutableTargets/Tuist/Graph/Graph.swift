import ArgumentParser
import Foundation
import TSCBasic
import ProjectAutomation
@_implementationOnly import TSCUtility

/// This is an example of an `executableTarget` target that requires entry for `main`thread and can be used for `swift scripting`
/// Following script is implemented using `https://github.com/apple/swift-argument-parser` package which provides a way to
/// receive user input from console/command-line, parse and validate the input
///
/// Then, we use tuist's `ProjectAutomation` which provides some useful functions to invoke Tuist commands
/// Note that process invocation happens through `TSCUtility` target of `https://github.com/apple/swift-tools-support-core` package


/// Usage: Enter on command-line
/// `swift run tuist-grapher --manifestPath absolute_path/to/tuist/manifest`
///  OR as a tuist task (use in Project.swift directory that is using this task plugin)
/// `tuist grapher --manifest-path absolute_path/to/tuist/manifest`
/// OR run via tust plugin (in Project.siwft directory that defines this plugin in its Config.swift)
/// `tuist plugin run tuist-grapher` OR `tuist plugin run tuist-grapher --manifest-path absolute_path/to/tuist/manifest`

@main
struct Graph: AsyncParsableCommand {
    
    static let VERSION = Version(1, 0, 0)
   
    @Flag(name: .shortAndLong, help: "Print tool version")
    var version: Bool = false
    
    @Option(name: .shortAndLong, help: "Path to manifest file of a project or workspace")
    var manifestPath: String? = nil
    
    mutating func run() async throws {
        printToolVersion()
        try await targets()
        //try await png()
    }
    
    func targets() async throws {
        let graph = try Tuist.graph(at: manifestPath)
        let targets = graph.projects.values.flatMap(\.targets)
        print("These are the current project's targets: \(targets.map(\.name).joined(separator: "\n"))")
    }
    
    public func png() async throws {
        var arguments = [
            "tuist",
            "graph",
            "--verbose"
        ]
        if let path = manifestPath {
            arguments += ["--path", path]
        }
        try run(
            arguments,
            environment: [:]
        )
    }
    
    private func run(
        _ arguments: [String],
        environment: [String: String]
    ) throws {
        let process = Process(
            arguments: arguments,
            environment: environment,
            outputRedirection: .none,
            startNewProcessGroup: false
        )
        
        try process.launch()
        try process.waitUntilExit()
    }
    
    private func printToolVersion() {
        if version {
            print("Tool Version v\(Graph.VERSION)")
        }
    }
}
