//
//  ExampleProjectService + Environment.swift
//  RaifMagic
//
//  Created by USOV Vasily on 04.03.2025.
//

import Foundation
import SwiftUI

extension ExampleProject.ProjectService: EnvironmentSupported {
    var environmentItems: [any MagicIntegration.EnvironmentItem] {
        [
            MacOsEnvironmentItem(needVersion: "15.0", allowHighVersion: true),
            XcodeEnvironmentItem(needVersion: "16.1", allowHighVersion: true),
            ExampleMiseEnvironmentItem(),
            ExampleTuistEnvironmentItem()
        ]
    }
}

// MARK: - Собственные объекты окружения

// MARK: Tuist

struct ExampleTuistEnvironmentItem: EnvironmentItem {
    var title: String = "Tuist"
    var status: Status = .unknown(description: "")
    
    // Версия туиста для установки
    // Обновление на новые версии из mise.toml происходит автоматически
    // при запуске tuist install
    private let tuistVersion = "4.43.2"
    
    func calculateStatus(_ commandExecutor: CommandExecutor, _ logger: Logger) async -> Status {
        do {
            let result = try await commandExecutor.execute(сommandWithSingleOutput: "mise list tuist")
            return if result.isEmpty {
                .error(description: "Tuist не установлен", operation: InstallOperation(title: "Установка",version: tuistVersion))
            } else { .actual }
        } catch {
            return .error(description: "Tuist не установлен", operation: InstallOperation(title: "Установка",version: tuistVersion))
        }
    }
    
    private struct InstallOperation: EnvironmentItemOperation {
        var title: String
        var version: String
        
        init(title: String, version: String) {
            self.title = title
            self.version = version
        }
        
        func operation(_ commandExecutor: CommandExecutor, _ logger: Logger) async throws(EnvironmentItemOperationError) {
            do {
                try await commandExecutor.execute(textCommand: "mise install tuist@\(version)")
            } catch {
                return
            }
        }
    }
}

// MARK: Mise

struct ExampleMiseEnvironmentItem: EnvironmentItem {
    var title: String = "Mise"
    var status: Status = .unknown(description: "")
    
    private let miseVersion = "2024.9.0"
    
    func calculateStatus(_ commandExecutor: CommandExecutor, _ logger: Logger) async -> Status {
        // Проверка установки mise
        do {
            _ = try await commandExecutor.execute(сommandWithSingleOutput: "~/.local/bin/mise --version")
        } catch {
            return .error(description: "Mise не установлен", operation: InstallOperation(title: "Установка",version: miseVersion))
        }
        
        // Проверка версии mise
        do {
            let currentVersionInfo = try await commandExecutor.execute(сommandWithSingleOutput: "mise --version").split(separator: " ")
            guard currentVersionInfo.count > 0 else {
                return .error(description: "Mise не установлен", operation: InstallOperation(title: "Установка", version: miseVersion))
            }
            return if currentVersionInfo[0] != miseVersion {
                .error(description: "Установлена неверная версия Mise. Установлена \(currentVersionInfo[0]), требуется \(miseVersion)", operation: InstallOperation(title: "Обновление", version: miseVersion))
            } else {
                .actual
            }
        } catch {
            return .error(description: "Ошибка в ходе проверки версии Mise: \(error.localizedDescription)", operation: nil)
        }
    }
    
    private struct InstallOperation: EnvironmentItemOperation {
        var title: String
        var version: String
        
        init(title: String, version: String) {
            self.title = title
            self.version = version
        }
        
        func operation(_ commandExecutor: CommandExecutor, _ logger: Logger) async throws(EnvironmentItemOperationError){
            do {
                try await commandExecutor.execute(textCommand: "export MISE_VERSION=\"v\(version)\" && curl https://mise.run | sh")
                addToZshIfNeeded("eval \"$(~/.local/bin/mise activate zsh)\"")
                addToZshIfNeeded("export PATH=$PATH:~/.local/share/mise/shims")
                addToBashIfNeeded("eval \"$(~/.local/bin/mise activate bash)\"")
                addToBashIfNeeded("export PATH=$PATH:~/.local/share/mise/shims")
            } catch {
                return
            }
        }
        
        private func addToZshIfNeeded(_ text: String) {
            guard let zshrcFileRawContent = FileManager.default.contents(atPath: NSHomeDirectory() + "/.zshrc"), let content = String(data: zshrcFileRawContent, encoding: .utf8) else {
                return
            }
            guard content.contains(text) == false else { return }
            let newContent = content + "\n\(text)\n"
            try? newContent.write(toFile: NSHomeDirectory() + "/.zshrc", atomically: true, encoding: .utf8)
        }
        
        private func addToBashIfNeeded(_ text: String) {
            if let fileRawContent = FileManager.default.contents(atPath: NSHomeDirectory() + "/.bashrc"), let content = String(data: fileRawContent, encoding: .utf8) {
                guard content.contains(text) == false else { return }
                let newContent = content + "\n\(text)\n"
                try? newContent.write(toFile: NSHomeDirectory() + "/.bashrc", atomically: true, encoding: .utf8)
            }
            if let fileRawContent = FileManager.default.contents(atPath: NSHomeDirectory() + "/.bash_profiles"), let content = String(data: fileRawContent, encoding: .utf8) {
                guard content.contains(text) == false else { return }
                let newContent = content + "\n\(text)\n"
                try? newContent.write(toFile: NSHomeDirectory() + "/.bash_profiles", atomically: true, encoding: .utf8)
            }
        }
    }
}


