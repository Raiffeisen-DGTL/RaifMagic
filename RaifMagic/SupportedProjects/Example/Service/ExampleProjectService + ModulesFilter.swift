//
//  ExampleProject + ModulesFilterSupported.swift
//  RaifMagic
//
//  Created by USOV Vasily on 20.02.2025.
//

extension ExampleProject.ProjectService: ModulesFilterSupported {
    var initialModulesFilterSections: [FilterSection] {
        [
            FilterSection(title: "Фильтрация модулей",
                          description: "",
                          values: [
                            ExampleTargetFilterPicker(name: "Проект",
                                               description: "Укажите, модули какого таргета отображать",
                                               currentValue: "Target1/Target2",
                                               values: ["Target1/Target2", "Target1", "Target2"])
                          ])
        ]
    }
}

// Фильтр-пикер для страницы модулей
struct ExampleTargetFilterPicker: FilterPicker {
    var name: String
    var description: String?
    var currentValue: String
    var values: [String]
    
    init(name: String, description: String? = nil, currentValue: String, values: [String]) {
        self.name = name
        self.description = description
        self.currentValue = currentValue
        self.values = values
    }
    
    func filter(module: any IProjectModule) -> Bool {
        guard let _module = module as? (any ExampleProject.Module) else { return false }
        return switch (self.currentValue, _module.target) {
        case ("Target1/Target2", .target1): true
        case ("Target1/Target2", .target2): true
        case ("Target1", .target1): true
        case ("Target2", .target2): true
        default: false
        }
    }
}
