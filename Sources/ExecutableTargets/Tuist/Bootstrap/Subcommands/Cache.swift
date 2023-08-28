//
//  Cache.swift
//
//
//  Created by Shahzad Majeed on 8/28/23.
//

import ArgumentParser

import Foundation

extension MainCommand {
    
    struct Cache: AsyncParsableCommand {
        
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
            
        }
    }
}
