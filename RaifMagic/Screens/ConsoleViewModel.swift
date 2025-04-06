//
//  ConsoleViewModel.swift
//  RaifMagic
//
//  Created by USOV Vasily on 11.06.2024.
//

import Foundation
import Observation

@Observable
@MainActor
final class ConsoleViewModel: IConsole {
    let logger: Logger
    let commandExecutor: CommandExecutor
    var output = [ConsoleLine]()
    var isCommandRunning: Bool {
        runningTasks.isEmpty == false
    }
    var needShowConsole: Bool = false
    private var runningTasks: [UUID: Task<Bool, Never>] = [:]
    
    init(executor: CommandExecutor, logger: Logger) {
        self.commandExecutor = executor
        self.logger = logger
    }
    
    func cancelRunning() {
        runningTasks.forEach { (_, task) in
            task.cancel()
        }
        runningTasks = [:]
    }
    
    /// Launching a custom job
    /// - Parameters:
    ///     - work: The job to be executed
    ///     - outputStrategy: Strategy for outputting messages to the console
    /// - Returns: Whether the execution was completed successfully. Warning (yellow output in the console) in the process is considered successful completion. I am on the screen with the list of projects
    // For the update screen inside the project there is a separate view AppVersionManager
    @discardableResult
    @MainActor
    func run(work: @Sendable @escaping (IConsole) async throws -> Void,
             withTitle title: String? = nil,
             outputStrategy: [PublishMessagesStrategy] = .all) async -> Bool {
        let id = UUID()
        let task = Task<Bool, Never> {
            if outputStrategy.contains(.emptyLinePrefix) {
                addEmptyLine()
            }
            if let title, outputStrategy.contains(.information) {
                await addConsoleOutput(line: ConsoleLine(item: .init(content: "Начало выполнения задачи \(title)")))
            }
            do {
                try await work(self)
                try Task.checkCancellation()
                if outputStrategy.contains(.information) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Выполнение задачи успешно завершено", color: .green)))
                }
                return true
            } catch is CancellationError {
                if outputStrategy.contains(.error) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Принудительное завершение выполнения задачи", color: .red)))
                }
                return false
            } catch {
                if outputStrategy.contains(.error) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Ошибка в ходе выполнения задачи", color: .red)))
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: error.localizedDescription, color: .red)))
                }
                return false
            }
        }
        runningTasks[id] = task
        let isSuccessExecuted = await task.value
        runningTasks[id] = nil
        return isSuccessExecuted
    }
    
    /// Run a custom command
    /// - Parameters:
    ///     - textCommand: Text representation of the command
    ///     - atPath: Path where the command should be executed
    ///     - withTitle: Title of command
    ///     - convertErrorToWarning: Display errors as warnings
    ///     - outputStrategy: Strategy for outputting messages to the console
    /// - Returns: Whether the execution was completed successfully. Warning (yellow output in the console) in the process is considered successful completion.
    @discardableResult
    func run(textCommand: String, 
             atPath: String? = nil,
             withTitle title: String? = nil,
             convertErrorToWarning: Bool = false,
             outputStrategy: [PublishMessagesStrategy] = .all) async -> Bool {
        let id = UUID()
        let task = Task<Bool, Never> {
            if outputStrategy.contains(.emptyLinePrefix) {
                addEmptyLine()
            }
            if let title, outputStrategy.contains(.information) {
                await addConsoleOutput(line: ConsoleLine(item: .init(content: "Начало выполнения команды \(title)")))
            }
            if outputStrategy.contains(.command) {
                await addConsoleOutput(line: ConsoleLine(item: .init(content: textCommand)))
            }
            do {
                let command = Command(textCommand, executeAtPath: atPath)
                try await commandExecutor.execute(command) { line in
                    if outputStrategy.contains(.commandOutput) {
                        await self.addConsoleOutput(line: line)
                    }
                }
                try Task.checkCancellation()
                if outputStrategy.contains(.information) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Выполнение команды завершено", color: .green)))
                }
                return true
            } catch is CancellationError {
                if outputStrategy.contains(.error) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Принудительное завершение выполнения команды", color: .red)))
                }
                return false
            } catch {
                if outputStrategy.contains(.error) {
                    let color: ConsoleLineItem.Color = convertErrorToWarning ? .yellow : .red
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Ошибка в ходе выполнения команды", color: color)))
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: error.localizedDescription, color: color)))
                }
                return false
            }
        }
        runningTasks[id] = task
        let isSuccessExecuted = await task.value
        runningTasks[id] = nil
        return isSuccessExecuted
    }
    
    /// Run a custom command
    /// - Parameters:
    ///     - command: The command to execute
    ///     - withTitle: The title to output to the console
    ///     - convertErrorToWarning: Display errors as warnings
    ///     - outputStrategy: Strategy for outputting messages to the console
    /// - Returns: Whether the execution was successful. Warning (yellow output to the console) in the process is considered successful.
    @discardableResult
    @MainActor
    func run(command: Command, 
             withTitle title: String? = nil,
             convertErrorToWarning: Bool = false,
             outputStrategy: [PublishMessagesStrategy] = .all) async -> Bool {
        let id = UUID()
        let task = Task<Bool, Never> {
            do {
                if outputStrategy.contains(.emptyLinePrefix) {
                    addEmptyLine()
                }
                if let title, outputStrategy.contains(.information) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Начало выполнения команды \(title)")))
                }
                if outputStrategy.contains(.command) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: command.asString)))
                }
                try await commandExecutor.execute(command) { line in
                    if outputStrategy.contains(.commandOutput) {
                        await self.addConsoleOutput(line: line)
                    }
                }
                try Task.checkCancellation()
                if outputStrategy.contains(.information) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Выполнение команды завершено", color: .green)))
                }
                return true
            } catch is CancellationError {
                if outputStrategy.contains(.error) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Принудительное завершение выполнения команды", color: .red)))
                }
                return false
            } catch {
                if outputStrategy.contains(.error) {
                    let color: ConsoleLineItem.Color = convertErrorToWarning ? .yellow : .red
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Ошибка в ходе выполнения команды", color: color)))
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: error.localizedDescription, color: color)))
                }
                return false
            }
        }
        runningTasks[id] = task
        let isSuccessExecuted = await task.value
        runningTasks[id] = nil
        return isSuccessExecuted
    }
    
    /// Running the scenario
    /// - Parameters:
    ///     - scenario: The scenario to be executed
    ///     - outputStrategy: The strategy for outputting messages to the console
    /// - Returns: Whether the execution was successful. Warning (yellow output in the console) in the process is considered successful.
    @discardableResult
    @MainActor
    func run(scenario: CommandScenario, 
             outputStrategy: [PublishMessagesStrategy] = .all) async -> Bool {
        let id = UUID()
        let task = Task<Bool, Never> {
            if outputStrategy.contains(.emptyLinePrefix) {
                addEmptyLine()
            }
            if let title = scenario.title {
                await addConsoleOutput(line: ConsoleLine(item: .init(content: "Начало выполнения сценария \(title)")))
            }
            for item in scenario.steps {
                do {
                    try Task.checkCancellation()
                } catch {
                    if outputStrategy.contains(.information) {
                        await addConsoleOutput(line: ConsoleLine(item: .init(content: "Принудительное завершение выполнения команды", color: .red)))
                    }
                    return false
                }
                
                if outputStrategy.contains(.command) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: item.command.asString)))
                }
                
                do {
                    try await commandExecutor.execute(item.command) { line in
                        if outputStrategy.contains(.commandOutput) {
                            await self.addConsoleOutput(line: line)
                        }
                    }
                } catch is CancellationError {
                    if outputStrategy.contains(.error) {
                        await addConsoleOutput(line: ConsoleLine(item: .init(content: "Принудительное завершение выполнения команды", color: .red)))
                    }
                    return false
                } catch where item.isRequiredSuccess == false {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: error.localizedDescription, color: .yellow)))
                    continue
                } catch {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Ошибка в ходе выполнения команды", color: .red)))
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: error.localizedDescription, color: .red)))
                    return false
                }
            }
            
            do {
                try Task.checkCancellation()
            } catch {
                if outputStrategy.contains(.error) {
                    await addConsoleOutput(line: ConsoleLine(item: .init(content: "Принудительное завершение выполнения команды", color: .red)))
                }
                return false
            }
            
            if outputStrategy.contains(.information) {
                await addConsoleOutput(line: ConsoleLine(item: .init(content: "Выполнение сценария успешно завершено", color: .green)))
            }
            return true
        }
        runningTasks[id] = task
        let isSuccessExecuted = await task.value
        runningTasks[id] = nil
        return isSuccessExecuted
    }
    
    func addEmptyLine() {
        output.append(.init(item: .init(content: "")))
    }
    func addConsoleOutput(line: ConsoleLine) async {
        let items = await line.items.asyncMap {
            // TODO: RND to need erase privacy data from console
//            let hiddenItemContent = await privacyService.hidePrivacyContent(from: $0.content)
//            return ConsoleLineItem(content: hiddenItemContent, color: $0.color)
            return ConsoleLineItem(content: $0.content, color: $0.color)
        }
        let hiddenPrivacyContentLine = ConsoleLine(items: items)
        await logger.log(.debug, message: hiddenPrivacyContentLine.asString)
        output.append(hiddenPrivacyContentLine)
        needShowConsole = true
    }
    func addConsoleOutput(lines: [ConsoleLine]) async {
        await lines.asyncForEach { line in
            await addConsoleOutput(line: line)
        }
    }
    func addConsoleOutput(content: String, color: ConsoleLineItem.Color) async {
        await addConsoleOutput(line: ConsoleLine(items: [ConsoleLineItem(content: content, color: color)]))
    }
}
