//
//  WhatsNewScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI

struct WhatsNewScreen: MagicScreen {
    let id = "whats-new"
    let whatsNew: [WhatsNewItem]
    @MainActor
    func show(data: ScreenCommonData, arguments args: Any?) -> AnyView {
        AnyView(
            WhatsNewView(whatsNew: whatsNew)
        )
    }
}
