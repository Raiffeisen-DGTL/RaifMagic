//
//  GradientView.swift
//  RaifMagic
//
//  Created by SHUMAKOV Kirill on 25.06.2024.
//

import SwiftUI

struct BlobGradient: View {
    private var blobs: [Color]
    private var highlights: [Color]
    private var speed: CGFloat
    private var blur: CGFloat
    
    @State var blurValue: CGFloat = 0.0
    
    init(blobs: [Color],
                highlights: [Color] = [],
                speed: CGFloat = 1.0,
                blur: CGFloat = 0.75) {
        self.blobs = blobs
        self.highlights = highlights
        self.speed = speed
        self.blur = blur
    }
    
    var body: some View {
        BlobGradientRepresentable(
            blobs: blobs,
            highlights: highlights,
            speed: speed,
            blurValue: $blurValue
        )
        .blur(radius: pow(blurValue, blur))
    }
}


// MARK: - Representable
private extension BlobGradient {
    struct BlobGradientRepresentable: NSViewRepresentable {
        var blobs: [Color]
        var highlights: [Color]
        var speed: CGFloat
        
        @Binding var blurValue: CGFloat
        
        func makeNSView(context: Context) -> BlobGradientView {
            context.coordinator.view
        }
        
        func updateNSView(_ view: BlobGradientView, context: Context) { }

        func makeCoordinator() -> Coordinator {
            Coordinator(blobs: blobs,
                        highlights: highlights,
                        speed: speed,
                        blurValue: $blurValue)
        }
    }
    
    @MainActor
    class Coordinator: @preconcurrency GradientViewDelegate {
        var blurValue: Binding<CGFloat>
        
        var view: BlobGradientView
        
        init(
            blobs: [Color],
             highlights: [Color],
             speed: CGFloat,
             blurValue: Binding<CGFloat>
        ) {
            self.blurValue = blurValue
            self.view = BlobGradientView(
                blobs: blobs,
                highlights: highlights,
                speed: speed
            )
            self.view.delegate = self
        }
        
        func updateBlurAfterFrameChanged(_ value: CGFloat) {
            blurValue.wrappedValue = value
        }
    }
}
