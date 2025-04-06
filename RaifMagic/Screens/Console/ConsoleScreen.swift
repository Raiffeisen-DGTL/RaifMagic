//
//  ConsoleScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI

struct ConsoleScreen: MagicScreen {
    let id = "console"
    let reinitProjectHandler: () async -> Void
    
    @MainActor
    func show(data: ScreenCommonData, arguments: Any?) -> AnyView {
        AnyView(
            ConsoleView(screenMode: .full, reinitProject: reinitProjectHandler)
        )
    }
}
