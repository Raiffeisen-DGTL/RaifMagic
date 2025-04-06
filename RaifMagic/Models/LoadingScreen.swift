//
//  LoadingScreen.swift
//  RaifMagic
//
//  Created by USOV Vasily on 24.07.2024.
//

import Foundation

enum LoadingScreen: Int, Identifiable, CustomStringConvertible, CaseIterable {
    case animatedMagic
    case sleepMagical
    case waveRaifMagic
    
    var id: Self { self }
    var description: String {
        switch self {
            case .animatedMagic: return "Магическая магия"
            case .sleepMagical: return "Спящий волшебник"
            case .waveRaifMagic: return "Волнения Мэджика"
        }
    }
    
    var imageName: String {
        switch self {
        case .animatedMagic:
            "loadingMagic"
        case .sleepMagical:
            "loadingWorker"
        case .waveRaifMagic:
            "loadingWaves"
        }
    }
}
