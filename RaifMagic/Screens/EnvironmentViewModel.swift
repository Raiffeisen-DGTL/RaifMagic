//
//  EnvironmentViewModel.swift
//  RaifMagic
//
//  Created by USOV Vasily on 10.06.2024.
//

import RaifMagicCore
import Observation
import SwiftUI

@Observable
@MainActor
final class EnvironmentViewModel {
    let console: any IConsole
    let appUpdaterService: any IAppUpdaterService
    let commandExecutor: CommandExecutor
    let logger: Logger
    
    var items: [any EnvironmentItem] = []
    var isRunningOperation = false
    
    var needUpdate: Bool {
        let itemsResult = items.filter {
            switch $0.status {
            case .error: true
            case .warning: true
            case .unknown: true
            default: false
            }
        }.isEmpty == false
        
        let appResult = {
            switch appStatus {
            case .needInstall, .needUpdate, .errorDuringChecking, .errorDuringUpdating, .errorDuringInstalling: true
            default: false
            }
        }()
        
        return itemsResult || appResult
    }
    
    var isRunningUpdatingEnvironment = false
    var isRunningCheckingEnvironment: Bool {
        [EnvironmentDependencyStatus.checkingInProgress].contains(appStatus)
    }
    var warningIndicator: Bool {
        appStatus == .needUpdate
    }
    var errorIndicator: Bool {
        [EnvironmentDependencyStatus.errorDuringChecking, .errorDuringUpdating].contains(appStatus) ||
        items.filter({ $0.status != .actual }).isEmpty == false
    }
    var appStatus: EnvironmentDependencyStatus = .waitingCheckingUpdating
    
    var appVersionRequired: AppVersionIdentifier? = nil
    
    init(
        appUpdaterService: any IAppUpdaterService,
        commandExecutor: CommandExecutor,
        console: any IConsole,
        logger: Logger
    ) {
        self.appUpdaterService = appUpdaterService
        self.console = console
        self.commandExecutor = commandExecutor
        self.logger = logger
    }

    func checkNeedUpdateEnvironment(
        minimalSupportedAppVersion: AppVersionIdentifier
    ) async {
        for index in items.indices {
            items[index].status = .waiting
        }
        appStatus = .checkingInProgress
        await checkAppGuiStatus(minimalSupportedAppVersion: minimalSupportedAppVersion)
        await checkItemsStatus()
    }
    
    private func checkItemsStatus() async {
        
        for index in items.indices {
            items[index].status = .inProgress
            items[index].status = await items[index].calculateStatus(commandExecutor, logger)
        }
    }
    
    // MARK: - Application
    
    func fetchAvailableAppVersions() async throws -> [AppVersionIdentifier]  {
        try await appUpdaterService.fetchAvailableAppVersions()
    }
    
    // TODO: replace with updateApplication (see bottom)?
    func updateApp(toVersion version: AppVersionIdentifier) async throws {
        try await appUpdaterService.updateApp(toVersion: version)
    }
    
    @MainActor
    func checkAppGuiStatus(
        minimalSupportedAppVersion: AppVersionIdentifier
    ) async {
        do {
            appVersionRequired = try await appUpdaterService.lastAvailableAppVersion(
                after: minimalSupportedAppVersion,
                comparedWith: AppConfig.appVersion
            )
            if let appVersionRequired {
                appStatus = appVersionRequired.isMajorHigher(than: AppConfig.appVersion) ? .needUpdate : .canUpdate
            } else {
                appStatus = .actualVersion
            }
        } catch {
            appStatus = .errorDuringChecking
        }
    }
    
    func updateApplication(toVersion version: AppVersionIdentifier) async {
        await console.run(work: { @MainActor [self] _ in
            do {
                appStatus = .updatingInProgress
                if let version = appVersionRequired {
                    try await appUpdaterService.updateApp(toVersion: version)
                }
                appStatus = .actualVersion
            } catch {
                appStatus = .errorDuringUpdating
                throw error
            }
        }, withTitle: "Обновление RaifMagic", outputStrategy: .all)
    }
}
