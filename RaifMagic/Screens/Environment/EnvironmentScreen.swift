//
//  EnvironmentScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI

struct EnvironmentScreen: MagicScreen {
    let id = "environment"
    @MainActor
    func show(data: ScreenCommonData, arguments args: Any?) -> AnyView {
        AnyView(
            EnvironmentView(subscreen: subscreen(fromArguments: args))
        )
    }
    
    private func subscreen(fromArguments args: Any?) -> Destination? {
        guard let _args = args as? [String], let subscreenID = _args.first else { return nil }
        return Destination(rawValue: subscreenID)
    }
    
    enum Destination: String, Codable, Identifiable {
        case raifmagicVersionManager = "version-manager"
        
        var id: String { rawValue }
    }
}
