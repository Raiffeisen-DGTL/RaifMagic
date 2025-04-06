//
//  GenerationSettingsScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI

struct GenerationSettingsScreen: MagicScreen {
    let id = "generation-settings"
    @MainActor
    func show(data: ScreenCommonData, arguments args: Any?) -> AnyView {
        AnyView(
            GenerationSettings()
        )
    }
}
