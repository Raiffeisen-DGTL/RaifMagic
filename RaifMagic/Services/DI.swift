protocol IAppDIContainer: Sendable {
    /// Application logger
    var logger: Logger { get }
    /// Parser/loader of projects
    var projectsLoader: ProjectsLoader { get }
    /// Executor of shell commands
    var executor: CommandExecutor { get }
    /// Service for work with macOS notifications
    var notificationService: NotificationService { get }
    /// Сервис для раюбоыт с окружением
    var appUpdaterService: IAppUpdaterService { get }
    // TODO: Remove from DI. Refactor WhatsNew data source
    var whatsNewStorage: WhatsNewStorage { get }
    /// Service for working with analytics
    var analyticsService: IAnalyticsService { get }
}

final class AppDIContainer: IAppDIContainer {
    let logger: Logger
    let projectsLoader: ProjectsLoader
    let executor: CommandExecutor
    let notificationService: NotificationService
    let appUpdaterService: IAppUpdaterService
    let whatsNewStorage: WhatsNewStorage
    let analyticsService: IAnalyticsService
    
    init(logger: Logger) {
        self.logger = logger
        let executor = CommandExecutor(logger: logger)
        self.executor = executor
        
        self.projectsLoader = ProjectsLoader(di: ProjectIntegrationDIContainer(logger: logger,
                                                                               executor: executor),
                                             supportedProjects: [ExampleProject.self])
        
        let _appUpdaterService = JFrogAppUpdaterService(logger: logger,
                                                        commandExecutor: executor,
                                                        artifactoryRepoPath: "JFROG_ARTIFACTORY_URL")
        notificationService = NotificationService()
        notificationService.configure()
        self.appUpdaterService = _appUpdaterService
        self.analyticsService = FirebaseAnalyticsService()
        self.whatsNewStorage = WhatsNewStorage()
    }
}

// Нужен, так как @Environment хочет дефолтное значение. Это оно
final class FatalDIContainer: IAppDIContainer {
    init() {}

    var logger: Logger {
        fatalError("Данный объект не должен быть использован в приложении")
    }
    var projectsLoader: ProjectsLoader {
        fatalError("Данный объект не должен быть использован в приложении")
    }
    var executor: CommandExecutor {
        fatalError("Данный объект не должен быть использован в приложении")
    }
    var notificationService: NotificationService {
        fatalError("Данный объект не должен быть использован в приложении")
    }
    var appUpdaterService: IAppUpdaterService {
        fatalError("Данный объект не должен быть использован в приложении")
    }
    var whatsNewStorage: WhatsNewStorage {
        fatalError("Данный объект не должен быть использован в приложении")
    }
    var analyticsService: any IAnalyticsService {
        fatalError("Данный объект не должен быть использован в приложении")
    }
    var deeplinkService: DeeplinkService {
        fatalError("Данный объект не должен быть использован в приложении")
    }
}
