//
//  Models.swift
//  RaifMagic
//
//  Created by USOV Vasily on 03.10.2024.
//

import SwiftUI

struct ModulesScreen: MagicScreen {
    let id = "modules"
    @MainActor
    func show(data: ScreenCommonData, arguments args: Any?) -> AnyView {
        AnyView(
            ModulesTableView()
        )
    }
    
    enum Endpoint: Hashable {
        static func == (lhs: ModulesScreen.Endpoint, rhs: ModulesScreen.Endpoint) -> Bool {
            false
        }
        
        case moduleScreen(moduleName: String, projectService: any ModuleScreenSupported)
        
        var hashValue: Int {
            switch self {
            case .moduleScreen:
                return 1
            }
        }
    }
}
