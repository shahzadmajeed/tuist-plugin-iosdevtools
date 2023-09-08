//
//  Extensions.swift
//  
//
//  Created by Shahzad Majeed on 9/6/23.
//

import Foundation
import ShellOut
import Rainbow

// MARK: Extensions/Workflows
/// TODO: Move following extensions to a general purpose toolkit target

public func echo(_ message: String, color: Color = .lightGreen) throws {
    /// Note: We are intentionally not using `executeShell` function because otherwise we will get stuck with a recursive calls/loop
    print(try shellOut(to: .echo(message)).applyingCodes(color))
}

public func currentDirectory() throws -> String {
    /// Note: We are intentionally not using `executeShell` function because otherwise we will get stuck with a recursive calls/loop
    try shellOut(to: .pwd())
}

public func printCurrentDirectory() throws {
    /// Note: We are intentionally not using `executeShell` function because otherwise we will get stuck with a recursive calls/loop
    try echo("Current Directory: \(try currentDirectory())", color: .lightYellow)
}

public func checkToolInstalled(_ tool: String) throws -> Bool {
    let output = try executeShell(cmd: .which(tool))
    return !output.isEmpty && output.contains(tool)
}

public func tuistVersion() throws  -> String {
    try executeShell(cmd: .tuistVersion())
}

public func installTuist() throws {
    try executeShell(cmd: .installTuistEnvironment())
}

public func checkTuistInstalled() throws {
    if try checkToolInstalled(CONSTANTS.TOOLS.TUIST) {
        try echo("Tuist \(try tuistVersion()) is installed already... Skipping installation")
    } else {
        try echo("Installing Tuist...")
        try installTuist()
        try echo("Installed version \(try tuistVersion())")
    }
}

public func tuistFetch(update: Bool,
                       workspaceDirectory: String,
                       verbose: Bool,
                       additionalArguments: [String] = [],
                       environmentVariables: [String] = []) throws {
    let command: ShellOutCommand = .tuistFetch(verbose: verbose, update: update, additionalArguments: additionalArguments)
    try executeShell(cmd: command, environmentVariables: environmentVariables, at: workspaceDirectory)
}

public func tuistGenerate(targets: [String],
                          projectPath: String?,
                          cacheProfile: String,
                          openInXcode: Bool,
                          verbose: Bool,
                          additionalArguments: [String] = [],
                          environmentVariables: [String] = []) throws {
    let command: ShellOutCommand = .tuistGenerate(targets: targets,
                                                  projectPath: projectPath,
                                                  cacheProfile: cacheProfile,
                                                  verbose: verbose,
                                                  openInXcode: openInXcode,
                                                  additionalArguments: additionalArguments)
    try executeShell(cmd: command, environmentVariables: environmentVariables)
}

