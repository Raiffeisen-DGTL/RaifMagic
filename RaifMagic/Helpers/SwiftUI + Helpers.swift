//
//  SwiftUI + Helpers.swift
//  RaifMagic
//
//  Created by USOV Vasily on 27.09.2024.
//

import SwiftUI

// Function for binding the value after casting to the original model
// Used when you need to pass not the entire model of the pod to the view, but only its part corresponding to a certain protocol or type
@MainActor
public func binding<T, R>(_ subcontainer: T, to: Binding<R>) -> Binding<T> {
    Binding(get: { subcontainer }, set: { instance in
        guard let podInstance = instance as? R else { return }
        to.wrappedValue = podInstance
    })
}

// Function for binding a specific property of a value after casting to the original model
// Used when you need to pass not the entire model of the pod to the view, but only its specific property
@MainActor
func binding<T, V, R>(_ subcontainer: T, key: WritableKeyPath<T, V>, to: Binding<R>) -> Binding<V> {
    Binding {
        subcontainer[keyPath: key]
    } set: { newValue in
        var mutableContainer = subcontainer
        mutableContainer[keyPath: key] = newValue
        guard let resultContainer = mutableContainer as? R else { return }
        to.wrappedValue = resultContainer
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
