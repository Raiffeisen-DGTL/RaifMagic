//
//  ProjectView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 27.05.2024.
//

import SwiftUI
import AppKit.NSColor

@MainActor
struct ProjectView: View {
    @AppStorage("notificationsOperationsEnd") private var notificationsOperationsEnd = false
    @AppStorage("useGenerateType") private var useGenerateType: GenerateType = .external
    @AppStorage("customEnvironmentControl") private var customEnvironmentControl = false
    @AppStorage("showMiniConsole") private var showMiniConsoleGlobalSetting = true
    
    @AppStorage("favoriteToggleGroups") private var favoriteGroups: [UUID] = []
    
    @State private var showWhatsNew = false
    @AppStorage("lastLoadedVersion") private var lastLoadedVersion = ""
    
    // Pass data here for navigation tosome screen
    @State private var selectedMainScreen: ProjectMainScreenDestination? = nil
    private var initialArguments: [String]
    
    @State private var mainMenuItems: [MainMenuIntegration] = []
    
    @State private var needUpdateEnvironmentAlert = false
    
    // View Models
    @State private var projectViewModel: ProjectViewModel
    @State private var environmentViewModel: EnvironmentViewModel
    @State private var consoleViewModel: ConsoleViewModel
    @State private var gitViewModel: GitViewModel
    
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) var colorScheme
    
    private var di: IAppDIContainer
    private let project: any IProject
    
    @State private var showMiniConsole: Bool = false
    @State private var miniConsoleHiddenTask: Task<Void, Error>? = nil
    
    @State private var showStopButton = false
    
    init(project: any IProject, arguments: [String], di: IAppDIContainer) {
        self.di = di
        guard let projectService = project.makeService() else { fatalError("Ошибка инициализации проекта") }
        self.project = project
        
        let consoleVM = ConsoleViewModel(executor: di.executor, logger: di.logger)
        _consoleViewModel = State(wrappedValue: consoleVM)
        
        let environmentVM = EnvironmentViewModel(appUpdaterService: di.appUpdaterService,
                                                 commandExecutor: di.executor,
                                                 console: consoleVM,
                                                 logger: di.logger)
        if let _service = projectService as? (any EnvironmentSupported) {
            environmentVM.items = _service.environmentItems
        }
        _environmentViewModel = State(wrappedValue: environmentVM)
        
        
        let gitViewModel = GitViewModel(
            projectURL: projectService.projectURL,
            logger: di.logger,
            commandExecutor: di.executor
        )
        let projectVM = ProjectViewModel(
            projectService: projectService,
            di: di
        )
        
        _projectViewModel = State(wrappedValue: projectVM)
        _gitViewModel = State(wrappedValue: gitViewModel)
        
        self.initialArguments = arguments
    }
    
    var body: some View {
        NavigationSplitView {
            navigationMenuView
                .frame(minWidth: 250)
        } detail: {
            if let destination = selectedMainScreen, let screen = mainMenuItems.first(where: { $0.screen.id == destination.screenID })?.screen {
                screen.show(data: ScreenCommonData(projectPath: projectViewModel.projectService.projectURL.path()),
                            arguments: destination.arguments)
                    .environment(\.dependencyContainer, di)
                    .environment(environmentViewModel)
                    .environment(consoleViewModel)
                    .environment(projectViewModel)
                    .environment(gitViewModel)
                    .toolbar {
                        toolbar
                    }
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .navigationTitle(headerTitle)
        .navigationSubtitle(gitViewModel.currentBranchName)
        .task {
            loadScreens()
            openInitialScreen()
            async let _ = await showWhatsNewIfNeeded()
            await initialLoading()
            
            guard let _service = projectViewModel.projectService as? (any GenerateConfigurationSupported), _service.isSupportedGenerationWithExternalConsole else {
                useGenerateType = .local
                return
            }
        }
        .onDisappear {
            gitViewModel.stopGitMonitoring()
        }
        .alert("Для генерации проекта требуется другая версия RaifMagic", isPresented: Binding(get: {
            projectViewModel.needInstallAppVersion != nil
        }, set: { _ in projectViewModel.needInstallAppVersion = nil }), presenting: projectViewModel.needInstallAppVersion, actions: { _ in
            Button {
                selectedMainScreen = .environment(destination: .raifmagicVersionManager)
            } label: {
                Text("Перейти в Менеджер версий")
            }
            Button {} label: {
                Text("Поняль")
            }
        }, message: { version in
            Text("Настройки проекта, указанные в файле .magic.conf в корне репозитория ограничивают версию RaifMagic, требуемую для генерации, на \(version.asString) или более позднюю вплоть до версии \(version.major + 1).0.0. Вам необходимо обновиться RaifMagic до актуальной версии в Менеджере версий.")
        })
        .alert("Необходимо обновить окружение, прежде чем запускать генерацию проекта", isPresented: $needUpdateEnvironmentAlert, actions: {
            Button("Перейти к разделу Обновления") {
                selectedMainScreen = .environment(destination: .raifmagicVersionManager)
            }
            Button("Отмена") {
                needUpdateEnvironmentAlert = false
            }
        })
        .animation(.default, value: consoleViewModel.isCommandRunning)
        .onChange(of: gitViewModel.currentBranchName) { oldBranch, branch in
            guard oldBranch.isEmpty == false else { return }
            Task {
                let line = ConsoleLine(item: ConsoleLineItem(content: "Текущая ветка проекта - \(branch)") )
                await consoleViewModel.addConsoleOutput(line: line)
            }
        }
        // MARK: Show WhatsNew
        .overlay(alignment: .center) {
            if showWhatsNew {
                whatsNewSmallView
            }
        }
        .animation(.default, value: showWhatsNew)
        .onChange(of: environmentViewModel.needUpdate) { _, newValue in
            mainMenuItems = mainMenuItems.map {
                if $0.id == "environment" {
                    var mutating = $0
                    mutating.icon = newValue ? .error : nil
                    return mutating
                } else {
                    return $0
                }
            }
        }
        .onChange(of: consoleViewModel.isCommandRunning) { _, newValue in
            mainMenuItems = mainMenuItems.map {
                if $0.id == "console" {
                    var mutating = $0
                    mutating.icon = newValue ? .progress : nil
                    return mutating
                } else {
                    return $0
                }
            }
        }
    }
    
    private var headerTitle: String {
        return projectViewModel.projectService.projectID + " \\ \(projectViewModel.projectService.projectURL.lastPathComponent )"
    }
    
    private func loadScreens() {
        var menuItems: [MainMenuIntegration] = []
        menuItems.append(
            MainMenuIntegration(title: "Консоль",
                                systemImage: "arcade.stick.console.fill",
                                backgroundGradientColors: [.black.opacity(0.6), .black],
                                sortIndex: 0,
                                section: .top,
                                screen: ConsoleScreen {
                                    consoleViewModel.addEmptyLine()
                                    guard project.loadConfiguration() != nil else {
                                        await consoleViewModel.addConsoleOutput(line: ConsoleLine(item: ConsoleLineItem(content: "Не удалось декодировать конфигурацию проекта в файле .magic.json. Возможно файл отсутствует или вы используете несовместимую версию RaifMagic", color: .red)))
                                        return
                                    }
                                    
                                    // Reinit of project
                                    guard let projectService = project.makeService() else {
                                        await consoleViewModel.addConsoleOutput(line: ConsoleLine(item: ConsoleLineItem(content: "Не удалось реиницализировать проект", color: .red)))
                                        return
                                    }
                                    projectViewModel.projectService = projectService
                                    if let _service = projectService as? (any EnvironmentSupported) {
                                        environmentViewModel.items = _service.environmentItems
                                    }
                                    await self.initialLoading()
                                })
        )
        
        menuItems.append(
            MainMenuIntegration(title: "Модули",
                                systemImage: "tray.full.fill",
                                backgroundGradientColors: [.cyan, .teal],
                                sortIndex: 0,
                                section: .project,
                                screen: ModulesScreen())
        )
        
        menuItems.append(
            MainMenuIntegration(title: "Настройки генерации",
                                systemImage: "arrow.triangle.branch",
                                backgroundGradientColors: [.purple, .pink],
                                sortIndex: 1,
                                section: .project,
                                screen: GenerationSettingsScreen())
                                
        )
        
        if let _service = projectViewModel.projectService as? (any QuickOperationSupported) {
            menuItems.append(
                MainMenuIntegration(title: "Операции",
                                    systemImage: "cross.case.fill",
                                    backgroundGradientColors: [.purple, .pink],
                                    sortIndex: 2,
                                    section: .project,
                                    screen: OperationsScreen(operations: _service.operations(console: consoleViewModel)))
            )
        }
        
        if let asCodeStyler = projectViewModel.projectService as? (any CodeStylerSupported) {
            menuItems.append(
                MainMenuIntegration(title: "CodeStyler",
                                    systemImage: "exclamationmark.warninglight.fill",
                                    backgroundGradientColors: [.green, .mint],
                                    sortIndex: 3,
                                    section: .project,
                                    screen: CodeStylerScreen(codeStylerService: asCodeStyler))
            )
        }
        
        if let asCodeOwners = projectViewModel.projectService as? (any CodeOwnersSupported) {
            menuItems.append(
                MainMenuIntegration(title: "CodeOwners",
                                    systemImage: "person.3.fill",
                                    backgroundGradientColors: [.green, .mint],
                                    sortIndex: 4,
                                    section: .project,
                                    screen: CodeOwnersScreen(isAdminMode: projectViewModel.projectService.isCurrentUserAdmin,
                                                             codeOwnersFilePath: asCodeOwners.codeOwnersFileAbsolutePath,
                                                             urlForEraseAddedPaths: projectViewModel.projectService.projectURL,
                                                             logger: di.logger,
                                                             developerFetcher: asCodeOwners.codeOnwersDeveloperTeamMemberInfoFetcher))
            )
        }
        
        menuItems.append(
            MainMenuIntegration(title: "Обновления",
                                systemImage: "aqi.medium",
                                backgroundGradientColors: [.orange, .red],
                                sortIndex: 0,
                                section: .environment,
                                screen: EnvironmentScreen())
        )
        
        if let asPrivacy = projectViewModel.projectService as? any SecretsSupported {
            menuItems.append(
                MainMenuIntegration(title: "Пароли и токены",
                                    systemImage: "lock.fill",
                                    backgroundGradientColors: [.indigo, .purple],
                                    sortIndex: 1,
                                    section: .environment,
                                    screen: SecretsScreen(secrets: asPrivacy.secrets, projectService: asPrivacy))
            )
        }
        
        menuItems.append(
            MainMenuIntegration(title: "Общие настройки",
                                systemImage: "gearshape.fill",
                                backgroundGradientColors: [Color.gray],
                                sortIndex: 0,
                                section: .other,
                                screen: GeneralSettingsScreen())
        )
        
        menuItems.append(
            MainMenuIntegration(title: "Поддержка",
                                systemImage: "richtext.page.fill",
                                backgroundGradientColors: [Color.gray],
                                sortIndex: 1,
                                section: .other,
                                screen: SupportScreen())
        )
        
        menuItems.append(
            MainMenuIntegration(title: "Что нового",
                                systemImage: "newspaper.fill",
                                backgroundGradientColors: [Color.gray],
                                sortIndex: 2,
                                section: .other,
                                screen: WhatsNewScreen(whatsNew: di.whatsNewStorage.whatsNew))
        )
        
        if let _service = projectViewModel.projectService as? any CustomScreenSupported {
            menuItems += _service.mainMenuIntegrations
        }
        
        mainMenuItems = menuItems
    }
    
    private func openInitialScreen() {
        guard initialArguments.count > 0 else {
            selectedMainScreen = .console()
            return
        }
        var arguments = initialArguments
        let screenName = arguments.removeFirst()
        guard let screenID = mainMenuItems.first(where: { $0.screen.id == screenName })?.screen.id else { return }
        selectedMainScreen = .init(screenID: screenID, arguments: arguments)
    }
    
    private func menuItemScreenItem(_ item: MainMenuIntegration) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(gradient: Gradient(colors: item.backgroundGradientColors), startPoint: .leading, endPoint: .topTrailing))
                .frame(width: 22, height: 22, alignment: .center)
                .overlay {
                    Image(systemName: item.systemImage)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 14, maxHeight: 14, alignment: .center)
                        .foregroundStyle(Color.white)
                }
            Text(item.title)
            
            if item.icon == .error {
                Image(systemName: "exclamationmark.triangle.fill")
                    .renderingMode(.template)
                    .foregroundStyle(.red)
            } else if item.icon == .warning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .renderingMode(.template)
                    .foregroundStyle(.yellow)
            } else if item.icon == .progress {
                ProgressView()
                    .controlSize(.small)
            }
            Spacer()
        }
        .padding(4)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .background(isSelected(screenWithID: item.screen.id) ? Color(NSColor.secondarySystemFill) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
        .onTapGesture {
            selectedMainScreen = ProjectMainScreenDestination(screenID: item.screen.id)
        }
    }
    
    private func isSelected(screenWithID: String) -> Bool {
        guard let selectedMainScreen else { return false }
        return selectedMainScreen.screenID == screenWithID
    }
    
    private func menuTitle(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .fontWeight(.semibold)
            .padding(.top, 20)
            .padding(.bottom, 4)
            .opacity(0.5)
    }
    
    private var navigationMenuView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(mainMenuItems.filter({ $0.section == .top }).sorted(by: { $0.sortIndex < $1.sortIndex })) { item in
                menuItemScreenItem(item)
            }
            
            menuTitle("Проект")
            ForEach(mainMenuItems.filter({ $0.section == .project }).sorted(by: { $0.sortIndex < $1.sortIndex })) { item in
                menuItemScreenItem(item)
            }
            
            menuTitle("Окружение")
            ForEach(mainMenuItems.filter({ $0.section == .environment }).sorted(by: { $0.sortIndex < $1.sortIndex })) { item in
                menuItemScreenItem(item)
            }
            
            menuTitle("Другое")
            ForEach(mainMenuItems.filter({ $0.section == .other }).sorted(by: { $0.sortIndex < $1.sortIndex })) { item in
                menuItemScreenItem(item)
            }
            Spacer()
            
        }
        .padding()
        .overlay(alignment: .bottom, content: {
            VStack {
                Group {
                    Text(AppConfig.appVersion.asString)
                    if AppConfig.appVersion.isBeta {
                        Text("Beta-версия для самых сильных")
                    }
                }
                .font(.caption)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
            .compositingGroup()
            .shadow(radius: 1)
        })
        .overlay(alignment: .bottom) {
            VStack(spacing: 5) {
                if showMiniConsoleGlobalSetting, selectedMainScreen?.screenID != "console", showMiniConsole {
                    ConsoleView(screenMode: .compact, reinitProject: nil)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .background(in: RoundedRectangle(cornerRadius: 10))
                        .padding(15)
                        .shadow(radius: 5)
                        .font(.system(size: 10))
                        .scrollIndicators(.hidden)
                        .transition(.move(edge: .leading))
                        .environment(consoleViewModel)
                        .environment(projectViewModel)
                }
            }
            .animation(.default, value: showMiniConsole)
            .onChange(of: environmentViewModel.isRunningCheckingEnvironment) {
                showOrHideMiniConsole()
            }
            .onChange(of: consoleViewModel.isCommandRunning) {
                showOrHideMiniConsole()
            }
            .onChange(of: consoleViewModel.needShowConsole) {
                showOrHideMiniConsole()
                consoleViewModel.needShowConsole = false
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Spacer()
                if consoleViewModel.isCommandRunning {
                    Button {
                        Task {
                            await di.logger.log(.debug, message: "Нажата кнопка досрочной остановки выполнения")
                        }
                        consoleViewModel.cancelRunning()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                    .transition(.move(edge: .trailing))
                }
                if let _service = projectViewModel.projectService as? (any GenerateConfigurationSupported) {
                    if _service.isSupportedGenerationWithExternalConsole == false {
                        runButton
                    } else {
                        Menu {
                            Button {
                                runGeneration(type: .local)
                            } label: {
                                Text("Запуск в консоли")
                            }
                            
                            Button {
                                runGeneration(type: .external)
                            } label: {
                                Text("Запуск в терминале")
                            }
                        } label: {
                            Label("Запустить генерацию", systemImage: "play.fill")
                        } primaryAction: {
                            runGeneration(type: useGenerateType)
                        }
                        .disabled(consoleViewModel.isCommandRunning || environmentViewModel.isRunningCheckingEnvironment)
                        .opacity(consoleViewModel.isCommandRunning ? 0.3 : 1)
                        .menuStyle(ButtonMenuStyle())
                    }
                } else {
                    runButton
                }
            }
        }
    }
    
    private var runButton: some View {
        Button {
            Task {
                await di.logger.log(.debug, message: "Нажата кнопка досрочной остановки выполнения")
            }
            runGeneration(type: useGenerateType)
        } label: {
            Image(systemName: "play.fill")
        }
        .disabled(consoleViewModel.isCommandRunning || environmentViewModel.isRunningCheckingEnvironment)
        .opacity(consoleViewModel.isCommandRunning ? 0.3 : 1)
        .menuStyle(ButtonMenuStyle())
    }
    
    private var whatsNewSmallView: some View {
        ZStack {
            Color.black.opacity(0.01)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            WhatsNewSmallView(showingItems: di.whatsNewStorage.whatsNew.filter({ $0.version >= AppConfig.appVersion.asString }),
                              show: $showWhatsNew)
            .compositingGroup()
            .shadow(radius: 10)
            .transition(.opacity)
        }
    }
    
    @MainActor
    private func initialLoading() async {
        try? await Task.sleep(for: .seconds(0.2))
        let startLine = ConsoleLine(item: .init(content: "Загрузка проекта \(projectViewModel.projectService.projectID) по пути \(projectViewModel.projectService.projectURL.path())"))
        await consoleViewModel.addConsoleOutput(line: startLine)
        
        // Checking RaifMagic version
        do {
            let canGenerateResult = try projectViewModel.canGenerate(withAppVersion: AppConfig.appVersion)
            switch canGenerateResult {
            case .can:
                await consoleViewModel.addConsoleOutput(content: "Данная версия RaifMagic подходит для генерации проекта", color: .green)
            case .needInstall(let appVersionIdentifier):
                await consoleViewModel.addConsoleOutput(content: "Данная версия RaifMagic не подходит для генерации проекта. Необходима версия \(appVersionIdentifier.asString) или новее", color: .red)
            }
        } catch {
            await consoleViewModel.addConsoleOutput(line: .init(item: .init(content: "Не удалось загрузить данные о требуемой версии RaifMagic из файла .magic.conf в корне проекта. Проверьте наличие файла и его синтаксис и повторите снова.", color: .red)))
        }
        
        // Modules loading
        do {
            try projectViewModel.refreshModules()
            await consoleViewModel.addConsoleOutput(content: "Данные о \(projectViewModel.modules.count) модулях успешно загружены", color: .green)
        } catch {
            await consoleViewModel.addConsoleOutput(content: "Ошибка в ходе загрузки данных о модулях - \(error.localizedDescription)", color: .red)
        }
        
        if let asPrivacy = projectViewModel.projectService as? any SecretsSupported {
            // Enable hiding private data in the logger
            di.logger.enablePrivacyContentHidding { message in
                await asPrivacy.hidePrivacyContent(from: message)
            }
        }
        
        await projectViewModel.projectService.onInitialLoading(console: consoleViewModel)
        
        // GIT integration
        if let _service = projectViewModel.projectService as? (any GitSupported), _service.gitBranchObservation {
            do {
                try await gitViewModel.updateCurrentBranch()
                try await gitViewModel.updateCurrentBranchWithMaster()
                try await gitViewModel.updateCurrentMasterWithOrigin()
                await gitViewModel.startGitMonitoring()
                await consoleViewModel.addConsoleOutput(content: "Активировано наблюдение за git", color: .green)
                await consoleViewModel.addConsoleOutput(content: "Текущая ветка - \(gitViewModel.currentBranchName)", color: .default)
            } catch {
                await consoleViewModel.addConsoleOutput(content: "Ошибка при доступе к git проекта: \(error.localizedDescription)", color: .red)
            }
        }
        
        
        await consoleViewModel.run(work: { [environmentViewModel, consoleViewModel] _ in
            await environmentViewModel.checkNeedUpdateEnvironment(minimalSupportedAppVersion: projectViewModel.projectService.minimalSupportedRaifMagicVersion)
            if await environmentViewModel.items.filter({ $0.status != .actual }).isEmpty == false {
                await consoleViewModel.addConsoleOutput(content: "Элементы окружения требуют обновления. Перейдите в раздле Обновления для получения дополнительной информации", color: .yellow)
            }
        }, withTitle: "Проверка окружения проекта", outputStrategy: .all)
    }
    
    private func showWhatsNewIfNeeded() async {
        guard lastLoadedVersion < AppConfig.appVersion.asString else { return }
        try? await Task.sleep(for: .seconds(0.5))
        showWhatsNew = true
        lastLoadedVersion = AppConfig.appVersion.asString
    }
    
    private func runGeneration(type: GenerateType) {
        Task {
            await di.logger.log(.debug, message: "Попытка запуска генерации проекта\n\tРУЧНОЕ УПРАВЛЕНИЯ ЗАВИСИМОСТЯМИ: \(customEnvironmentControl)\n\tТРЕБУЕТСЯ ОБНОВЛЕНИЕ ОКРУЖЕНИЯ: \(environmentViewModel.errorIndicator)\n\tСРЕДА ЗАПУСКА: \(type)")
        }
        if customEnvironmentControl == false, environmentViewModel.errorIndicator {
            needUpdateEnvironmentAlert = true
            return
        }
        Task {
            await projectViewModel.generateProject(generateType: type, console: consoleViewModel)
        }
    }
    
    private func showOrHideMiniConsole() {
        if environmentViewModel.isRunningCheckingEnvironment || consoleViewModel.isCommandRunning || consoleViewModel.needShowConsole {
            miniConsoleHiddenTask?.cancel()
            miniConsoleHiddenTask = nil
            showMiniConsole = true
        } else {
            miniConsoleHiddenTask = Task {
                try await Task.sleep(for: .seconds(5))
                showMiniConsole = false
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(id: "spacer") {
            HStack {
                Spacer()
            }
        }

        ToolbarItemGroup {
            VStack(spacing: 0) {
                Button {
                    Task {
                        try await di.executor.execute(textCommand: "open -a Terminal -n")
                    }
                } label: {
                    Image(systemName: "tv")
                        .padding(.horizontal, 4)
                }
                Text("Терминал")
                    .font(.footnote)
                    .padding(.top, -3)
                    .foregroundStyle(Color.secondary)
            }
            VStack(spacing: 0) {
                Button {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: projectViewModel.projectService.projectURL.path())
                } label: {
                    Image(systemName: "folder")
                        .padding(.horizontal, 4)
                }
                Text("Папка")
                    .font(.footnote)
                    .padding(.top, -3)
                    .foregroundStyle(Color.secondary)
            }
            VStack(spacing: 0) {
                Button {
                    Task {
                        try await di.executor.execute(textCommand: "open RMobile.xcworkspace", atPath: projectViewModel.projectService.projectURL.path())
                    }
                } label: {
                    Image(systemName: "shippingbox.circle.fill")
                        .padding(.horizontal, 4)
                }
                Text("Workspace")
                    .font(.footnote)
                    .padding(.top, -3)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

