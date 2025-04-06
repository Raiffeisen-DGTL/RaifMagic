//
//  SecretsScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI

struct SecretsScreen: MagicScreen {
    let id = "secrets"
    var secrets: [any SecretValue]
    let projectService: any SecretsSupported
    @MainActor
    func show(data: ScreenCommonData, arguments args: Any?) -> AnyView {
        AnyView(
            SecretsView(secrets: secrets, projectService: projectService)
        )
    }
}
