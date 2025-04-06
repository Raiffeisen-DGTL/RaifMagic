//
//  GitViewModel.swift
//  RaifMagic
//
//  Created by ANPILOV Roman on 30.01.2025.
//

import Foundation
import Observation

@Observable
@MainActor
final class GitViewModel {
    private let logger: Logger
    private let commandExecutor: CommandExecutor
    
    private let projectURL: URL
    
    private var fileHandlerGitHead: FileHandle?
    private var fileDescriptor: CInt = -1
    private var sourceGitHead: (any DispatchSourceFileSystemObject)?
    
    var currentBranchName: String = ""
    var isMasterActualToOrigin: Bool = false
    var isCurrentBranchActualToLocalMaster: Bool = false
    
    init(projectURL: URL, logger: Logger, commandExecutor: CommandExecutor) {
        self.projectURL = projectURL
        self.logger = logger
        self.commandExecutor = commandExecutor
    }

    func startGitMonitoring() async {
        do {
            let branchFileUrl = projectURL.appending(path: ".git/HEAD")
            let branchFileHandler = try FileHandle(forReadingFrom: branchFileUrl)
            let branchDescriptor = branchFileHandler.fileDescriptor
            
            let branchSource = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: branchDescriptor, eventMask: .all, queue: .main
            )
            branchSource.setEventHandler { [weak self] in
                guard let event = self?.sourceGitHead?.data, event != .attrib else {
                    return
                }
                Task {
                    try await self?.updateCurrentBranch()
                    try await self?.updateCurrentBranchWithMaster()
                    try await self?.updateCurrentMasterWithOrigin()
                    self?.stopGitMonitoring()
                    try await Task.sleep(for: .seconds(0.3))
                    await self?.startGitMonitoring()
                }
            }
            branchSource.setCancelHandler { [weak self] in
                try? self?.fileHandlerGitHead?.close()
            }
            branchSource.resume()
            self.sourceGitHead = branchSource
            self.fileHandlerGitHead = branchFileHandler
            self.fileDescriptor = fileDescriptor
        } catch {
            Task {
                await logger.log(.warning, message: "Не удается создать наблюдателя за файлом .git/HEAD")
            }
        }
    }
    
    func stopGitMonitoring() {
        sourceGitHead?.cancel()
        fileHandlerGitHead = nil
        sourceGitHead = nil
    }
    
    func updateCurrentMasterWithOrigin() async throws {
        let result = try await self.commandExecutor.execute(
            сommandWithSingleOutput:
            "git fetch -q && git rev-list --count HEAD ^origin/master | grep -q '^0$' && echo true || echo false",
            atPath: projectURL.path()
        )
        isMasterActualToOrigin = result == "true"
    }
    
    func updateCurrentBranchWithMaster() async throws {
        let result = try await self.commandExecutor.execute(
            сommandWithSingleOutput: "git merge-base --is-ancestor master HEAD && echo true || echo false",
            atPath: projectURL.path()
        )
        isCurrentBranchActualToLocalMaster = result == "true"
    }
    
    func updateCurrentBranch() async throws {
        guard let branch = try? await self.commandExecutor.execute(
            сommandWithSingleOutput: "git symbolic-ref --short -q HEAD",
            atPath: projectURL.path()
        ) else {
            currentBranchName = try await self.commandExecutor.execute(
                сommandWithSingleOutput: "git rev-parse HEAD",
                atPath: projectURL.path()
                )
            return
        }
        currentBranchName = branch
    }
}
