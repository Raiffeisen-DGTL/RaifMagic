//
//  SettingsScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI

struct GeneralSettingsScreen: MagicScreen {
    let id = "generalSettings"
    @MainActor
    func show(data: ScreenCommonData, arguments args: Any?) -> AnyView {
        AnyView(
            SettingsView()
        )
    }
}
