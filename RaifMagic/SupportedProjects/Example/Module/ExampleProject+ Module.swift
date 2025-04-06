//
//  ExampleProject.swift
//  RaifMagic
//
//  Created by USOV Vasily on 12.02.2025.
//

import Foundation

// In Modules models ypu can create any properties and method
// Later you will can use this properties and method into Integration

extension ExampleProject {
    
    /// Base protocol for all module types
    protocol Module: IProjectModule, ProjectModule.DisplayConfigurationSupported {
        var url: URL  { get }
        var target: ExampleProject.Target  { get }
    }
    
    struct MonorepositoryModule: Module, ProjectModule.CodeOwnersSupported, Hashable {
        var id: Int {
            hashValue
        }
        var name: String
        var url: URL
        var target: ExampleProject.Target
        var tableItemDescription: String? {
            "Monorepositore"
        }
    }
    
    struct LocalSpmPackage: Module, Hashable {
        var id: Int {
            hashValue
        }
        var name: String
        var url: URL
        var target: ExampleProject.Target
        var tableItemDescription: String? {
            "Local SPM"
        }
    }
    
    struct RemoteSpmPackage: Module, Hashable {
        var id: Int {
            hashValue
        }
        var name: String
        var url: URL
        var version: String
        var target: ExampleProject.Target
        var tableItemDescription: String? {
            "Remote SPM"
        }
    }
    
    enum Target {
        case target1
        case target2
    }
}

