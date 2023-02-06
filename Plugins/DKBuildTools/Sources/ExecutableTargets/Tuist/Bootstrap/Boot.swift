import ArgumentParser
import ProjectAutomation
@_implementationOnly import TSCUtility

/// This is an example of an `executableTarget` target that requires entry for `main`thread and can be used for `swift scripting`
/// Following script is implemented using `https://github.com/apple/swift-argument-parser` package which provides a way to
/// receive user input from console/command-line, parse and validate the input
///
/// Then, we use tuist's `ProjectAutomation` which provides some useful functions to invoke Tuist commands
/// Note that process invocation happens through `TSCUtility` target of `https://github.com/apple/swift-tools-support-core` package

/// Usage: Enter on command-line
/// `swift run Bootstrap -n "Sportsbook" --version`

@main
struct Boot: AsyncParsableCommand {

    static let VERSION = Version(1, 0, 0)
    
    @Flag(name: .shortAndLong, help: "Print tool version")
    var version: Bool = false
    
    @Option(name: .shortAndLong, help: "Name of tuist project")
    var name: String
    
    @Flag(name: .shortAndLong, help: "Enable/disable caching")
    var cacheEnabled: Bool = false
    
    @Option(help: "Caching profile")
    var profile: String = "Development"
    
    mutating func run() async throws {
        print("I am running")
        print("name --> \(name)")
        print("profile --> \(profile)")
        print("cacheEnabled --> \(cacheEnabled)")
        
        if version {
            print("Version --> v\(Boot.VERSION)")
        }
    }
}
