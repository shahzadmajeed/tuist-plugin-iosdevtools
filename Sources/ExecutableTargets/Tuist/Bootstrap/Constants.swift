//
//  Constants.swift
//  
//
//  Created by Shahzad Majeed on 9/5/23.
//

enum CONSTANTS {
    
    enum TOOLS {
        static let LS: String = "ls"
        static let CD: String = "cd"
        static let CP: String = "cp"
        static let MV: String = "mv"
        static let PWD: String = "pwd"
        static let GIT: String = "git"
        static let CURL: String = "curl"
        static let ECHO: String = "echo"
        static let TUIST: String = "tuist"
        static let MKDIR: String = "mkdir"
        static let WHICH: String = "which"
    }
    
    enum TUIST_COMMANDS {
        /// Project management & testing
        static let INIT: String = "init"
        static let EDIT: String = "edit"
        static let RUN: String = "run"
        static let TEST: String = "test"
        static let BUILD: String = "build"
        static let CLEAN: String = "clean"
        static let FETCH: String = "fetch"
        static let GENERATE: String = "generate"
        
        /// Build cache
        static let CACHE: String = "cache"
        static let CACHE_WARM: String = "\(CACHE) warm"
        static let CACHE_PRINT_HASHES: String = "\(CACHE) print-hashes"
        static let CLOUD: String = "cloud"

        /// Dependency graph
        static let GRAPH: String = "graph"
        static let DUMP: String = "dump"
                
        /// Plugins support
        static let PLUGIN: String = "plugin"
        static let PLUGIN_BUILD: String = "\(PLUGIN) build"
        static let PLUGIN_RUN: String = "\(PLUGIN) run"
        static let PLUGIN_TEST: String = "\(PLUGIN) test"
        static let PLUGIN_ARCHIVE: String = "\(PLUGIN) archive"
        
        /// Custom templates & code generation
        static let SCAFFOLD: String = "scaffold"
        
        /// Code signing
        static let SIGNING: String = "signing"
        
        /// Code migration
        static let MIGRATION: String = "migration"
        
        /// Tool environment
        static let LOCAL: String = "local"
        static let BUNDLE: String = "bundle"
        static let UPDATE: String = "update"
        static let INSTALL: String = "install"
        static let UNINSTALL: String = "uninstall"
        static let ENV_VERSION: String = "envversion"
        static let VERSION: String = "version"
    }
    
    enum TUIST_ARGS {
        static let PATH: String = "--path"
        static let UPDATE: String = "--update"
        static let VERBOSE: String = "--verbose"
        static let PROFILE: String = "--profile"
        static let NO_OPEN: String = "--no-open"
    }
    
    static let TUIST_FOLDER_NAME: String = "Tuist"
    static let MASTER_KEY_FILE_NAME: String = "master.key"
    static let MASTER_KEY_FILE_PATH: String = "\(TUIST_FOLDER_NAME)/\(MASTER_KEY_FILE_NAME)"
    static let CODE_SIGNING_DIR_TEMP="\(TUIST_FOLDER_NAME)/Code_Signing"
    static let CODE_SIGNING_DIR="\(TUIST_FOLDER_NAME)/Signing"
    static let PROJECTS_FOLDER_NAME: String = "Projects"
    static let DERIVED_FOLDER_NAME: String = "Derived"
    static let ROOT_DERIVED_DIR: String = "\(DERIVED_FOLDER_NAME)/."
    static let TUIST_BASH_INSTALLATION_SCRIPT_URL="https://install.tuist.io"
}
