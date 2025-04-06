//
//  RMobileProject.swift
//  RaifMagic
//
//  Created by USOV Vasily on 13.02.2025.
//

import Foundation

/// Namespace для интеграции RaiffeisenOnline (RMobile + RInvest)
struct ExampleProject: IProject {
    typealias Configuration = ExampleProject.ProjectConfiguration
    typealias Service = ExampleProject.ProjectService
    
    let projectID: String = "Example"
    let description: String = "Example of integration"
    let url: URL
    let di: ProjectIntegrationDIContainer
    
    init(url: URL, di: ProjectIntegrationDIContainer) {
        self.url = url
        self.di = di
    }
}
