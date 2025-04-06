//
//  GenerateView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 28.05.2024.
//
import SwiftUI



struct ConsoleView: View {
    
    let screenMode: ScreenMode
    let reinitProject: (() async -> Void)?
    @Environment(ConsoleViewModel.self) private var consoleViewModel
    @Environment(ProjectViewModel.self) private var projectViewModel
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var dotCounts = 1
    
    var body: some View {
        switch screenMode {
        case .full:
            HStack {
                consoleView
                AppSidebar {
                    Section("Проект") {
                        SidebarCustomOperationView(operation: CustomOperation(title: "Реинициализация проекта", description: "Будет произведена полная реинициализация проекта", icon: "arrow.clockwise") {
                            Task { @MainActor in
                                await reinitProject?()
                            }
                        })
                        .disabled(consoleViewModel.isCommandRunning)
                    }
                    Section("Консоль") {
                        SidebarCustomOperationView(operation: CustomOperation(title: "Скопировать", icon: "doc.on.doc") {
                            NSPasteboard.general.declareTypes([.string], owner: nil)
                            let string = await consoleViewModel.output.map(\.asString).joined(separator: "\n")
                            NSPasteboard.general.setString(string, forType: .string)
                        })
                        SidebarCustomOperationView(operation: CustomOperation(title: "Очистить", icon: "clear.fill") {
                            Task { @MainActor in
                                consoleViewModel.output = []
                            }
                        })
                    }
                }
            }
        case .compact:
            consoleView
        }
    }
    
    private var consoleView: some View {
        ScrollViewReader { reader in
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(Array(consoleViewModel.output.enumerated()), id:\.offset) { value in
                        let string: AttributedString = {
                            var result = AttributedString()
                            value.element.items.forEach{ item in
                                var itemString = AttributedString(item.content + " ")
                                
                                itemString.foregroundColor = switch item.color {
                                case .green: .green
                                case .red: .red
                                case .yellow: .yellow
                                default: .white
                                }
                                result += itemString
                            }
                            return result
                        }()
                        
                        Text(string)
                            .foregroundStyle(Color.gray)
                            .fontWeight(.semibold)
                            .fontDesign(.monospaced)
                    }
                    HStack {
                        if consoleViewModel.isCommandRunning {
                            ForEach(0...(dotCounts-1), id: \.self) { _ in
                                Text(".")
                                    .foregroundStyle(Color.gray)
                                    .fontWeight(.bold)
                                    .fontDesign(.monospaced)
                            }
                        }
                    }
                    .id("dotsAnchor")
                }
                .textSelection(.enabled)
                
            }
            .defaultScrollAnchor(.bottom)
            .frame(maxWidth:.infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black)
            .onReceive(timer) { _ in
                guard consoleViewModel.isCommandRunning else { return }
                let newValue = dotCounts + 1
                dotCounts = if newValue > 3 { 1 } else { newValue }
            }
            .scrollDisabled(screenMode == .compact)
        }
    }
    
    enum ScreenMode {
        case full
        case compact
    }
}



