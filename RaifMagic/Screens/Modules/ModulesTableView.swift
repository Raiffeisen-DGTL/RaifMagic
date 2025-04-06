//
//  File.swift
//
//
//  Created by USOV Vasily on 25.04.2024.
//

import SwiftUI


@MainActor
struct ModulesTableView: View {

    @Environment(ConsoleViewModel.self) private var consoleViewModel
    @Environment(EnvironmentViewModel.self) private var environmentViewModel
    @Environment(ProjectViewModel.self) private var projectViewModel
    @Environment(\.dependencyContainer) private var di
    
    @State private var searchText = ""
    
    @AppStorage("favoriteModules") private var favoriteModules: Set<String> = []
    
    var body: some View {
        NavigationStack {
            HStack {
                modulesTable(modules: Bindable(wrappedValue: projectViewModel).modules)
                AppSidebar {
                    ForEach(Bindable(projectViewModel).filters) { filter in
                        Section {
                            ForEach(filter.values, id: \.id) { value in
                                FilterView(value: value)
                            }
                        } header: {
                            Text(filter.wrappedValue.title)
                        } footer: {
                            Text(filter.wrappedValue.description)
                                .font(.footnote)
                        }
                    }
                    SidebarCustomOperationView(operation: CustomOperation(title: "Загрузить модули", description: "Будет произведена повторная загрузка модулей из проекта", icon: "play") {
                        await consoleViewModel.run(work: { console in
                            try await projectViewModel.refreshModules()
                        }, withTitle: "Загрузка модулей из проекта", outputStrategy: .all)
                    })
                    .disabled(consoleViewModel.isCommandRunning)
                }
                .frame(maxWidth: 350)
            }
            .searchable(text: $searchText)
            .navigationDestination(for: ModulesScreen.Endpoint.self, destination: { destination in
                switch destination {
                case .moduleScreen(moduleName: let name, projectService: let projectService):
                    if let module = Bindable(wrappedValue: projectViewModel).modules.first(where: {$0.wrappedValue.name == name}) {
                        ModuleView(module: module, projectService: projectService)
                            .environment(consoleViewModel)
                            .environment(\.dependencyContainer, di)
                    }
                }
            })
        }
    }
    
    private struct FilterView: View {
        @Binding var value: any FilterValue
        
        var body: some View {
            if let toggle = value as? any FilterToggle {
                Toggle(isOn: Binding(get: {
                    toggle.currentValue
                }, set: { newValue in
                    var mutable = toggle
                    mutable.currentValue = newValue
                    value = mutable
                })) {
                    Text(toggle.name)
                    if let description = toggle.description {
                        Text(description)
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                }
            } else if let picker = value as? any FilterPicker {
                VStack(alignment: .leading) {
                    Picker(selection: Binding(get: {
                        picker.currentValue
                    }, set: { newValue in
                        var mutable = picker
                        mutable.currentValue = newValue
                        value = mutable
                    })) {
                        ForEach(picker.values, id: \.self) { option in
                            Text(option)
                                .tag(option)
                        }
                    } label: {
                        Text(picker.name)
                        
                    }
                    if let description = picker.description {
                        Text(description)
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
    
    private func modulesTable(modules: Binding<[any IProjectModule]>) -> some View {
        ScrollViewReader { reader in
            Table(of: AnyBindingModule.self) {
                TableColumn("★") { item in
                    Button {
                        if favoriteModules.contains(item.module.wrappedValue.name) {
                            favoriteModules.remove(item.module.wrappedValue.name)
                        } else {
                            favoriteModules.insert(item.module.wrappedValue.name)
                        }
                    } label: {
                        Image(systemName: favoriteModules.contains(item.module.wrappedValue.name) ? "star.fill" : "star")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15)
                    }
                    .id(item.id)
                }
                .width(max: 40)
                .alignment(.center)
                
                TableColumn("Название") { item in
                    VStack(alignment: .leading) {
                    Text(item.module.wrappedValue.name)
                        if let _item = item.module.wrappedValue as? (any ProjectModule.DisplayConfigurationSupported), let description = _item.tableItemDescription {
                            Text(description)
                                .font(.subheadline)
                                .opacity(0.5)
                        }
                    }
                }
                .alignment(.leading)
                
                // Display a button to go to the module details screen
                if let projectService = projectViewModel.projectService as? (any ModuleScreenSupported) {
                    TableColumn("Детали") { item in
                        NavigationLink(value: ModulesScreen.Endpoint.moduleScreen(moduleName: item.module.wrappedValue.name, projectService: projectService)) {
                            Image(systemName: "info.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15)
                        }
                    }
                    .width(max: 80)
                    .alignment(.center)
                }
            } rows: {
                ForEach(modules
                    .filter {
                        let filters = projectViewModel.filters.flatMap(\.values)
                        for filter in filters {
                            if filter.filter(module: $0.wrappedValue) == false { return false }
                        }
                        guard searchText.count > 0 else { return true }
                        return $0.wrappedValue.name.lowercased().contains(searchText.lowercased())
                    }
                    .sorted { $0.wrappedValue.name.lowercased() < $1.wrappedValue.name.lowercased() }
                    .sorted { favoriteModules.contains($0.wrappedValue.name) && favoriteModules.contains($1.wrappedValue.name) == false }
                    .map(AnyBindingModule.init)
                ) { item in
                    TableRow(item)
                }
            }
            .onChange(of: searchText, { _, _ in
                // Hack to avoid scrolling up when re-entering into the search field
                guard let first = modules.first else { return }
                reader.scrollTo(first.wrappedValue.id, anchor: .top)
            })
        }
    }
}
