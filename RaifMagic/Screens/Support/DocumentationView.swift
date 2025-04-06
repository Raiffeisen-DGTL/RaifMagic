//
//  Documentation.swift
//  RaifMagic
//
//  Created by USOV Vasily on 08.10.2024.
//

import SwiftUI

struct DocumentationView: View {
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [.init(.adaptive(minimum: 300, maximum: 400),
                                spacing: 20, alignment: .topLeading)],
                alignment: .leading) {
                    docItem
                }
                .padding()
        }
    }
    
    private var docItem: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: "doc.text")
                .resizable()
                .frame(width: 30, height: 35)
            Text("Документация")
                .font(.title)
            Text("Узнайте, как настроить RaifMagic и решить все возникающие проблемы")
                .multilineTextAlignment(.center)
            Button {
                if let url = URL(string: "https://github.com/Raiffeisen-DGTL/RaifMagic") {
                    openURL(url)
                }
            } label: {
                Text("Открыть")
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .systemFill))
            
        }
    }
}

#Preview {
    DocumentationView()
        .frame(width: 500, height: 500)
}
