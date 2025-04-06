//
//  AppVersionsList.swift
//  RaifMagic
//
//  Created by USOV Vasily on 03.03.2025.
//

import SwiftUI 

// This view is used on the screen with the list of projects
// For the update screen inside the project there is a separate view AppVersionManager

struct GlobalUpdateAppVersionView: View {
    let appUpdaterService: any IAppUpdaterService
    @State private var versions: [AppVersionIdentifier] = []
    @State private var loadDidEnd = false
    @State private var showError: MagicError? = nil
    @State private var tryInstall: AppVersionIdentifier? = nil
    @State private var installInProgress: AppVersionIdentifier? = nil
    
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
                                    try await appUpdaterService.updateApp(toVersion: version)
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
        Form {
            ForEach(versions
                .sorted(by: { ($0.major, $0.minor, $0.patch) > ($1.major, $1.minor, $1.patch) } )) { item in
                        HStack {
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
                            Spacer()
                            if item.asString != AppConfig.appVersion.asString {
                                Button {
                                    tryInstall = item
                                } label: {
                                    Text("Установить")
                                }
                                .disabled(installInProgress != nil)
                            }
                        }
                    }
        }
        .formStyle(.grouped)
    }
    
    private func checkVersions() async {
        loadDidEnd = false
        do {
            versions = try await appUpdaterService.fetchAvailableAppVersions()
        } catch {
            showError = MagicError(error: nil, errorDescription: "Не удалось загрузить список доступных версий. Ошибка - \(error.localizedDescription)")
        }
        loadDidEnd = true
    }
}
