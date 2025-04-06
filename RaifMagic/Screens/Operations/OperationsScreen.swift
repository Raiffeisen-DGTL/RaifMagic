//
//  OperationsScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI

struct OperationsScreen: MagicScreen {
    let id = "operations"
    let operations: [CustomActionSection]
    @MainActor
    func show(data: ScreenCommonData, arguments args: Any?) -> AnyView {
        AnyView(
            OperationsView(sections: operations)
        )
    }
}
