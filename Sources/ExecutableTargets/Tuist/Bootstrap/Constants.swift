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
        static let CURL: String = "curl"
        static let ECHO: String = "echo"
        static let TUIST: String = "tuist"
        static let WHICH: String = "which"
    }
    
    enum TUIST_COMMANDS {
        static let FETCH: String = "fetch"
        static let GENERATE: String = "generate"
        static let CACHE_WARM: String = "cache warm"
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
    static let TUIST_BASH_INSTALLATION_SCRIPT_URL="https://install.tuist.io"
}
