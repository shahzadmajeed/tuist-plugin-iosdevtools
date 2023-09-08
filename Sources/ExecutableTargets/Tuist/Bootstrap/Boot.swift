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
    var projectPath: String {
        guard let projectName else { return workspaceDirectory }
        return pathRelativeToWorkingDirectory("\(CONSTANTS.PROJECTS_FOLDER_NAME)/\(projectName)")
    }
    
    @Option(name: .shortAndLong, help: "Same as `projectName` use one or the other")
    var workspaceDirectory: String = "."
    
    @Option(name: .shortAndLong, help: "Targets to include in focused project. `projectName` and `targets` are both mutually exclusive and only one of them is needed. Full workspace will be generated if none is specified")
    var targets: [String] = []
    
    @Option(name: .shortAndLong, help: "Open generated project in Xcode. Disabled for CI")
    var openInXcode: Bool = true
    
    @Flag(name: .shortAndLong, help: "Enable verbose logs")
    var verbose: Bool = false
    
    // MARK: Build Actions
    
    @Flag(name: .shortAndLong, help: "Enable/disable caching")
    var enableCache: Bool = false
    
    @Flag(name: .long, help: "Cache was hit or a miss")
    var cacheHit: Bool = false
    
    @Option(name: .long, help: "Caching profile - defaults to `CIProdDebug`")
    var cacheProfile: String = "CIProdDebug"
    
    @Option(name: .shortAndLong, help: "Build configuration - defaults to `Prod-Debug`. `xcodebuild` or Tuist will use corresponding scheme for actions")
    var buildConfiguration: String = "Prod-Debug"
    
    @Option(name: .customLong("env-cache-profile"), help: "Environment variables used when `--cache-profile` is `OnDemand`. These variables are sent to tuist commands")
    var cacheProfileVariables: [String] = []
    var cacheProfileEnvironmentVariables: String {
        cacheProfileVariables.escapedEnvironmentVariablesString()
    }
    
    // MARK: Code Signing & Deployment
    
    @Option(name: .shortAndLong, help: "Master key for code signing. We will skip code signing if master key is not provided")
    var masterKey: String? = nil
    
    @Option(name: .customLong("env-target-provisioning-profile"), help: "Provisioning profiles used for each target. Use environment variable format to specify all provisioning profiles i.e., `NotificationContentExtension=NC-AppStore-Provisioning-Profile`")
    var provisioningProfilesVariables: [String] = []
    var provisioningProfilesEnvironmentVariablesForTuist: String {
        provisioningProfilesVariables
            .escapedEnvironmentVariables(keyPrefix: "TUIST_TARGET_")
            .escapedEnvironmentVariablesString()
    }
    
    
    // MARK: Run Command

    mutating func run() async throws {
        try await execute(at: workspaceDirectory) {
            /// Check Tuist is installed
            try checkTuistInstalled()
            
            /// Setup code signing
            try setupForCodeSigning()
            
            /// Prepare Xcode project
            try createXcodeProject()
            
            /// Cleanup code signing and other artifacts/files/configuration that is not needed anymore
            /// We also move code signing identity to correct path after project is generated
            try cleanup()
        }
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
        
        let codeSigningDir = pathRelativeToWorkingDirectory("\(CONSTANTS.CODE_SIGNING_DIR_TEMP)")
        if FileManager.default.directoryExists(at: codeSigningDir) {
            /// Match provisioning prfiles and format for Tuist
            let matchedProfiles = try matchProvisioningProfiles()
            
            /// Delete non-matching provisioning profiles - Tuist will fail if there are provisioning profiles that don't
            /// match `targe.configuration.mobileprovision` format so we delete those files
            try deleteNonMatchingProvisioningProfiles(matchedProfiles)
            
            /// Rename current `Code_Signing` folder to `Signing` for Tuist
            try renameCodeSingingFolder()
        } else {
            try echo("Directory \"\(codeSigningDir)\" doesn't exist or code signing is setup already...")
        }
    }
    
    func deleteExistingMasterKey() throws {
        try executeShell(
            cmd: .removeFile(
                from: pathRelativeToWorkingDirectory(CONSTANTS.MASTER_KEY_FILE_PATH)
            )
        )
    }
    
    func createNewMasterKey(_ masterKey: String) throws {
        try executeShell(
            cmd: .createFile(
                named: pathRelativeToWorkingDirectory(CONSTANTS.MASTER_KEY_FILE_PATH),
                contents: masterKey
            )
        )
    }

    func matchProvisioningProfiles() throws -> Set<String> {
        
        let profiles = provisioningProfilesVariables
            .compactMap { $0.provisioningProfile() }
        
        let codeSigningDir = pathRelativeToWorkingDirectory("\(CONSTANTS.CODE_SIGNING_DIR_TEMP)")

        var matchedProfiles: Set<String> = .init()
        for profile in profiles {
            let oldFile: String = "\(codeSigningDir)/\(profile.profile).mobileprovision"
            let newFile: String = "\(codeSigningDir)/\(profile.target).\(buildConfiguration).mobileprovision"
            try executeShell(cmd: .moveFile(from: oldFile, to: newFile, arguments: ["-i"]))
            matchedProfiles.insert(newFile)
        }
        return matchedProfiles
    }
    
    func deleteNonMatchingProvisioningProfiles(_ excludeList: Set<String>) throws {
        let codeSigningDir = pathRelativeToWorkingDirectory("\(CONSTANTS.CODE_SIGNING_DIR_TEMP)")
        try FileManager.default.deleteFiles(in: codeSigningDir, excludeList: excludeList, excludeExtensions: ["encrypted"])
    }
    
    func copySigningIdentityToCorrectProject() throws {
        let fromDir: String = pathRelativeToWorkingDirectory("\(CONSTANTS.ROOT_DERIVED_DIR)")
        let toDir: String = "\(projectPath)/\(CONSTANTS.DERIVED_FOLDER_NAME)/"
        try echo(
            """
            Copying code signing...
            From: \(fromDir)
            To: \(toDir)
            """
        )
        try executeShell(cmd: .copyFiles(from: fromDir, to: toDir))
    }
    
    func renameCodeSingingFolder() throws {
        let fromDir: String = pathRelativeToWorkingDirectory(CONSTANTS.CODE_SIGNING_DIR_TEMP)
        let toDir = pathRelativeToWorkingDirectory(CONSTANTS.CODE_SIGNING_DIR)
        try echo(
            """
            Renaming code signing folder...
            From: \(fromDir)
            To: \(toDir)
            """
        )
        try executeShell(cmd: .moveFile(from: fromDir, to: toDir))
    }
    
    func resetCodeSigningFolderChanges() throws {
        let codeSigningNewDir = pathRelativeToWorkingDirectory(CONSTANTS.CODE_SIGNING_DIR)
        let codeSigningOldDir = pathRelativeToWorkingDirectory(CONSTANTS.CODE_SIGNING_DIR_TEMP)
        /// Delete new folder
        if FileManager.default.directoryExists(at: codeSigningNewDir) {
            try executeShell(cmd: .removeFile(from: codeSigningNewDir, arguments: ["-r"]))
        }
        /// Undo old folder
        try executeShell(cmd: .gitCheckoutFolder(at: codeSigningOldDir), at: workspaceDirectory)
    }
    
    func pathRelativeToWorkingDirectory(_ component: String) -> String {
        "\(workspaceDirectory)/\(component)"
    }
}

