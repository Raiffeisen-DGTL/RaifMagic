//
//  ExampleProjectService + ModuleScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 14.02.2025.
//

import SwiftUI

extension ExampleProject.ProjectService: ModuleScreenSupported {
    func moduleScreenAdditionalOperations(module: any IProjectModule, console: IConsole) -> [CustomActionSection]? {
        guard let projectModule = module as? (ExampleProject.MonorepositoryModule) else { return nil }
        return [
            CustomActionSection(title: "Форматирование модуля", operations: [
                CustomOperation(title: "Запустить SwiftFormat по коду модуля",
                               description: "Исходный код модуля будет исправлен с помощью swiftformat",
                               confirmationDescription: "Запуск swiftformat приведет к изменению исходного кода модуля. Советуем сохранить текущие изменения в git, чтобы иметь возможно откатиться после отработки swiftformat.", closure: { [self] in
                                   let command = Command("./scripts/swiftformat .\(projectModule.url) --config .swiftformat", executeAtPath: projectURL.path())
                                   await console.run(command: command, withTitle: "Запуск swiftformate для модуля \(module.name)", convertErrorToWarning: false, outputStrategy: .all)
                })
            ])
        ]
    }
    
    func moduleScreenAdditionalView(module: Binding<any IProjectModule>) -> AnyView? {
        if let _m = module.wrappedValue as? ExampleProject.MonorepositoryModule {
            AnyView(
                MonorepositoryModuleAdditionalView(module: Binding(get: { _m }, set: { v in module.wrappedValue = v }), projectService: self)
            )
        } else if let _m = module.wrappedValue as? ExampleProject.LocalSpmPackage {
            AnyView(
                LocalSpmPackageAdditionalView(module: Binding(get: { _m }, set: { v in module.wrappedValue = v }), projectService: self)
            )
        } else if let _m = module.wrappedValue as? ExampleProject.RemoteSpmPackage {
            AnyView(
                RemoteSpmPackageAdditionalView(module: Binding(get: { _m }, set: { v in module.wrappedValue = v }), projectService: self)
            )
        } else {
            nil
        }
    }
}

private struct MonorepositoryModuleAdditionalView: View {
    
    @Binding var module: ExampleProject.MonorepositoryModule
    let projectService: ExampleProject.ProjectService
    
    var body: some View {
        Section("Основное") {
            LabeledContent("Расположение", value: "Монорепозиторий")
            LabeledContent("URL") {
                VStack(alignment: .trailing) {
                    Text(module.url.path())
                    if let path = absolutePath(forModuleURL: module.url) {
                        Button {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                        } label: {
                            Text("Открыть")
                        }
                    }
                }
            }
        }
    }
    
    private func absolutePath(forModuleURL url: URL) -> String? {
        let resultURL = projectService.projectURL.appending(path: url.path())
        return if FileManager.default.fileExists(atPath: resultURL.path) {
            resultURL.path
        } else { nil }
    }
}

private struct LocalSpmPackageAdditionalView: View {
    
    @Binding var module: ExampleProject.LocalSpmPackage
    let projectService: ExampleProject.ProjectService
    
    var body: some View {
        Section("Основное") {
            LabeledContent("Расположение", value: "Локальный SPM-пакет")
            LabeledContent("URL") {
                VStack(alignment: .trailing) {
                    Text(module.url.path())
                    if let path = absolutePath(forModuleURL: module.url) {
                        Button {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                        } label: {
                            Text("Открыть")
                        }
                    }
                }
            }
        }
    }
    
    private func absolutePath(forModuleURL url: URL) -> String? {
        let resultURL = projectService.projectURL.appending(path: url.path())
        return if FileManager.default.fileExists(atPath: resultURL.path) {
            resultURL.path
        } else { nil }
    }
}

private struct RemoteSpmPackageAdditionalView: View {
    
    @Binding var module: ExampleProject.RemoteSpmPackage
    let projectService: ExampleProject.ProjectService
    
    var body: some View {
        Section("Основное") {
            LabeledContent("Расположение", value: "Удаленный SPM-пакет")
            LabeledContent("URL") {
                VStack(alignment: .trailing) {
                    Text(module.url.absoluteString)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Button {
                        NSWorkspace.shared.open(module.url)
                    } label: {
                        Text("Открыть")
                    }
                }
            }
            LabeledContent("Версия", value: module.version)
        }
    }
    
    private func absolutePath(forModuleURL url: URL) -> String? {
        let resultURL = projectService.projectURL.appending(path: url.path())
        return if FileManager.default.fileExists(atPath: resultURL.path) {
            resultURL.path
        } else { nil }
    }
}
