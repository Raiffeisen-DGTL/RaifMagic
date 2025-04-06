//
//  EnvironmentKeys.swift
//  RaifMagic
//
//  Created by USOV Vasily on 13.06.2024.
//

import SwiftUI

// MARK: - Logger

struct DIKey: EnvironmentKey {
    static let defaultValue: IAppDIContainer = FatalDIContainer()
}

extension EnvironmentValues {
    var dependencyContainer: IAppDIContainer {
        get { self[DIKey.self] }
        set { self[DIKey.self] = newValue }
    }
}
