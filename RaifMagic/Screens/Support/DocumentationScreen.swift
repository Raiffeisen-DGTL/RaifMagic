//
//  DocumentationScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI

struct SupportScreen: MagicScreen {
    let id = "support"
    @MainActor
    func show(data: ScreenCommonData, arguments args: Any?) -> AnyView {
        AnyView(
            DocumentationView()
        )
    }
}
