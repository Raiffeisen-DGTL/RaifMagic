//
//  ExampleProjectService + GenerationConfigurationView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 13.02.2025.
//

import SwiftUI

extension ExampleProject.ProjectService: GenerateConfigurationSupported {
    var isSupportedGenerationWithExternalConsole: Bool {
        true
    }
    
    func configurationView(onChange: @escaping () -> Void) -> AnyView {
        AnyView(ExampleProject.ConfigurationView(onChange: onChange))
    }
}

extension ExampleProject {
    struct ConfigurationView: View {
        let onChange: () -> Void
        
        @AppStorage("Example_removeDerivedData") private var removeDerivedData = false
        @AppStorage("Example_openXcodeWorkspaceAfterSuccessGeneration") private var needOpenXcode = false
        @AppStorage("Example_needCloseXcode") private var needCloseXcode = true
        
        var body: some View {
            Section("Предварительные ласки") {
                Toggle(isOn: $needCloseXcode) {
                    Text("Закрыть Xcode при старте генерации")
                    Text("Будут закрыты все процессы, имеющие в названии слово Xcode")
                        .font(.callout)
                }
                .onChange(of: needCloseXcode) { _, _ in
                    onChange()
                }
                Toggle(isOn: $removeDerivedData) {
                    Text("Удалять DerivedData")
                    Text("Вызывать rm -Rf ~/Library/Developer/Xcode/DerivedData/*")
                        .font(.callout)
                }
                .onChange(of: removeDerivedData) { _, _ in
                    onChange()
                }
            }
            Section("Проект") {
                Toggle(isOn: $needOpenXcode) {
                    Text("Открывать Xcode после успешной генерации")
                    Text("В случае, если проект будет успешно сгенерирован, то будет автоматически открыт Xcode")
                        .font(.callout)
                }
                .onChange(of: needOpenXcode) { _, _ in
                    onChange()
                }
            }
        }
    }
}
