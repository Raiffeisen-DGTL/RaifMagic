//
//  CodeOwnersScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI
import CodeOwnersSwiftUI

struct CodeOwnersScreen: MagicScreen {
    let id = "code-owners"
    let isAdminMode: Bool
    let codeOwnersFilePath: String
    let urlForEraseAddedPaths: URL
    let logger: CodeOwnersServiceLogger
    let developerFetcher: DeveloperTeamMemberInfoFetcher
    
    @MainActor
    func show(data: ScreenCommonData, arguments: Any?) -> AnyView {
        AnyView(
            CodeOwnersView(isAdminMode: isAdminMode,
                           currentUsername: NSUserName(),
                           codeOwnersFilePath: codeOwnersFilePath,
                           urlForEraseAddedPaths: urlForEraseAddedPaths,
                           logger: logger,
                           developerFetcher: developerFetcher)
        )
    }
}
