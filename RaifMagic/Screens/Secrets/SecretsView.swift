//
//  SecretsView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 05.03.2025.
//

import SwiftUI

private struct SecretValueTextView: View {
    
    let initialValue: any TextSecretValue
    @State private var value: String = ""
    
    var body: some View {
        LabeledContent {
            TextField("", text: $value)
        } label: {
            Text(initialValue.title)
                .foregroundStyle(Color.gray)
        }
        .onChange(of: value) { oldValue, newValue in
            Task {
                await initialValue.onUpdate(newValue)
            }
        }
        .task {
            value = await initialValue.currentValue
        }
    }
}

struct SecretsView: View {
    
    let secrets: [any SecretValue]
    let projectService: any SecretsSupported
    
    var body: some View {
        HStack(spacing: 0) {
            Form {
                Section {
                    ForEach(secrets, id: \.id) { secret in
                        if let _secret = secret as? any TextSecretValue {
                            SecretValueTextView(initialValue: _secret)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            if projectService.secretsScreenSidebarActions.isEmpty == false {
                AppSidebar {
                    SidebarCustomSections(sections: projectService.secretsScreenSidebarActions)
                }
            }
        }
    }
}
