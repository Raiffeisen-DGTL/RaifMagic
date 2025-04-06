//
//  BlobGradientView.swift
//  RaifMagic
//
//  Created by SHUMAKOV Kirill on 25.06.2024.
//

import SwiftUI
import Combine

protocol GradientViewDelegate: AnyObject {
    func updateBlurAfterFrameChanged(_ value: CGFloat)
}

 class ResizableLayer: CALayer {
    override init() {
        super.init()
        autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BlobGradientView: NSView {
    private var speed: CGFloat
    
    private let baseLayer = ResizableLayer()
    private let blendModeLayer = ResizableLayer()
    
    private var cancellables = Set<AnyCancellable>()
    
    weak var delegate: GradientViewDelegate?
    
    init(
        blobs: [Color] = [],
        highlights: [Color] = [],
        speed: CGFloat = 1.0
    ) {
        self.speed = speed
        super.init(frame: .zero)
        
        
        setupLayers()
        draw(blobs, layer: baseLayer)
        draw(highlights, layer: blendModeLayer)
        animate(speed: speed)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidMoveToWindow() {
       super.viewDidMoveToWindow()
       let scale = window?.backingScaleFactor ?? 2
       layer?.contentsScale = scale
       baseLayer.contentsScale = scale
       blendModeLayer.contentsScale = scale
       updateBlur()
   }
   
    override func resize(withOldSuperviewSize oldSize: NSSize) {
       updateBlur()
   }
    
    private func setupLayers() {
        if let compositingFilter = CIFilter(name: "CIOverlayBlendMode") {
            blendModeLayer.compositingFilter = compositingFilter
        }
        
        layer = ResizableLayer()
        
        wantsLayer = true
        postsFrameChangedNotifications = true
        
        layer?.delegate = self
        baseLayer.delegate = self
        blendModeLayer.delegate = self
        
        self.layer?.addSublayer(baseLayer)
        self.layer?.addSublayer(blendModeLayer)
        
    }
    
    private func draw(_ colors: [Color], layer: CALayer) {
         colors.forEach {
             layer.addSublayer(BlobLayer(color: $0))
         }
    }
    
     private func animate(speed: CGFloat) {
         let layers = (self.baseLayer.sublayers ?? []) + (self.blendModeLayer.sublayers ?? [])
         
         layers.forEach { layer in
             guard  let blobLayer = layer as? BlobLayer else { return }
             Timer.publish(
                every: .random(in: 0.8/speed...1.2/speed),
                on: .main,
                in: .common
             )
             .autoconnect()
             .sink { _ in
                 let visible = self.window?.occlusionState.contains(.visible)
                 guard visible == true else { return }
                 blobLayer.animate(speed: speed)
             }
             .store(in: &cancellables)
         }
    }
    
    private func updateBlur() {
        delegate?.updateBlurAfterFrameChanged(min(frame.width, frame.height))
    }
}

extension BlobGradientView: CALayerDelegate, NSViewLayerContentScaleDelegate {
    public func layer(_ layer: CALayer,
                      shouldInheritContentsScale newScale: CGFloat,
                      from window: NSWindow) -> Bool {
        true
    }
}
