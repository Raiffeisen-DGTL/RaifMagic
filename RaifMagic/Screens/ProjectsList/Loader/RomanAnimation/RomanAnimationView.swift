//
//  WaveAnimationsView.swift
//  RaifMagic
//
//  Created by ANPILOV Roman on 27.11.2024.
//

import SwiftUI

struct WaveAnimationsView: View {
    private let startDate = Date()

    @Binding var didEndAnimation: Bool
    
    var body: some View {
        TimelineView(.animation) { _ in
            ZStack {
                Text("RaifMagic")
                    .font(.system(size: 120, weight: .bold))
                    .kerning(-1.5)
                    .padding(.vertical, 50)
                    .drawingGroup()
                    .distortionEffect(ShaderLibrary.waveText(
                        .float(startDate.timeIntervalSinceNow)
                    ), maxSampleOffset: .init(width: 0, height: 50))
                    .zIndex(1)
                Color.white
                    .visualEffect { content, proxy in
                        content
                            .colorEffect (
                                ShaderLibrary.waveColor(
                                    .float2(proxy.size),
                                    .float(startDate.timeIntervalSinceNow)
                                )
                            )
                    }
                    .zIndex(0)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .task {
            try? await Task.sleep(for: .seconds(3))
            didEndAnimation = true
        }
    }
}
