//
//  CacheViewModel.swift
//  RaifMagic
//
//  Created by USOV Vasily on 09.07.2024.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class ProjectViewModel {
    
    // MARK: Navigation
    
    var projectScreens: [any MagicScreen] = []
    
    // MARK: Services
    
    let executor: CommandExecutor
    let logger: Logger
    let notificationService: NotificationService
    let analyticsService: IAnalyticsService
    let appUpdaterService: any IAppUpdaterService
    
    // MARK: SubViewModels
    
    var needInstallAppVersion: AppVersionIdentifier? = nil

    var projectService: any IProjectService
    var modules: [any IProjectModule] = []
    var erasedModules: [AnyWrappedModule] {
        modules.map { .init(module: $0) }
    }
    
    var filters: [FilterSection]
    
    init(
        projectService: any IProjectService,
        di: IAppDIContainer
    ) {
        self.projectService = projectService
        self.executor = di.executor
        self.logger = di.logger
        self.notificationService = di.notificationService
        self.appUpdaterService = di.appUpdaterService
        self.analyticsService = di.analyticsService
        
        filters = if let _service = projectService as? (any ModulesFilterSupported) {
            _service.initialModulesFilterSections
        } else { [] }
    }
    
    func refreshModules() throws {
        modules = try projectService.fetchProjectModules()
        print(modules)
    }
    
    // MARK: - Project Generation
    
    func generationScenario() -> CommandScenario {
        projectService.generationScenario()
    }
    
    func canGenerate(withAppVersion appVersion: AppVersionIdentifier) throws -> VerifyGenerationResult {
        let projectMinimalVersion = projectService.minimalSupportedRaifMagicVersion
        guard canGenerate(project: projectMinimalVersion, app: appVersion) else {
            return .needInstall(projectMinimalVersion)
        }
        return .can
        
        func canGenerate(project: AppVersionIdentifier, app: AppVersionIdentifier) -> Bool {
            app == project || app.isMinorHigher(than: project) || app.isPatchHigher(than: project)
        }
    }
    
    func generateProject(generateType: GenerateType, console: IConsole) async {
        do {
            switch try canGenerate(withAppVersion: AppConfig.appVersion) {
            case .can:
                let scenario = generationScenario()
                await runGeneration(generateType: generateType, scenario: scenario, console: console)
            case let .needInstall(version):
                needInstallAppVersion = version
            }
        } catch {
            Task {
                await logger.log(.debug, message: "Ошибка в процессе проверки минимальной поддерживаемой версии RaifMagic. \(error.localizedDescription)")
            }
            await console.addConsoleOutput(line: ConsoleLine(item: .init(content: "Ошибка при попытке запуска генерации - \(error)", color: .red)))
        }
    }
    
    private func runGeneration(generateType: GenerateType,
                               scenario: CommandScenario,
                               console: IConsole) async {
        switch generateType {
        case .external:
            if await generateWithExternalConsole(scenario, console: console) {
                await console.addConsoleOutput(line: ConsoleLine(item: .init(content: "Скрипт генерации успешно запущен во внешнем терминале", color: .green)))
            } else {
                await console.addConsoleOutput(line: ConsoleLine(item: .init(content: "Ошибка в ходе запуска скрипта генерации во внешнем терминале", color: .red)))
            }
        case .local:
            let startAt = Date()
            if await console.run(scenario: scenario, outputStrategy: .all) {
                notificationService.sendNotification(title: "Успех", message: "Генерация завершилась успешно")
                analyticsService.log(event: .endGeneration(duration: Date().timeIntervalSince(startAt)))
            } else {
                notificationService.sendNotification(title: "Ошибка", message: "Генерация завершилась с ошибкой")
                analyticsService.log(event: .failureGeneration)
            }
        }
    }
    
    // Start generation of RO in external terminal
    // Returns information about whether the generation task was started in external terminal
    private func generateWithExternalConsole(_ scenario: CommandScenario, console: IConsole) async -> Bool {
        await console.addConsoleOutput(line: ConsoleLine(item: .init(content: "Подготовка к запуску сценария \(scenario.title ?? "") во внешнем терминале")))

        let scriptPath: String
        do {
            scriptPath = try scenario.saveAsExecutableFile(path: AppConfig.temporaryDirectory)
        } catch {
            await console.addConsoleOutput(line: ConsoleLine(item: .init(content: error.localizedDescription, color: .red)))
            return false
        }
        
        let openCommand = Command("open -a Terminal \"\(scriptPath)\"")
        let isSuccessExecuted = await console.run(command: openCommand, withTitle: nil, convertErrorToWarning: false, outputStrategy: .all)
        return isSuccessExecuted
    }
    
    // MARK: - Subtypes
    
    enum VerifyGenerationResult: Equatable {
        case can
        case needInstall(AppVersionIdentifier)
    }
}
