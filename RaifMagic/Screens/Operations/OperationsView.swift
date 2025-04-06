//
//  OperationsView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 09.07.2024.
//

import SwiftUI

struct OperationsView: View {
    @Environment(ConsoleViewModel.self) private var consoleViewModel
    @Environment(EnvironmentViewModel.self) private var environmentViewModel
    @AppStorage("favoriteMagicOperationsTitles") private var favoriteMagicOperationsTitles: [String] = []
    let sections: [CustomActionSection]
    
    var body: some View {
        HStack {
            ScrollView {
                LazyVGrid(
                    columns: [.init(.adaptive(minimum: 300, maximum: 400),
                                    spacing: 20, alignment: .top)]) {
                                        ForEach(sections) { section in
                                            OperationSection(section: section)
                                        }
                                    }
                                    .padding()
                                    .disabled(consoleViewModel.isCommandRunning || environmentViewModel.isRunningUpdatingEnvironment || environmentViewModel.isRunningCheckingEnvironment)
            }
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: NSColor.windowBackgroundColor))
            
            AppSidebar {
                Section {
                    if favoriteMagicOperationsTitles.isEmpty == false {
                        ForEach(favoriteMagicOperationsTitles, id: \.self) { favoriteTitle in
                            // TODO: There may be links here, you need to process them
                            if let operation = sections.flatMap(\.items).first(where: { $0.title == favoriteTitle }) as? CustomOperation {
                                HStack(spacing: 10) {
                                    FastMagicOperationView(operation: operation)
                                        .disabled(consoleViewModel.isCommandRunning || environmentViewModel.isRunningUpdatingEnvironment || environmentViewModel.isRunningCheckingEnvironment)
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    } else {
                        Text("Вы еще не добавили избранные операции. Для добавления нажмите на иконку звездочки возле операции")
                            .font(.callout)
                    }
                } header: {
                    HStack {
                        Text("Избранные операции")
                    }
                }
            }
        }
    }
    
    private struct FastMagicOperationView: View {
        var operation: CustomOperation
        @Environment(\.isEnabled) private var isEnabled: Bool
        
        var body: some View {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(operation.title)
                    if let description = operation.description {
                        Text(description)
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                }
                Spacer()
                Button {
                    Task {
                        await operation.closure()
                    }
                } label: {
                    Image(systemName: "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 10)
                }
                .opacity(isEnabled == false ? 0.3 : 1)
                .disabled(isEnabled == false)
            }
        }
    }
}

private struct OperationSection: View {
    let section: CustomActionSection
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(section.title)
                .font(.title)
                .fontWeight(.bold)
            ForEach(section.items, id: \.id) { action in
                if let operation = action as? CustomOperation {
                    CustomOperationView(magicOperation: operation)
                }
            }
        }
        .padding(3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CustomOperationView: View {
    let magicOperation: CustomOperation
    @State private var isFavorite: Bool = false
    @Environment(\.isEnabled) private var isEnabled: Bool
    @AppStorage("favoriteMagicOperationsTitles") private var favoriteMagicOperationsTitles: [String] = []
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, content: {
                Text(magicOperation.title)
                    .font(.title3)
                if let description = magicOperation.description {
                    HStack {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.gray)
                    }
                }
            })
            Spacer()
            
            Image(systemName: isFavorite ? "star.fill" : "star")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 15)
                .onTapGesture {
                    isFavorite.toggle()
                }
                .padding(.leading, 10)
                .foregroundStyle(isEnabled ? Color.black.opacity(0.6) : Color.black.opacity(0.3))
            Button(action: {
                Task {
                    await magicOperation.closure()
                }
            }, label: {
                Image(systemName: "play.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10)
                    .foregroundStyle(isEnabled ? Color.black.opacity(0.6) : Color.black.opacity(0.3))
            })
        }
        .onAppear {
            isFavorite = favoriteMagicOperationsTitles.contains { $0 == magicOperation.title }
        }
        .onChange(of: isFavorite) {
            if isFavorite,  favoriteMagicOperationsTitles.contains(where: { $0 == magicOperation.title }) == false {
                favoriteMagicOperationsTitles.append(magicOperation.title)
            } else if isFavorite == false, let index = favoriteMagicOperationsTitles.firstIndex(where: { $0 == magicOperation.title }) {
                favoriteMagicOperationsTitles.remove(at: index)
            }
        }
    }
}

private struct OperationItemView: View {
    let title: String
    let description: String?
    let showAlert: Bool
    let operation: () -> Void
    
    init(title: String, description: String?, showAlert: Bool = false, operation: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.showAlert = showAlert
        self.operation = operation
    }
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, content: {
                Text(title)
                    .font(.title3)
                if let description {
                    HStack {
                        if showAlert {
                            Image(systemName: "info.circle.fill")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundStyle(Color.red)
                                .frame(width: 13, height: 13)
                        }
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.gray)
                    }
                }
            })
            Spacer()
            Button(action: {
                operation()
            }, label: {
                Image(systemName: "play.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10)
                    .foregroundStyle(isEnabled ? Color.black.opacity(0.6) : Color.black.opacity(0.3))
            })
        }
    }
}
