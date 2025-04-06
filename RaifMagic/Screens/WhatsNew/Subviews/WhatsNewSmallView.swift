//
//  WhatsNewSmallView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 22.08.2024.
//

import SwiftUI

struct WhatsNewSmallView: View {
    
    let showingItems: [WhatsNewItem]
    @Binding var show: Bool
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
                Text("Что нового?")
                    .font(.title)
                    .bold()
                ForEach(showingItems) { item in
                    Text("Версия " + item.version)
                        .font(.title2)
                        .bold()
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                    if item.added.count > 0 {
                        Text("Добавлено")
                            .font(.title3)
                            .bold()
                            .padding(.bottom, 1)
                        ForEach(item.added, id: \.self) { addedLine in
                            Text("- \(addedLine)")
                        }
                    }
                    if item.improved.count > 0 {
                        Text("Исправлено")
                            .font(.title3)
                            .bold()
                            .padding(.top, 10)
                            .padding(.bottom, 1)
                        ForEach(item.improved, id: \.self) { addedLine in
                            Text("- \(addedLine)")
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 400, height: 400, alignment: .center)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing, content: {
            Button(action: {
                show = false
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.primary)
                    .frame(width: 30, height: 30)
            })
            .buttonStyle(.plain)
            .padding()
            
        })
    }
}

//#Preview {
//    Color.gray
//        .frame(width: 500, height: 500)
//        .padding()
//        .overlay(alignment: .center) {
//            WhatsNewSmallView(show: .constant(true))
//        }
//}
