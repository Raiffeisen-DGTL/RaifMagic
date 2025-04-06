//
//  ExampleProjectService + Privacy.swift
//  RaifMagic
//
//  Created by USOV Vasily on 05.03.2025.
//

import SwiftUI

// TODO: Убрать privacyService, упростить код
extension ExampleProject.ProjectService: SecretsSupported {
    var secrets: [any SecretValue] {
        [
            SomeAPIKey()
        ]
    }
    var secretsScreenSidebarActions: [CustomActionSection] {
        [
            CustomActionSection(title: "Сервисы", operations: [
                CustomWebLink(title: "Открыть Gitlab", description: "Будет открыт экран настройки Access Tokens", url: URL(string: "https://gitlabci.example.com/-/user_settings/personal_access_tokens")!)
            ])
        ]
    }
    func hidePrivacyContent(from source: String) async -> String {
        // you can modify content here to clear privacy data from logs and other output
        source
    }
}

final class SomeAPIKey: TextSecretValue {
    var id: Int {
        title.hashValue
    }
    var title: String = "Gitlab token"
    private var _value: String = "Test Token"
    
    var currentValue: String {
        get async {
            _value
        }
    }
    
    func onUpdate(_ newValue: String) async {
        _value = newValue
    }
}
