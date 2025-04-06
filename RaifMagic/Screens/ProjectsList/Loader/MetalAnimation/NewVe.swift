//
//  NewVe.swift
//  RaifMagic
//
//  Created by SHUMAKOV Kirill on 28.06.2024.
//

import SwiftUI

struct AnimatedMagic: View {
    @State var progress = 0.0
    @Binding var didEndAnimation: Bool
    
    var body: some View {
        ZStack {
            BlobGradient(
                blobs: GradientColorPalete.randomColors(),
                highlights: GradientColorPalete.randomColors(),
                speed: 1.5
            )
            WritingAnimation(progress: $progress)
        }.onAppear {
            withAnimation(.linear(duration: 3)) {
                progress = 1
            } completion: {
                withAnimation(.linear(duration: 0.3)) {
                    didEndAnimation = true
                }
            }
        }
    }
}

private enum GradientColorPalete {
    static let colors: [Color] =  [.teal, .blue, .purple, .white]
    
    static func randomColors() -> [Color] {
        var cc = [Color]()
        for _ in 0...Int.random(in: 5...5) {
            cc.append(colors.randomElement()!)
        }
        return cc
    }
}

private struct WritingAnimation: View {
    @Binding var progress: Double
    
    var body: some View {
        MyIcon()
            .trim(from: 0.0, to: progress)
            .stroke(
                style: StrokeStyle(
                    lineWidth: 40,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .fill(
                LinearGradient(
                    gradient: Gradient(
                        colors: GradientColorPalete.randomColors()
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            .padding(150)
    }
}

#Preview {
    AnimatedMagic(didEndAnimation: .constant(true))
}

#Preview {
    WritingAnimation(progress: .constant(0))
}
