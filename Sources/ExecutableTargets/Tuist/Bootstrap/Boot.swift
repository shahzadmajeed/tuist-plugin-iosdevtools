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
struct MainCommand: AsyncParsableCommand {

    static var configuration = CommandConfiguration(
           commandName: "devtools",
           abstract: "Tools that extend Tuist CLI to define developer workflows for iOS development",
           subcommands: [
               Fetch.self,          // fetch dependencies
               Cache.self,          // cache targers
               Codesign.self,       // setup code signing certificates & provisioning profiles
               Generate.self,       // generate projects
               Print.self           // print project structure, dependencies and other useful information
           ],
           defaultSubcommand: Version.self
       )
}
