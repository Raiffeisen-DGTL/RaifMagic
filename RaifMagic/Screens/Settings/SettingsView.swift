//
//  SettingsView.swift
//
//
//  Created by USOV Vasily on 27.04.2024.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("notificationsOperationsEnd") private var notificationsOperationsEnd = false
    
    @AppStorage("customEnvironmentControl") private var customEnvironmentControl = false
    @AppStorage("showMiniConsole") private var showMiniConsole = true
    @AppStorage("loadingScreen") private var loadingScreen: LoadingScreen = .animatedMagic
    
    @Environment(\.dependencyContainer) private var di
    
    @Namespace private var namespace
    
    var body: some View {
        HStack {
            Form {
                Section("Окружение") {
                    Toggle(isOn: $customEnvironmentControl) {
                        Text("Самостоятельно управлять версиями зависимостей")
                        Text("При включении этой функции использование старых версий зависимостей, Xcode и RaifMagic не будет блокировать генерацию проекта")
                            .font(.callout)
                        if customEnvironmentControl {
                            Label {
                                Text("Использование данной настройки не рекомендовано")
                                    .font(.callout)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .foregroundStyle(Color.yellow)
                            }
                        }
                    }
                }
                
                Section("Вспомогательные функции") {
                    Toggle(isOn: $notificationsOperationsEnd) {
                        Text("Уведомлять после завершения задачи")
                        Text("После выполнения сценария генерации проекта в Центре уведомлений macOS будет отображено всплывающее уведомление с результатами генерации")
                            .font(.callout)
                    }
                    Toggle(isOn: $showMiniConsole) {
                        Text("Показывать уменьшенную версию консоли")
                        Text("Во время выполнения задач в левом нижнем углу будет отображаться уменьшеная версия консоли")
                            .font(.callout)
                    }
                }
                
                Section("Оформление") {
                    HStack(alignment: .top) {
                        Text("Экран загрузки")
                        Spacer()
                        imageSelector(value: .waveRaifMagic)
                        imageSelector(value: .animatedMagic)
                        imageSelector(value: .sleepMagical)
                    }
                }
            }
            .onChange(of: notificationsOperationsEnd) {
                di.notificationService.requestNotificationAuthorization()
            }
            .formStyle(.grouped)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func imageSelector(value: LoadingScreen) -> some View {
        VStack(spacing: 8) {
            Color.clear
                .overlay(alignment: .center) {
                    Image(value.imageName)
                        .resizable()
                        .frame(width: 120, height: 80)

                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(width: 100, height: 60)
                .shadow(radius: 1)
                .overlay {
                    if loadingScreen == value {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke()
                            .stroke(lineWidth: 2)
                            .foregroundStyle(Color.blue)
                            .frame(width: 107, height: 67, alignment: .center)
                    }
                }
            Text(value.description)
                .font(.caption2)
                .opacity(loadingScreen == value ? 1.0 : 0.5)
                .fontWeight(loadingScreen == value ? .bold : .regular)
        }
        .onTapGesture {
            loadingScreen = value
        }
        .frame(width: 110)
    }
}


