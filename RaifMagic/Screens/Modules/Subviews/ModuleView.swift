//
//  ModuleScreen.swift
//  RaifMagic
//
//  Created by ANPILOV Roman on 09.07.2024.
//

import SwiftUI

struct ModuleView: View {
    @Binding var module: any IProjectModule
    let projectService: any ModuleScreenSupported
    
    @Environment(ConsoleViewModel.self) private var consoleViewModel
    @Environment(\.dependencyContainer) private var di
    
    var body: some View {
        HStack {
            Form {
                Section {
                    Text(module.name)
                        .font(.title)
                }
                
                if let additionalView = projectService.moduleScreenAdditionalView(module: $module) {
                    additionalView
                }
                
                if let _service = projectService as? (any CodeOwnersSupported), let codeOwnersSupportedModule = module as? ProjectModule.CodeOwnersSupported {
                    CodeOwnersURLView(url: codeOwnersSupportedModule.url,
                                      codeOwnersFilePath: _service.codeOwnersFileAbsolutePath,
                                      logger: di.logger,
                                      developerFetcher: _service.codeOnwersDeveloperTeamMemberInfoFetcher)
                }

            }
            .formStyle(.grouped)
            
            if let sections = projectService.moduleScreenAdditionalOperations(module: module, console: consoleViewModel) {
                AppSidebar {
                    ForEach(sections) { section in
                        SidebarSectionView(section: section)

                    }
                }
            }
        }
        .onAppear {
            di.analyticsService.log(event: .openScreen(name: "pod_screen", additionalData: ["pod_name" : module.name]))
        }
    }
}
