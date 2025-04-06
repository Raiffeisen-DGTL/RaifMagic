//
//  RaifMagicApp.swift
//  RaifMagic
//
//  Created by ANPILOV Roman on 23.05.2024.
//

import SwiftUI
import AppKit

@_exported import RaifMagicCore
@_exported import CodeOwners
@_exported import CodeOwnersSwiftUI
@_exported import MagicDesign
@_exported import CommandExecutor
@_exported import MagicIntegration
@_exported import CodeStyler

@main
struct RaifMagicApp: App {
    
    static let logger = Logger(useLogIntoConsole: resolve(debug: true, release: false),
                               useLogIntoOsLog: true,
                               useLogIntoFileWithDirectoryPath: AppConfig.temporaryDirectory,
                               levels: [.debug, .warning])

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Loads once and is an indication that the process has just been opened (the first window/tab is open)
    @State private var di: IAppDIContainer? = nil
    
    /// Default window width for initial load
    @AppStorage("windowDefaultWidth") var defaultWidth: Double = 900
    /// Default window height for initial load
    @AppStorage("windowDefaultHeight") var defaultHeight: Double = 450

    var body: some Scene {
        WindowGroup(id: "projectWindow") {
            WindowView(di: $di, logger: Self.logger)
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEndLiveResizeNotification)) { notification in
                    if let window = notification.object as? NSWindow {
                        defaultWidth = window.frame.width
                        defaultHeight = window.frame.height
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true)) 
        .defaultSize(.init(width: defaultWidth, height: defaultHeight))
        .windowResizability(.contentSize)
    }
    
    struct WindowView: View {
        @State private var loadingDidFinish: Bool = false
        @State private var initialOpen: Bool = true
        @State var selectedProject: (any IProject)? = nil
        @State var arguments: [String]? = nil
        @Binding var di: IAppDIContainer?
        let logger: Logger
        
        @State private var splashDidFinishLoading: Bool = false

        @AppStorage("projectURLs") private var projectURLs: [URL] = []
        
        var body: some View {
            VStack {
                if loadingDidFinish == false {
                    LoaderView(loadingDidFinish: $loadingDidFinish, di: $di, logger: logger)
                        .onOpenURL { url in
                            Task {
                                await logger.log(.debug, message: "Открытие по диплинку \(url.absoluteString)")
                            }
                            do {
                                guard url.host() != nil else {
                                    throw DeeplinkService.ServiceError.emptyRootParameter
                                }
                                guard let di else { return }
                                let deeplinkService = DeeplinkService(logger: logger, projectLoader: di.projectsLoader)
                                switch try deeplinkService.parseURL(url: url) {
                                case .projectsList:
                                    Task {
                                        await di.logger.log(.debug, message: "Будет открыт Список проектов")
                                    }
                                    break
                                case let .project(project, arguments: arguments):
                                    Task {
                                        await di.logger.log(.debug, message: "Будет открыт проект \(project.projectID), путь: \(project.url.path), аргументы - \(String(describing: arguments))")
                                    }
                                    self.arguments = arguments
                                    if projectURLs.contains(project.url) == false {
                                        projectURLs.append(project.url)
                                    }
                                    selectedProject = project
                                }
                            } catch DeeplinkService.ServiceError.emptyRootParameter {
                                Task {
                                    await logger.log(.debug, message: "Deeplink не может быть обработан, так как отсутствует корневой параметр")
                                }
                            } catch {
                                Task {
                                    await logger.log(.debug, message: "Ошибка в ходе открытия Deeplink: \(error)")
                                }
                            }
                        }
                } else if let di {
                    if let selectedProject = selectedProject {
                        ProjectView(project: selectedProject,
                                    arguments: arguments ?? [],
                                    di: di)
                        .onAppear {
                            showTabBar()
                        }
                    } else {
                        ProjectsListMainView(projectURLs: $projectURLs,
                                             arguments: $arguments,
                                             selectedProject: $selectedProject,
                                             forceOpenProjectList: !initialOpen,
                                             di: di)
                    }
                }
            }
            .onAppear {
                initialOpen = (di == nil)
            }
        }
        
        private func showTabBar() {
            NSApplication.shared.windows.forEach { window in
                if let tabGroup = window.tabGroup, tabGroup.isTabBarVisible == false {
                    window.toggleTabBar(nil)
                }
            }
        }
    }
}
