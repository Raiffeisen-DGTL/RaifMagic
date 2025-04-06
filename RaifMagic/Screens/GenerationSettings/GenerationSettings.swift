//
//  File.swift
//
//
//  Created by USOV Vasily on 25.04.2024.
//

import SwiftUI
import TipKit

struct GenerationSettings: View {
    
    @Environment(ProjectViewModel.self) private var projectViewModel
    
    @AppStorage("useGenerateType") private var useGenerateType: GenerateType = .external
    
    @State private var scenario: CommandScenario? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            if let _service = projectViewModel.projectService as? (any GenerateConfigurationSupported), _service.isSupportedGenerationWithExternalConsole {
                Form {
                    Section("Процесс генерации") {
                        Picker(selection: $useGenerateType) {
                            ForEach(GenerateType.allCases) { value in
                                Text(value.description)
                            }
                        } label: {
                            Text("Терминал, в котором будет запускать генерация проекта")
                        }
                    }
                    
                    if let service = projectViewModel.projectService as? (any GenerateConfigurationSupported) {
                        service.configurationView {
                            scenario = projectViewModel.generationScenario()
                        }
                    }
                }
                .formStyle(.grouped)
                .frame(maxWidth: .infinity)
            }
            
            if let scenario {
                Form {
                    Section("Сценарий генерации проекта") {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(scenario.steps) {
                                CommandLine(command: $0.command)
                            }
                        }
                        .textSelection(.enabled)
                        .foregroundStyle(Color.gray)
                        .fontWeight(.semibold)
                        .fontDesign(.monospaced)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(maxWidth: .infinity)
                .formStyle(.grouped)
            }
        }
        .onAppear {
            scenario = projectViewModel.generationScenario()
        }
    }
}

private struct CommandLine: View {
    var command: Command
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            Text(command.asString)
        }
        .padding(.horizontal, 5)
        .onHover(perform: { hovering in
            isHovering = hovering
        })
        .background(Color.gray.opacity(isHovering ? 0.3 : 0))
    }
}
