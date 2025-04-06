//
//  ProjectView + Models.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

struct ProjectMainScreenDestination: Sendable {
    let screenID: String
    let arguments: Sendable?
    
    init(screenID: String, arguments: Sendable? = nil) {
        self.screenID = screenID
        self.arguments = arguments
    }
    
    static func console() -> Self {
        Self(screenID: "console")
    }
    
    static func environment(destination: EnvironmentScreen.Destination?) -> Self {
        var args: [String] = []
        if let destination {
            args.append(destination.rawValue)
        }
        return Self(screenID: "environment", arguments: args)
    }
}
