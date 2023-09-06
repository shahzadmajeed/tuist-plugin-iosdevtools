import ShellOut
import ArgumentParser
import ProjectAutomation
import Foundation
@_implementationOnly import TSCUtility
//import SwiftCommand

/// This is an example of an `executableTarget` target that requires entry for `main`thread and can be used for `swift scripting`
/// Following script is implemented using `https://github.com/apple/swift-argument-parser` package which provides a way to
/// receive user input from console/command-line, parse and validate the input
///
/// Then, we use tuist's `ProjectAutomation` which provides some useful functions to invoke Tuist commands
/// Note that process invocation happens through `TSCUtility` target of `https://github.com/apple/swift-tools-support-core` package

/// Usage: Enter on command-line
/// `swift run Bootstrap -n "Sportsbook" --version`
/// `swift run tuist-bootstrap --cache-profile Release --open-in-xcode`
/// `swift run tuist-bootstrap --verbose --open-in-xcode --path-to-project path/to/project/manifest`
/// Note: if this command line plugin is also using local/pinned tuist version then make sure that the project you specify via. `--path-to-project` or `--project-name` uses same tuist version

@main
struct Bootstrap: AsyncParsableCommand {

//    static var configuration = CommandConfiguration(
//           commandName: "devtools",
//           abstract: "Tools that extend Tuist CLI to define developer workflows for iOS development",
//           subcommands: [
//               Fetch.self,          // fetch dependencies
//               Cache.self,          // cache targers
//               Codesign.self,       // setup code signing certificates & provisioning profiles
//               Generate.self,       // generate projects
//               Print.self           // print project structure, dependencies and other useful information
//           ],
//           defaultSubcommand: Version.self
//       )

    
    // MARK: Project Generation
    
    @Option(name: .shortAndLong, help: "Name of focused project. `projectName` and `targets` are both mutually exclusive and only one of them is needed. Full workspace will be generated of both are not specified.\nNote: `projectName` assumes that this tool is being used for dk-ios repo. Use `projectPath` if you are using for a different setup.")
    var projectName: String?
    @Option(name: .customLong("path-to-project"), help: "Same as `projectName` use one or the other")
    var projectPath: String?
    var computedProjectPath: String? {
        guard let projectName else { return projectPath }
        return "\(CONSTANTS.PROJECTS_FOLDER_NAME)/\(projectName)"
    }
    
    @Option(name: .shortAndLong, help: "Targets to include in focused project. `projectName` and `targets` are both mutually exclusive and only one of them is needed. Full workspace will be generated of both are not specified")
    var targets: [String] = []
    
    
    @Flag(name: .shortAndLong, help: "Open generated project in Xcode. Disabled for CI")
    var openInXcode: Bool = false
    
    @Flag(name: .shortAndLong, help: "Enable verbose logs")
    var verbose: Bool = false
    
    // MARK: Build Actions

    @Flag(name: .shortAndLong, help: "Enable/disable caching")
    var enableCache: Bool = false
    
    @Flag(name: .shortAndLong, help: "Cache was hit or a miss")
    var cacheHit: Bool = false
    
    @Option(help: "Caching profile - defaults to `CIProdDebug`")
    var cacheProfile: String = "CIProdDebug"
    
    @Option(help: "Build configuration - defaults to `Prod-Debug`. `xcodebuild` or Tuist will use corresponding scheme for actions")
    var buildConfiguration: String = "Prod-Debug"
    
    var environmentVariables: String {
        let tuistVariables = ProcessInfo
            .processInfo
            .environment
            .filter { $0.key.hasPrefix("TUIST_") }
            .map { "\($0.key)=\"\($0.value)\"" }
        return tuistVariables.joined(separator: " ")
    }
    
    // MARK: Deployment
    
    @Option(help: "Master key for code signing. We will skip code signing if master key is not provided")
    var masterKey: String? = nil
    
    @Option(help: "Mapping of all executable targets to their provisioning profiles. Use string of this format {TargetName:Provisioning_Profile}")
    var provisioningProfiles: [String] = []
    
    
    // MARK: Run Command

    mutating func run() async throws {
        /// Check Tuist is installed
        try checkTuistInstalled()
        
        /// Setup code signing
        try setupForCodeSigning()
        
        /// Prepare Xcode project
        try createXcodeProject()
    }
}

