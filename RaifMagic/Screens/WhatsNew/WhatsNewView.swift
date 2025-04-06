//
//  SwiftUIView.swift
//  
//
//  Created by USOV Vasily on 20.05.2024.
//

import SwiftUI

struct WhatsNewView: View {
    
    let whatsNew: [WhatsNewItem]
    
    var body: some View {
        List {
            ForEach(whatsNew) { item in
                WhatsNewItemView(version: item.version,
                                 whatsAdded: item.added,
                                 whatsImproved: item.improved)
            }
        }
    }
}

private struct WhatsNewItemView: View {
    let version: String
    let whatsAdded: [String]
    let whatsImproved: [String]
    
    var body: some View {
        Section {
            Text("Версия \(version)")
                .font(.title.weight(.medium))
            
            if whatsAdded.count > 0 {
                changesListView("Добавлено", whatsAdded)
            }
            
            if whatsImproved.count > 0 {
                changesListView("Исправлено", whatsImproved)
            }
        }
    }
    
    @ViewBuilder
    private func changesListView(_ title: String, _ changes: [String]) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .padding(.top, 10)
        ForEach(changes, id: \.self) { item in
            Text("- \(item)")
                .listRowSeparator(.hidden)
        }
    }
}
