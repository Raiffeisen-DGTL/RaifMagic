//
//  SleepMagical.swift
//  RaifMagic
//
//  Created by USOV Vasily on 24.07.2024.
//

import Foundation
import SwiftUI

struct SleepMagical: View {
    
    @Binding var didEndAnimation: Bool
    
    @State private var showTitle = false
    @State private var showSubtitle = false
    
    var body: some View {
        VStack(spacing: 10) {
            Image("sleepMagicWorker")
                .resizable()
                .frame(width: 100, height: 100)
                .cornerRadius(50)
                .task {
                    try? await Task.sleep(for: .seconds(0.2))
                    withAnimation {
                        showTitle = true
                    }
                    try? await Task.sleep(for: .seconds(0.2))
                    withAnimation {
                        showSubtitle = true
                    } completion: {
                        didEndAnimation = true
                    }
                }
            if showTitle {
                Text("RaifMagic")
                    .font(.title)
            }
            if showSubtitle {
                Text("Make RaifMagic great again")
                    .padding(.top, -8)
            }
        }
    }
}
