//
//  NavigationService.swift
//  RaifMagic
//
//  Created by USOV Vasily on 05.11.2024.
//

import Foundation

final class DeeplinkService: Sendable {
    
    private let logger: Logger
    private let projectLoader: ProjectsLoader
    
    init(logger: Logger, projectLoader: ProjectsLoader) {
        self.logger = logger
        self.projectLoader = projectLoader
    }
    
    func parseURL(url: URL) throws(ServiceError) -> DeeplinkEndpoint {
        guard let host = url.host() else {
            throw ServiceError.emptyRootParameter
        }
        switch host {
        case "projectsList":
            return .projectsList
        case "project":
            guard url.pathComponents.count > 0 else {
                Task {
                    await logger.log(.debug, message: "[Deeplink Service] Попытка открыть проект провалилась, так как не передан URL проекта")
                }
                throw ServiceError.missingProjectURL
            }
            
            var components = url.pathComponents
            var lastComponents: [String] = []
            var findedProject: (any IProject)? = nil
            while components.isEmpty == false {
                var urlBasePath = components.filter({ $0 != "/"}).joined(separator: "/")
                if let first = urlBasePath.first, first != "/" {
                    urlBasePath = "/" + urlBasePath
                }
                if let last = urlBasePath.last, last != "/" {
                    urlBasePath += "/"
                }
                let url = URL(filePath: urlBasePath)
                let projects = projectLoader.loadSupportedProjects(forURL: url)
                if let first = projects.first {
                    findedProject = first
                    break
                } else {
                    lastComponents.insert(components.removeLast(), at: 0)
                }
            }
            if let project = findedProject {
                guard lastComponents.count > 0 else {
                    return .project(project, arguments: nil)
                }
                return .project(project, arguments: lastComponents)
            }
            Task {
                await logger.log(.debug, message: "[Deeplink Service] Попытка открыть проект провалилась, так как не передан неверный URL проекта")
            }
            throw ServiceError.missingProjectURL
        default:
            Task {
                await logger.log(.debug, message: "[Deeplink Service] Обработка диплинка завершилась ошибкой, так как передеан неподдерживаемый первый параметр - \(host)")
            }
            throw ServiceError.invalidRootParameter(passed: host)
        }
    }
    
    // MARK: - Errors
    
    enum ServiceError: LocalizedError {
        case emptyRootParameter
        case invalidRootParameter(passed: String)
        case missingProjectURL
        case invalidProjectURL(_ url: String)
        
        var errorDescription: String? {
            switch self {
            case .emptyRootParameter:
                "Корневой параметр пути не передан"
            case .invalidRootParameter(let passed):
                "Передан неверный корневой параметр - \(passed)"
            case .missingProjectURL:
                "Не передан путь к проекту"
            case .invalidProjectURL(let url):
                "Передан некорректный путь к проекту - \(url)"
            }
        }
    }
}
