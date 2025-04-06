//
//  TerminalType.swift
//  RaifMagic
//
//  Created by USOV Vasily on 04.06.2024.
//

import Foundation

enum GenerateType: Int, CaseIterable, CustomStringConvertible, Identifiable {
    case external = 0
    case local
    
    var id: Self { self }
    var description: String {
        switch self {
        case .external: return "Внешний терминал"
        case .local: return "Внутренняя консоль"
        }
    }
}
