//
//  Extensions.swift
//  
//
//  Created by Shahzad Majeed on 9/6/23.
//

import Foundation
import ShellOut
import Rainbow
import SwiftCommand

// MARK: Extensions/Workflows
/// TODO: Move following extensions to a general purpose toolkit target

public func echo(_ message: String, color: Color = .lightGreen) throws {
    /// Note: We are intentionally not using `executeShell` function because otherwise we will get stuck with a recursive calls/loop
    print(try shellOut(to: .echo(message)).applyingCodes(color))
}

public func checkToolInstalled(_ tool: String) async throws -> Bool {
    
    let output = try await Command.findInPath(withName: "which")!
        .addArguments(tool)
        .output
    
    return !output.stdout.isEmpty && output.stdout.contains(tool)

    
    //let output = try executeShell(to: .which(tool))
    //return !output.isEmpty && output.contains(tool)
}

public func tuistVersion() async throws  -> String {
    
    let output = try await Command(executablePath: .init("/usr/local/bin/tuist"))
        .addArguments("version")
        .output
    
    return output.stdout
    //try executeShell(to: .tuistVersion())
}

public func installTuist() throws {
    //try executeShell(to: .installTuistEnvironment())
}

public func checkTuistInstalled() async throws {
    if try await checkToolInstalled(CONSTANTS.TOOLS.TUIST) {
        try echo("Tuist \(try await tuistVersion()) is installed already... Skipping installation")
    } else {
        try echo("Installing Tuist...")
        try installTuist()
        try echo("Installed version \(try await tuistVersion())")
    }
}

public func tuistFetch(update: Bool, verbose: Bool, additionalArguments: [String] = [], environmentVariables: [String] = []) async throws {
//    let command: ShellOutCommand = .tuistFetch(verbose: verbose, update: update, additionalArguments: additionalArguments)
//    try executeShell(to: command, environmentVariables: environmentVariables)
    try await executeShell(to: "tuist", arguments: ["fetch", "--update"])
}

public func tuistGenerate(targets: [String],
                          projectPath: String?,
                          cacheProfile: String,
                          openInXcode: Bool,
                          verbose: Bool,
                          additionalArguments: [String] = [],
                          environmentVariables: [String] = []) async throws {
//    let command: ShellOutCommand = .tuistGenerate(targets: targets,
//                                                  projectPath: projectPath,
//                                                  cacheProfile: cacheProfile,
//                                                  verbose: verbose,
//                                                  openInXcode: openInXcode,
//                                                  additionalArguments: additionalArguments)
//    try executeShell(to: command, environmentVariables: environmentVariables)
//
    /// SwiftCommand doesn't like spaces in each argument so we cannot combine all arguments into a single or even provide value for an
    /// argument within same string. So, we have to split them into separate strings
    try await executeShell(to: "tuist", arguments: ["generate", "--profile", "\(cacheProfile)", "--path", "\(projectPath!)"])
}

public func tuistCacheWarm(targets: [String] = [],
                           projectPath: String? = nil,
                           cacheProfile: String,
                           verbose: Bool,
                           additionalArguments: [String] = [],
                           environmentVariables: [String] = []) async throws {
    
    var arguments: [String] = ["\(CONSTANTS.TUIST_ARGS.PROFILE) \(cacheProfile)"]
    if let projectPath = projectPath {
        arguments.append("\(CONSTANTS.TUIST_ARGS.PATH) \(projectPath)")
    } else {
        arguments.append(contentsOf: targets)
    }
    if verbose {
        arguments.append(CONSTANTS.TUIST_ARGS.VERBOSE)
    }
    
    //try shellOut(to: "tuist \(CONSTANTS.TUIST_COMMANDS.CACHE_WARM)", arguments: arguments + additionalArguments, at: projectPath ?? ".")
    
    //    let command: ShellOutCommand = .tuistCacheWarm(targets: targets,
    //                                                   projectPath: projectPath,
    //                                                   cacheProfile: cacheProfile,
    //                                                   verbose: verbose,
    //                                                   additionalArguments: additionalArguments)
    //    try executeShell(to: command, environmentVariables: environmentVariables)
    
    try await executeShell(to: "tuist", arguments: ["cache", "warm", "--profile", "\(cacheProfile)", "--path", "\(projectPath!)"])
}

// MARK: General Commands

public extension ShellOutCommand {
    /// echo command
    static func echo(_ message: String) -> ShellOutCommand {
        CONSTANTS
            .TOOLS
            .ECHO
            .appending(argument: message)
            .shellOutCommand()
    }
    
    /// tool installation check command
    static func which(_ tool: String) -> ShellOutCommand {
        CONSTANTS
            .TOOLS
            .WHICH
            .appending(argument: tool)
            .shellOutCommand()
    }
    
    /// curl command
    static func curlBash(_ url: String, arguments: [String]) -> ShellOutCommand {
        CONSTANTS
            .TOOLS
            .CURL
            .appending(arguments: arguments)
            .appending(" \(url) | bash")
            .shellOutCommand()
    }
}