// MARK: Private - Code Signing

private extension Bootstrap {
    /// Note: Tuist code signing requires formating provisoning profiles as `target.configuration.mobileprovision` file which means
    /// we cannot pre-format all provisioning files like that because both AppStore & AppCenter use same release configuration. So, following functions
    /// will rename needed files according to Tuist format and delete other unnecessary provisioning files temporarily (this is because Tust will try to use any
    /// file on disk and throw error if the file is not following Tuist naming convention). For easier development process, we have also chosen a different name
    /// for folder that contains code signing files so that we can avoid code signing setup during development or testing workflows, although setting up
    /// code signing for deelopment might still be useful.
    func setupForCodeSigning() throws {
        guard let masterKey, !masterKey.isEmpty, masterKey != "NA" else {
            try echo("master.key not set, skipping code signing setup...")
            return
        }
        
        /// Delete current `master.key`
        try deleteExistingMasterKey()
        
        /// Create new `master.key`
        try createNewMasterKey(masterKey)
        
        /// Match provisioning prfiles and format for Tuist
        try matchProvisioningProfiles()
        
        /// Rename current `Code_Signing` folder to `Signing` for Tuist
        try renameCodeSingingFolder()
    }
    
    func deleteExistingMasterKey() throws {
        try executeShell(to: .removeFile(from: CONSTANTS.MASTER_KEY_FILE_PATH))
        //try File(path: CONSTANTS.MASTER_KEY_FILE_PATH).delete()
    }
    
    func createNewMasterKey(_ masterKey: String) throws {
        /// Note `\c` is appended to avoid a newline character in generated file
        try executeShell(to: .createFile(named: CONSTANTS.MASTER_KEY_FILE_PATH, contents: "\(masterKey)\\c"))
//        try Folder(path: CONSTANTS.TUIST_FOLDER_NAME)
//            .createFile(named: CONSTANTS.MASTER_KEY_FILE_NAME)
    }

    func matchProvisioningProfiles() throws {
        
    }
    
    func tuistFormatForProvisioningProfile(for target: String, configuration: String) -> String {
        "\(target).\(configuration).mobileprovision"
    }
    
    func renameProvisioningProfile(current: String, new: String) throws {
        try executeShell(to: .moveFile(from: current, to: new))
//        let file = try File(path: current)
//        try file.rename(to: new)
    }
    
    func renameCodeSingingFolder() throws {
        try executeShell(to: .moveFile(from: CONSTANTS.CODE_SIGNING_DIR_TEMP, to: CONSTANTS.CODE_SIGNING_DIR))
    }
}

// MARK: Private - Dependency Resolution & Project Generation

private extension Bootstrap {
    /// Note: We have 3 popular workflows for project generation
    /// 1. Generate a tuist targets focused Xcode project. In that case provide only `targets` that you want to include in generated project
    /// 2. Generate a tuist project focused Xcode project. In that case provide only provide `computedProjectPath` to `Project.swift`
    /// 3. Generate a tuist workspace based Xcode project. This will genereate and include all projects specified in `Workspace.swift` file.
    ///    ** This is useful for integration or unit testing all the apps against changes in some shared code
    func createXcodeProject() throws {
        /// Fetch dependencies
        /// TODO: Decenteralize `Dependencies.swift` for each Project to improve fetch speed and serve project specific needs
        try tuistFetch(update: true, verbose: verbose, environmentVariables: [environmentVariables])
        
        /// Setup tuist cache. Mostly used during unit testing. Production pipelines should disable cache
        if enableCache && !cacheHit {
            try echo("Cache is enabled but it is a miss. Warming tuist cache...")
            try tuistCacheWarm(projectPath: computedProjectPath,
                               cacheProfile: cacheProfile,
                               verbose: verbose,
                               environmentVariables: [environmentVariables])
        } else {
            try echo("Cache is a hit or it is disabled. Skipping caching...")
        }
        
        /// Generate Xcode project
        try tuistGenerate(targets: targets,
                          projectPath: computedProjectPath,
                          cacheProfile: cacheProfile,
                          openInXcode: openInXcode,
                          verbose: verbose,
                          environmentVariables: [environmentVariables])
    }
}