// MARK: Private - Dependency Resolution & Project Generation

private extension Bootstrap {
    /// Note: We have 3 popular workflows for project generation
    /// 1. Generate a tuist targets focused Xcode project. In that case provide only `targets` that you want to include in generated project
    /// 2. Generate a tuist project focused Xcode project. In that case only provide `projectName` used in `Project.swift`
    /// 3. Generate a tuist workspace based Xcode project. This will genereate and include all projects specified in `Workspace.swift` file.
    ///    a. ** This is useful for integration or unit testing all the apps against changes in some shared code
    /// **NOTE**: For all 3 uses case you have to provide `workspaceDirectory` which we use to calculate relative paths
    
    func createXcodeProject() throws {
        /// Fetch dependencies
        /// TODO: Decenteralize `Dependencies.swift` for each Project to improve fetch speed and serve project specific needs
        try tuistFetch(update: true,
                       workspaceDirectory: workspaceDirectory,
                       verbose: verbose,
                       environmentVariables: [
                        cacheProfileEnvironmentVariables,
                        provisioningProfilesEnvironmentVariablesForTuist
                       ])
        
        /// Setup tuist cache. Mostly used during unit testing. Production pipelines should disable cache
        if enableCache && !cacheHit {
            try echo("Cache is enabled but it is a miss. Warming tuist cache...")
            try tuistCacheWarm(projectPath: projectPath,
                               cacheProfile: cacheProfile,
                               verbose: verbose,
                               environmentVariables: [
                                cacheProfileEnvironmentVariables,
                                provisioningProfilesEnvironmentVariablesForTuist
                               ])
        } else {
            try echo("Cache is a hit or it is disabled. Skipping caching...")
        }
        
        /// Generate Xcode project
        try tuistGenerate(targets: targets,
                          projectPath: projectPath,
                          cacheProfile: cacheProfile,
                          openInXcode: openInXcode,
                          verbose: verbose,
                          environmentVariables: [
                            cacheProfileEnvironmentVariables,
                            provisioningProfilesEnvironmentVariablesForTuist
                           ])
    }
    
    func cleanup() throws {
        /// Tuist creates code signing identity/keychain file at wrong path. Move it to correct project path
        try copySigningIdentityToCorrectProject()
        
        /// Delete current `master.key`
        try deleteExistingMasterKey()
        
        /// Reset changes to code signing folder
        try resetCodeSigningFolderChanges()
    }
}
