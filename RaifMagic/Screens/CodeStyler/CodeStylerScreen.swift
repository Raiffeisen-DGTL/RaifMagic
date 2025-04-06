//
//  CodeStylerScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.03.2025.
//

import SwiftUI
import CodeStylerSwiftUI

struct CodeStylerScreen: MagicScreen {
    
    let id = "code-styler"
    let codeStylerService: any CodeStylerSupported
    
    @MainActor
    func show(data: ScreenCommonData, arguments args: Any?) -> AnyView {
        AnyView(
            WrappedView(arguments: args, codeStylerService: codeStylerService)
        )
    }
    
    private struct WrappedView: View {
        
        @Environment(\.dependencyContainer) private var di
        @Environment(ProjectViewModel.self) private var projectViewModel
        
        let arguments: Any?
        let codeStylerService: any CodeStylerSupported
        
        var body: some View {
            CodeStylerView(projectPath: projectViewModel.projectService.projectURL.path(),
                           openCFPortReceiverWithPortID: needOpenPortWithID(fromArguments: arguments),
                           targetGitBranch: codeStylerService.codeStylerTargetGitBranch,
                           filesDiffCheckers: codeStylerService.codeStylerFilesDiffCheckers,
                           excludeFilesWithNameContaints: codeStylerService.codeStylerExcludeFilesWithNameContaints,
                           commandExecutor: di.executor,
                           logger: di.logger)
        }
        
        private func needOpenPortWithID(fromArguments args: Any?) -> String? {
            guard let _args = args as? [String],
                    _args.count == 2,
                    let openCFPortFlag = _args.first,
                    openCFPortFlag == "open-cf-port",
                    let cfPortID = _args.last else
            { return nil }
            
            return cfPortID
        }
    }
}
