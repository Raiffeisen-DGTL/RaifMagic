//
//  EnvironmentView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 10.06.2024.
//

import SwiftUI

struct EnvironmentView: View {
    
    @State private var showAlertAppWillBeReload = false
    @State private var showAlertXcodeneedUpdateInsideRaifMagic = false
    
    @State private var navigationPath: NavigationPath
    
    @Environment(ConsoleViewModel.self) private var consoleViewModel
    @Environment(EnvironmentViewModel.self) private var environmentViewModel
    @Environment(ProjectViewModel.self) private var projectViewModel
    @Environment(\.dependencyContainer) private var di
    @Environment(\.openURL) private var openURL
    
    init(subscreen: EnvironmentScreen.Destination?) {
        var navigationPath = NavigationPath()
        if let subscreen {
            switch subscreen {
            case .raifmagicVersionManager:
                navigationPath.append(subscreen)
            }
        }
        self._navigationPath = State(wrappedValue: navigationPath)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            HStack(spacing: 0) {
                Form {
                    Section("Приложение") {
                        DependencyView(
                            title: "RaifMagic",
                            isActionButtonDisabled: consoleViewModel.isCommandRunning || environmentViewModel.isRunningUpdatingEnvironment,
                            status: environmentViewModel.appStatus,
                            requiredVersion: environmentViewModel.appVersionRequired?.asString,
                            checkAction: {
                                await environmentViewModel.checkAppGuiStatus(
                                    minimalSupportedAppVersion: projectViewModel.projectService.minimalSupportedRaifMagicVersion
                                )
                        },
                                       updateAction: { showAlertAppWillBeReload = true })
                    }
                    Section("Окружение") {
                        ForEach(Bindable(environmentViewModel).items, id: \.wrappedValue.id) { item in
                            EnvironmentRow(item: item,
                                           didRunOperation: Bindable(environmentViewModel).isRunningOperation,
                                           executor: di.executor,
                                           logger: di.logger)
                                .disabled(environmentViewModel.isRunningOperation)
                        }
                    }
                }
                .formStyle(.grouped)
                
                AppSidebar {
                    Section("Операции") {
                        SidebarCustomOperationView(operation: CustomOperation(title: "Проверить окружение", description: "Запустить повторную проверку окружения и актуализировать данные на экране", icon: "arrow.clockwise") {
                            await environmentViewModel.checkNeedUpdateEnvironment(
                                minimalSupportedAppVersion: projectViewModel.projectService.minimalSupportedRaifMagicVersion
                            )
                            if await environmentViewModel.errorIndicator {
                                await di.notificationService.sendNotification(title: "Требуется обновление", message: "Для дальнейшей работы требуется обновить зависимости")
                            } else {
                                await di.notificationService.sendNotification(title: "Зависимости актуальны", message: "Вы можете продолжить работу, обновление не требуется")
                            }
                        })
                        .disabled(
                            consoleViewModel.isCommandRunning || environmentViewModel.isRunningCheckingEnvironment
                        )
                    }
                    
                    NavigationLink(value: EnvironmentScreen.Destination.raifmagicVersionManager) {
                        Text("Открыть менеджер версий")
                    }
                    
                    
                }
                .scrollContentBackground(.hidden)
            }
            .alert("После обновления приложение будет перезагружено. Не забудьте сделать скриншоты всех несохраненных данных", isPresented: $showAlertAppWillBeReload) {
                Button {
                    guard let version = environmentViewModel.appVersionRequired else { return }
                    Task {
                        await environmentViewModel.updateApplication(toVersion: version)
                    }
                } label: {
                    Text("Сделаль, Обновляй!")
                }
                
                Button(action: {}, label: {
                    Text("Я передумал")
                })
            }
            .onChange(of: environmentViewModel.appStatus) { _, newValue in
                if newValue == .actualVersion {
                    environmentViewModel.appVersionRequired = nil
                }
            }
            .navigationDestination(for: EnvironmentScreen.Destination.self, destination: { destination in
                AppVersionManager()
                    .navigationTitle("Менеджер версий RaifMagic")
                    .environment(environmentViewModel)
                    .environment(projectViewModel)
            })
        }
    }
}

struct EnvironmentRow: View {
    @Binding var item: any EnvironmentItem
    @Binding var didRunOperation: Bool
    let executor: CommandExecutor
    let logger: Logger
    
    @State private var isAnimated: Bool = false
    
    var body: some View {
        HStack {
            switch item.status {
            case .unknown(description: let description):
                Image(systemName: "questionmark.circle.fill")
                    .renderingMode(.template)
                    .foregroundStyle(.gray)
                title(withDescription: description)
            case .actual:
                Image(systemName: "checkmark.circle.fill")
                    .renderingMode(.template)
                    .foregroundStyle(.green)
                title(withDescription: "Установлена актуальная версия")
            case .waiting:
                Image(systemName: "ellipsis")
                    .renderingMode(.template)
                    .foregroundStyle(.gray)
                title(withDescription: "Ожидает старта")
            case .inProgress:
                animatedIcon
                title(withDescription: "Операция выполняется")
            case .warning(description: let description, operation: let operation):
                Image(systemName: "exclamationmark.triangle.fill")
                    .renderingMode(.template)
                    .foregroundStyle(.yellow)
                title(withDescription: description)
                Spacer()
                if let operation {
                    Button {
                        Task { @MainActor in
                            do {
                                item.status = .inProgress
                                try await operation.operation(executor, logger)
                                item.status = await item.calculateStatus(executor, logger)
                            } catch let error as EnvironmentItemOperationError {
                                item.status = .error(description: error.errorDescription, operation: error.operation)
                            } catch {
                                item.status = await item.calculateStatus(executor, logger)
                            }
                        }
                    } label: {
                        Text(operation.title)
                    }
                }
            case .error(description: let description, operation: let operation):
                Image(systemName: "exclamationmark.triangle.fill")
                    .renderingMode(.template)
                    .foregroundStyle(.red)
                title(withDescription: description)
                Spacer()
                if let operation {
                    Button {
                        Task { @MainActor in
                            do {
                                item.status = .inProgress
                                try await operation.operation(executor, logger)
                                item.status = await item.calculateStatus(executor, logger)
                            } catch let error as EnvironmentItemOperationError {
                                item.status = .error(description: error.errorDescription, operation: error.operation)
                            } catch {
                                item.status = await item.calculateStatus(executor, logger)
                            }
                        }
                    } label: {
                        Text(operation.title)
                    }
                }
            }
        }
    }
    