public func tuistCacheWarm(targets: [String] = [],
                           projectPath: String? = nil,
                           cacheProfile: String,
                           verbose: Bool,
                           additionalArguments: [String] = [],
                           environmentVariables: [String] = []) throws {
    
    var arguments: [String] = ["\(CONSTANTS.TUIST_ARGS.PROFILE) \(cacheProfile)"]
    if let projectPath = projectPath {
        arguments.append("\(CONSTANTS.TUIST_ARGS.PATH) \(projectPath)")
    } else {
        arguments.append(contentsOf: targets)
    }
    if verbose {
        arguments.append(CONSTANTS.TUIST_ARGS.VERBOSE)
    }
        
    let command: ShellOutCommand = .tuistCacheWarm(targets: targets,
                                                   projectPath: projectPath,
                                                   cacheProfile: cacheProfile,
                                                   verbose: verbose,
                                                   additionalArguments: additionalArguments)
    try executeShell(cmd: command, environmentVariables: environmentVariables)
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
    
    /// git checkout folder
    static func gitCheckoutFolder(at path: String, arguments: [String] = ["-f"]) -> ShellOutCommand {
        CONSTANTS
            .TOOLS
            .GIT
            .appending(arguments: ["checkout"] + arguments)
            .appending(argument: path)
            .shellOutCommand()
    }
    
    /// mv files command
    static func moveFile(from originPath: String, to targetPath: String, arguments: [String] = []) -> ShellOutCommand {
        CONSTANTS
            .TOOLS
            .MV
            .appending(arguments: arguments)
            .appending(argument: originPath)
            .appending(argument: targetPath)
            .shellOutCommand()
    }
    
    /// copy files command
    static func copyFiles(from originPath: String, to targetPath: String, arguments: [String] = ["-R"]) -> ShellOutCommand {
        CONSTANTS
            .TOOLS
            .CP
            .appending(arguments: arguments)
            .appending(argument: originPath)
            .appending(argument: targetPath)
            .shellOutCommand()
    }
    
    /// pwd directory command
    static func pwd() -> ShellOutCommand {
        CONSTANTS
            .TOOLS
            .PWD
            .shellOutCommand()
    }
    
    /// change  directory command
    static func cd(to path: String) -> ShellOutCommand {
        CONSTANTS
            .TOOLS
            .CD
            .appending(argument: path)
            .shellOutCommand()
    }
    
    /// create  directory command
    static func mkdir(path: String, arguments: [String] = []) -> ShellOutCommand {
        let url = URL(fileURLWithPath: path)
        let directory = url.pathComponents.joined(separator: "/")
        print("directory: \(directory)")
        guard !FileManager.default.directoryExists(at: directory) && !arguments.contains("-p") else {
            return ShellOutCommand(string: "")
        }
        return CONSTANTS
             .TOOLS
             .MKDIR
             .appending(arguments: arguments + [directory])
             .shellOutCommand()
    }
}

public func execute(at path: String, command: () async throws -> Void) async throws {
    let currentDirectory = try executeShell(cmd: .pwd())
    try executeShell(cmd: .cd(to: path))
    try await command()
    try executeShell(cmd: .cd(to: currentDirectory))
}

@discardableResult
public func executeShell(
    cmd command: ShellOutCommand,
    arguments: [String] = [],
    environmentVariables: [String] = [],
    at path: String = ".",
    process: Process = .init(),
    outputHandle: FileHandle? = nil,
    errorHandle: FileHandle? = nil
) throws -> String {
    guard !command.string.isEmpty else { return "" }
    let command = "\(environmentVariables.joined(separator: " ")) \(command.string)"
    try echo(
        """
        Executing Command: \(command)
        Current Directory: \(try currentDirectory())
        Specified Executable Path: \(path)
        """,
        color: .lightYellow
    )
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

public extension String {
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

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    public subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

/// Environment Variables
extension String {
    struct ProvisioningProfile {
        let target: String
        let profile: String
    }
    func provisioningProfile() -> ProvisioningProfile? {
        let components: [String] = components(separatedBy: "=")
        guard let key = components[safe: 0], let value = components[safe: 1] else {
            return nil
        }
        return ProvisioningProfile(target: key, profile: value)
    }
}
extension Array where Element == String {
    
    public func escapedEnvironmentVariables(keyPrefix: String = "") -> [String] {
        compactMap { keyValuePair in
            guard let profile = keyValuePair.provisioningProfile() else {
                return nil
            }
            return "\(keyPrefix)\(profile.target)=\"\(profile.profile)\""
        }
    }
        
    public func escapedEnvironmentVariablesString() -> String {
        escapedEnvironmentVariables().joined(separator: " ")
    }
}

/// File Operations
public extension FileManager {
    func directoryExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }
        return true
    }
    
    func deleteFiles(in directory: String, excludeList: Set<String> = .init(), excludeExtensions: [String] = []) throws {
        guard let dirUrl = URL(string: directory) else { return }
        let files: [URL] = try contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        let excludedFilesList = excludeList.map { $0.replacingOccurrences(of: "file://", with: "") }
        for file in files {
            if file.isFileURL,
               !excludedFilesList.contains(file.absoluteString.replacingOccurrences(of: "file://", with: "")),
               !excludeExtensions.contains(file.pathExtension) {
                try removeItem(at: file)
                try echo("Deleted File: \(file.lastPathComponent)")
            }
        }
    }
}
