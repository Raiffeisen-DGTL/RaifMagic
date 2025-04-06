//
//  RMobileProjectService.swift
//  RaifMagic
//
//  Created by USOV Vasily on 12.02.2025.
//

import SwiftUI

extension ExampleProject {
    
    final class ProjectService: IProjectService, Sendable {
        let di: ProjectIntegrationDIContainer
        let configuration: any IProjectConfiguration
        let projectID: String
        let projectURL: URL
        let minimalSupportedRaifMagicVersion: RaifMagicCore.AppVersionIdentifier
        
        init(di: ProjectIntegrationDIContainer,
             projectURL: URL,
             configuration: ExampleProject.Configuration) {
            self.di = di
            self.configuration = configuration
            self.projectID = configuration.projectID
            self.projectURL = projectURL
            self.minimalSupportedRaifMagicVersion = configuration.minimalSupportedRaifMagicVersion
        }
        
        func fetchProjectModules() throws -> [any IProjectModule] {
            // Parse here filesystem/Packege.swift etc to get modules and show in UI
            
            [
                ExampleProject.MonorepositoryModule(name: "Module 1",
                                                    url: URL(filePath: "/")!,
                                                    target: .target1),
                ExampleProject.MonorepositoryModule(name: "Module 2",
                                                    url: URL(filePath: "/")!,
                                                    target: .target2),
                ExampleProject.LocalSpmPackage(name: "Module 3",
                                               url: URL(filePath: "/")!,
                                               target: .target1),
                ExampleProject.LocalSpmPackage(name: "Module 4",
                                               url: URL(filePath: "/")!,
                                               target: .target2),
                ExampleProject.RemoteSpmPackage(name: "Module 5",
                                                url: URL(filePath: "/")!,
                                                version: "1.0.0",
                                               target: .target1),
                ExampleProject.RemoteSpmPackage(name: "Module 6",
                                                url: URL(filePath: "/")!,
                                                version: "1.0.0",
                                               target: .target2),
            ]
        }
        
        func generationScenario() -> CommandScenario {
            var scenario = CommandScenario(title: "Генерация проекта \(configuration.projectID)")
            if AppStorage(wrappedValue: false, "ExampleProject_needCloseXcode").wrappedValue {
                scenario.add(command: "kill $(ps aux | grep 'Xcode' | awk '{print $2}')".asCommand, isRequiredSuccess: false)
                scenario.add(command: "kill -9 $(ps aux | grep 'Xcode' | awk '{print $2}')".asCommand, isRequiredSuccess: false)
                scenario.add(command: "killall -9 \"Xcode\"".asCommand, isRequiredSuccess: false)
            }
            
            if AppStorage(wrappedValue: false, "ExampleProject_removeDerivedData").wrappedValue {
                scenario.add(command: Command("rm -Rf ~/Library/Developer/Xcode/DerivedData/*", executeAtPath: projectURL.path()),
                             isRequiredSuccess: false)
            }
            scenario.add(command: Command("magic generate-toggles", executeAtPath: projectURL.path()))
            scenario.add(command: Command("git config --global filter.lfs.required false"))
            scenario.add(command: Command("tuist install", executeAtPath: projectURL.path()))
            if AppStorage(wrappedValue: false, "ExampleProject_openXcodeWorkspaceAfterSuccessGeneration").wrappedValue {
                scenario.add(command: Command("tuist generate", executeAtPath: projectURL.path()))
            } else {
                scenario.add(command: Command("tuist generate --no-open", executeAtPath: projectURL.path()))
            }
            
            return scenario
        }
        
        @MainActor
        func onInitialLoading(console: IConsole) async -> Void {
            do {
                await console.addConsoleOutput(content: "Данные успешно загружены", color: .green)
            } catch {
                await console.addConsoleOutput(content: "Ошибка в ходе загрузки паролей и токенов - \(error.localizedDescription)", color: .red)
            }
        }
        
        var isCurrentUserAdmin: Bool {
            ["ruauov1", "ruaapr3", "ruashkj"].contains(NSUserName())
        }
    }
}
