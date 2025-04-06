//
//  RMobileProjectService + Operations.swift
//  RaifMagic
//
//  Created by USOV Vasily on 12.02.2025.
//

extension ExampleProject.ProjectService: QuickOperationSupported {
    func operations(console: any IConsole) -> [CustomActionSection] {
        [
            CustomActionSection(title: "Окружение", operations: [
                CustomOperation(title: "Очистка кеша SPM", description: "Полная очистка кеша для всех проектов. Обычно решает все проблемы с SPM", closure: {
                    var scenario = CommandScenario(title: "Очистка кеша SPM")
                    scenario.add(command: Command("rm -rf ~/Library/Caches/org.swift.swiftpm"))
                    scenario.add(command: Command("rm -rf ~/Library/org.swift.swiftpm"))
                    await console.run(scenario: scenario, outputStrategy: .all)
                }),
                CustomOperation(title: "Удаление DerivedData", description: "Удаление артефактов сборки в папке DerivedData", closure: {
                    var scenario = CommandScenario(title: "Удаление DerivedData")
                    scenario.add(command: Command("rm -Rf ~/Library/Developer/Xcode/DerivedData/*"))
                    await console.run(scenario: scenario, outputStrategy: .all)
                })
            ]),
            CustomActionSection(title: "Проект", operations: [
                CustomOperation(title: "Очистка Tuist", description: "Вызов tuist clean", closure: {
                    var scenario = CommandScenario(title: "Очистка Tuist")
                    scenario.add(command: Command("tuist clean", executeAtPath: self.projectURL.path()))
                    await console.run(scenario: scenario, outputStrategy: .all)
                }),
                CustomOperation(title: "Обновление FeatureToggles и ABTestToggles", description: "Обновление содержимого файла featureToggles.swift в модуле FeatureToggles", closure: {
                    var scenario = CommandScenario(title: "Удаление DerivedData")
                    scenario.add(command: Command("magic generate-toggles \(self.projectURL.path())"))
                    await console.run(scenario: scenario, outputStrategy: .all)
                })
            ]),
        ]
    }
}