@discardableResult
public func executeShell(
    to command: String,
    arguments: [String] = [],
    environmentVariables: [String] = [],
    at path: String = ".",
    process: Process = .init(),
    outputHandle: FileHandle? = nil,
    errorHandle: FileHandle? = nil
) async throws -> String {
    let command = "\(environmentVariables.joined(separator: " ")) \(command)"
    try echo(
        """
        Executing: \(command),
        Arguments: \(arguments),
        Environment Vars: \(environmentVariables)
        """,
        color: .yellow
    )
    
    let output = try await Command(executablePath: .init("/usr/local/bin/tuist"))
        .addArguments(arguments)
        .output
    
    print(output.stdout)
    
    return output.stdout
}

@discardableResult
public func executeShell(
    to command: ShellOutCommand,
    arguments: [String] = [],
    environmentVariables: [String] = [],
    at path: String = ".",
    process: Process = .init(),
    outputHandle: FileHandle? = nil,
    errorHandle: FileHandle? = nil
) throws -> String {
    let command = "\(environmentVariables.joined(separator: " ")) \(command.string)"
    try echo("Executing Command: \(command)", color: .yellow)
    do {
        let output = try shellOut(
            to: command,
            arguments: arguments,
            at: path,
            process: process,
            outputHandle: outputHandle,
            errorHandle: errorHandle
        )
        try echo(output)
        return output
    } catch {
        let error = error as! ShellOutError
        try echo(error.description)
        throw error
    }
}

// MARK: Tuist Commands

public extension ShellOutCommand {
    /// tuist version command
    static func tuistVersion() -> ShellOutCommand {
        tuistCommand("version")
    }
    
    /// tuist fetch command
    static func tuistFetch(verbose: Bool,
                           update: Bool = true,
                           additionalArguments: [String] = []) -> ShellOutCommand {
        /// TODO: Figure out why tuist fetch doesn't work for specific project i.e., `tuist fetch --path Projects/$APP_NAME --verbose`.
        /// This will be useful in CI to save time
        var arguments: [String] = []
        if update {
            arguments.append(CONSTANTS.TUIST_ARGS.UPDATE)
        }
        if verbose {
            arguments.append(CONSTANTS.TUIST_ARGS.VERBOSE)
        }
        return tuistCommand("\(CONSTANTS.TUIST_COMMANDS.FETCH)", arguments: arguments + additionalArguments)
    }
    
    /// tuist generate command
    static func tuistGenerate(targets: [String],
                              projectPath: String?,
                              cacheProfile: String,
                              verbose: Bool,
                              openInXcode: Bool,
                              additionalArguments: [String] = []) -> ShellOutCommand {
        var arguments: [String] = ["\(CONSTANTS.TUIST_ARGS.PROFILE) \(cacheProfile)"]
        if let projectPath = projectPath {
            arguments.append("\(CONSTANTS.TUIST_ARGS.PATH) \(projectPath)")
        } else {
            arguments.append(contentsOf: targets)
        }
        if !openInXcode {
            arguments.append(CONSTANTS.TUIST_ARGS.NO_OPEN)
        }
        if verbose {
            arguments.append(CONSTANTS.TUIST_ARGS.VERBOSE)
        }
        return tuistCommand("\(CONSTANTS.TUIST_COMMANDS.GENERATE)", arguments: arguments + additionalArguments)
    }
    
    /// tuist cache warm command
    static func tuistCacheWarm(targets: [String],
                               projectPath: String?,
                               cacheProfile: String,
                               verbose: Bool,
                               additionalArguments: [String] = []) -> ShellOutCommand {
        var arguments: [String] = ["\(CONSTANTS.TUIST_ARGS.PROFILE) \(cacheProfile)"]
        if let projectPath = projectPath {
            arguments.append("\(CONSTANTS.TUIST_ARGS.PATH) \(projectPath)")
        } else {
            arguments.append(contentsOf: targets)
        }
        if verbose {
            arguments.append(CONSTANTS.TUIST_ARGS.VERBOSE)
        }
        return tuistCommand("\(CONSTANTS.TUIST_COMMANDS.CACHE_WARM)", arguments: arguments + additionalArguments)
    }
    
    /// any tuist command
    static func tuistCommand(_ cmd: String, arguments: [String] = []) -> ShellOutCommand {
        var command = "tuist \(cmd)"
        command = command.appending(arguments: arguments, asString: false)
        return ShellOutCommand(string: command)
    }
    
    /// install tuistenv
    static func installTuistEnvironment() -> ShellOutCommand {
        curlBash(CONSTANTS.TUIST_BASH_INSTALLATION_SCRIPT_URL, arguments: ["-Ls"])
        //ShellOutCommand(string: "curl -Ls https://install.tuist.io | bash")
    }
}

extension String {
    func appending(argument: String) -> String {
        guard !argument.isEmpty else { return self }
        return "\(self) \"\(argument)\""
    }
    
    func appending(arguments: [String], asString: Bool = true) -> String {
        guard !arguments.isEmpty else { return self }
        guard asString else {
            return "\(self) \(arguments.joined(separator: " "))"
        }
        return appending(argument: arguments.joined(separator: "\" \""))
    }
    
    func shellOutCommand() -> ShellOutCommand {
        .init(string: self)
    }
}

extension Array {
    
    public func compactMap<ElementOfResult>() -> [ElementOfResult] {
        compactMap { $0 as? ElementOfResult }
    }
}