    private func title(withDescription description: String) -> some View {
        VStack(alignment: .leading) {
            Text(item.title)
            Text(description)
                .font(.callout)
                .foregroundStyle(.gray)
        }
    }
    
    private var animatedIcon: some View {
        Image(systemName: "circle.hexagonpath")
            .renderingMode(.template)
            .foregroundStyle(.gray)
            .rotationEffect(isAnimated ? Angle(degrees: 360) : Angle(degrees: 0))
            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimated)
            .onAppear {
                isAnimated = true
            }
            .onDisappear {
                isAnimated = false
            }
    }
}

// TODO: Remove view, use common logic of work with Environments Items
private struct DependencyView: View {
    let title: String
    let isActionButtonDisabled: Bool
    let status: EnvironmentDependencyStatus
    let requiredVersion: String?
    let actualWarning: String?
    let checkAction: () async -> Void
    let updateAction: (() async -> Void)?
    let installAction: (() async -> Void)?

    
    init(title: String,
         isActionButtonDisabled: Bool,
         status: EnvironmentDependencyStatus,
         requiredVersion: String? = nil,
         actualWarning: String? = nil,
         checkAction: @escaping () async -> Void,
         updateAction: (() async -> Void)? = nil,
         installAction: (() async -> Void)? = nil) {
        self.title = title
        self.isActionButtonDisabled = isActionButtonDisabled
        self.status = status
        self.requiredVersion = requiredVersion
        self.actualWarning = actualWarning
        self.checkAction = checkAction
        self.updateAction = updateAction
        self.installAction = installAction
    }
    
    @State private var isAnimated: Bool = false
    
    var body: some View {
        HStack {
            switch status {
            case .waitingCheckingUpdating:
                Image(systemName: "ellipsis")
                    .renderingMode(.template)
                    .foregroundStyle(.gray)
                title(withDescription: "Ожидает проверки")
            case .checkingInProgress:
                animatedIcon
                title(withDescription: "Проверка состояния зависимости")
            case .errorDuringChecking:
                Button {
                    Task {
                        await checkAction()
                    }
                } label: {
                    Text("Повторить")
                }
                title(withDescription: "Проверка завершилась ошибкой")
            case .actualVersion:
                Image(systemName: "checkmark.circle.fill")
                    .renderingMode(.template)
                    .foregroundStyle(.green)
                title(withDescription: "Установлена актуальная версия (\(AppConfig.appVersion.asString))")
                Spacer()
                    .disabled(isActionButtonDisabled)
            case .actualWithWarning:
                Image(systemName: "checkmark.circle.fill")
                    .renderingMode(.template)
                    .foregroundStyle(.yellow)
                title(withDescription: actualWarning ?? "")
                Spacer()
                    .disabled(isActionButtonDisabled)
            case .needInstall:
                Button {
                    Task {
                        await installAction?()
                    }
                } label: {
                    Text("Установить")
                }
                .disabled(isActionButtonDisabled)
                if let requiredVersion {
                    title(withDescription: "Требуется установка версии \(requiredVersion)")
                } else {
                    title(withDescription: "Требуется установка")
                }
            case .canUpdate:
                Button {
                    Task {
                        await updateAction?()
                    }
                } label: {
                    Text("Обновить")
                }
                .disabled(isActionButtonDisabled)
                if let requiredVersion {
                    title(withDescription: "Может быть обновлено до версии \(requiredVersion)")
                } else {
                    title(withDescription: "Может быть обновлено")
                }
            case .needUpdate:
                Button {
                    Task {
                        await updateAction?()
                    }
                } label: {
                    Text("Обновить")
                }
                .disabled(isActionButtonDisabled)
                if let requiredVersion {
                    title(withDescription: "Требуется обновление до версии \(requiredVersion)")
                } else {
                    title(withDescription: "Требуется обновление")
                }
            case .installingInProgress:
                animatedIcon
                title(withDescription: "Выполняется установка")
            case .updatingInProgress:
                animatedIcon
                title(withDescription: "Выполняется обновление")
            case .errorDuringInstalling:
                Button {
                    Task {
                        await installAction?()
                    }
                } label: {
                    Text("Повторить")
                }
                title(withDescription: "Установка завершилась ошибкой")
            case .errorDuringUpdating:
                Button {
                    Task {
                        await updateAction?()
                    }
                } label: {
                    Text("Повторить")
                }
                title(withDescription: "Обновление завершилось ошибкой")
            }
        }
    }
    
    private func title(withDescription description: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
            Text(description)
                .font(.callout)
                .foregroundStyle(.gray)
        }
    }
    
    private var animatedIcon: some View {
        Image(systemName: "circle.hexagonpath")
            .renderingMode(.template)
            .foregroundStyle(.gray)
            .rotationEffect(isAnimated ? Angle(degrees: 360) : Angle(degrees: 0))
            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimated)
            .onAppear {
                isAnimated = true
            }
            .onDisappear {
                isAnimated = false
            }
    }
    
}
