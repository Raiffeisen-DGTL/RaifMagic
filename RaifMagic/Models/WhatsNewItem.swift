//
//  WhatsNewModel.swift
//  RaifMagic
//
//  Created by USOV Vasily on 22.08.2024.
//

import SwiftUI

struct WhatsNewItem: Identifiable {
    var id: Int {
        version.hashValue
    }
    let version: String
    let added: [String]
    let improved: [String]
}
