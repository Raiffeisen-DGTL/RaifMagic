//
//  AppVersionView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 16.12.2024.
//
import SwiftUI

struct AppVersionManager: View {
    @Environment(EnvironmentViewModel.self) private var environmentViewModel
    @Environment(ProjectViewModel.self) private var projectViewModel
    @State private var versions: [AppVersionIdentifier] = []
    @State private var loadDidEnd = false
    @State private var showError: MagicError? = nil
    @State private var tryInstall: AppVersionIdentifier? = nil
    @State private var installInProgress: AppVersionIdentifier? = nil
    @AppStorage("showOnlySupportedVersions") private var showOnlySupportedVersions: Bool = false
    
    var body: some View {
        HStack {
            if loadDidEnd == false {
                Form {
                    ProgressView()
                }
                .formStyle(.grouped)
            } else {
                versionsView
                    .alert("Обновление RaifMagic", isPresented: Binding<Bool>(get: {tryInstall != nil }, set: { _ in
                        tryInstall = nil
                    }), presenting: tryInstall) { version in
                        Button(action: {
                            Task { [version] in
                                do {
                                    installInProgress = version
                                    try await environmentViewModel.updateApp(toVersion: version)
                                } catch {
                                    showError = MagicError(error: nil, errorDescription: "Ошибка при попытке обновления - \(error.localizedDescription)")
                                }
                                installInProgress = nil
                            }
                        }, label: {
                            Text("Делаем!")
                        })
                        Button(action: {}, label: {
                            Text("Не делаем")
                        })
                    } message: { version in
                        Text("Будет установлен RaifMagic \(version.asString). Запущенная версия RaifMagic будет удалена, приложение будет перезапущено. При этом все несохраненный данные будут потрачены. Делаем?")
                    }
            }
            AppSidebar {
                SidebarCustomOperationView(operation: CustomOperation(title: "Проверить обновления", description: "Будет произведена проверка доступных версий RaifMagic", icon: "network") {
                    await checkVersions()
                })
                Section("Фильтрация") {
                    Toggle(isOn: $showOnlySupportedVersions) {
                        Text("Показывать только совместимые версии")
                        Text("При включении будут отображены только те версии приложения, которые совместимы с текущим проектом.")
                    }
                }
            }
        }
        .task {
            await checkVersions()
        }
        .alert(isPresented: Binding<Bool>(get: {showError != nil}, set: { _ in showError = nil }),
               error: showError,
               actions: {})
    }
    
    @ViewBuilder
    private var versionsView: some View {
        Table(versions
            .filter({
                if showOnlySupportedVersions {
                    if let result = try? projectViewModel.canGenerate(withAppVersion: $0) {
                        result == .can
                    } else {
                        false
                    }
                } else {
                    true
                }
            })
            .sorted(by: {
            ($0.major, $0.minor, $0.patch) > ($1.major, $1.minor, $1.patch)
        })) {
            TableColumn("Версия", content: { item in
                if item.asString == AppConfig.appVersion.asString {
                    VStack(alignment: .leading) {
                        Text(item.asString)
                            .bold()
                        Text("Текущая версия")
                            .font(.caption2)
                    }
                } else {
                    Text(item.asString)
                }
            })
            TableColumn("Совместимо с проектом", content: { item in
                VersionRow(version: item)
                    .environment(projectViewModel)
            })
            .alignment(.center)
            TableColumn("Действия", content: { item in
                if item.asString != AppConfig.appVersion.asString {
                    Button {
                        tryInstall = item
                    } label: {
                        Text("Установить")
                    }
                    .disabled(installInProgress != nil)
                }
            })
            .alignment(.center)
        }
    }
    
    private func checkVersions() async {
        loadDidEnd = false
        do {
            versions = try await environmentViewModel.fetchAvailableAppVersions()
        } catch {
            showError = MagicError(error: nil, errorDescription: "Не удалось загрузить список доступных версий. Ошибка - \(error.localizedDescription)")
        }
        loadDidEnd = true
    }
}

struct VersionRow: View {
    
    let version: AppVersionIdentifier
    @State private var canUseResult: CanUseResult = .error
    
    @Environment(ProjectViewModel.self) private var projectViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch canUseResult {
            case .yes:
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.green)
                    .frame(width: 10, height: 10)
            case .not:
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.red)
                    .frame(width: 10, height: 10)
            case .error:
                Image(systemName: "info.circle.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.gray)
                    .frame(width: 10, height: 10)
            }
        }
        .task {
            do {
                switch try projectViewModel.canGenerate(withAppVersion: version) {
                case .can:
                    canUseResult = .yes
                case .needInstall:
                    canUseResult = .not
                }
            } catch {
                canUseResult = .error
            }
        }
    }
    
    enum CanUseResult {
        case yes
        case not
        case error
    }
}
