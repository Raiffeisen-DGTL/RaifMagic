//
//  LoaderView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 08.07.2024.
//

import SwiftUI

struct LoaderView: View {
    
    @Binding var loadingDidFinish: Bool
    @Binding var di: IAppDIContainer?
    let logger: Logger
    
    @State private var didEndAnimation: Bool = false
    
    @State private var isShowAlert = false
    @State private var error: MagicError? = nil
    
    @AppStorage("loadingScreen") private var loadingScreen: LoadingScreen = .animatedMagic
    
    var body: some View {
        Color.clear
            .overlay{
                switch loadingScreen {
                case .animatedMagic:
                    AnimatedMagic(didEndAnimation: $didEndAnimation)
                case .sleepMagical:
                    SleepMagical(didEndAnimation: $didEndAnimation)
                case .waveRaifMagic:
                    WaveAnimationsView(didEndAnimation: $didEndAnimation)
                }
            }
            .alert(isPresented: $isShowAlert, error: error) {}
            .onAppear {
                Task {
                    await logger.log(.debug, message: "[LoadingView] Отображение экрана загрузки")
                }
                hideTabBar()
                do {
                    if di == nil {
                        Task {
                            await logger.log(.debug, message: "[LoadingView] DI не инициализирован, требуется его иницализация")
                        }
                        let di = AppDIContainer(logger: logger)
                        self.di = di
                    }
                    try prepareMagicEnvironment()
                    Task { @MainActor in
                        while didEndAnimation == false {
                            try await Task.sleep(for: .seconds(0.1))
//                            await Task.yield()
                        }
                        loadingDidFinish = true
                    }
                } catch {
                    Task {
                        await di?.logger.log(.debug, message: error.localizedDescription)
                    }
                    self.error = MagicError(errorDescription: "Ошибка в ходе инициализации приложения: \(error.localizedDescription)")
                    isShowAlert = true
                }
            }
    }
    
    private func prepareMagicEnvironment() throws {
        if FileManager.default.fileExists(atPath: AppConfig.temporaryDirectory) == false {
            try? FileManager.default.createDirectory(atPath: AppConfig.temporaryDirectory, withIntermediateDirectories: false)
        }
        try FileManager.default.contentsOfDirectory(atPath: AppConfig.temporaryDirectory).forEach { file in
            guard let fileExtension = file.split(separator: ".").last, fileExtension == "log" else { return }
            let filePath = AppConfig.temporaryDirectory + "/" + file
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            guard let creationDate = attributes[.creationDate] as? Date else { return }

            guard let days = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day else { return }
            // Delete files older than 5 days
            if days > 5 {
                try FileManager.default.removeItem(atPath: filePath)
            }
        }
        // Delete data after updating the application
        try? FileManager.default.removeItem(atPath: AppConfig.temporaryDirectory + "/__MACOSX")
        try? FileManager.default.removeItem(atPath: AppConfig.temporaryDirectory + "/RaifMagic.app")
        try? FileManager.default.removeItem(atPath: AppConfig.temporaryDirectory + "/RaifMagic.zip")
    }
    
    @MainActor
    private func hideTabBar() {
        NSApplication.shared.windows.forEach { window in
            if let tabGroup = window.tabGroup, tabGroup.isTabBarVisible {
                window.toggleTabBar(nil)
            }
        }
    }
}
