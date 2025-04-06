//
//  ExampleProjectService + CodeStyler.swift
//  RaifMagic
//
//  Created by USOV Vasily on 04.04.2025.
//

import CodeStyler

extension ExampleProject.ProjectService: CodeStylerSupported {
    var codeStylerTargetGitBranch: String {
        "master"
    }
    
    var codeStylerFilesDiffCheckers: [any CodeStyler.IFilesDiffChecker] {
        [SwiftFormatDiffChecker(swiftFormatBinaryPath: "\(self.projectURL.path())scripts/swiftformat",
                                swiftFormatRulesPath: "\(self.projectURL.path()).swiftformat",
                                projectPath: self.projectURL.path(),
                                commandExecutor: di.executor),
         ImageChecker(),
         RegexCheckerService(projectPath: self.projectURL.path())]
    }
    
    var codeStylerExcludeFilesWithNameContaints: [String] {
        ["Generated"]
    }
}
