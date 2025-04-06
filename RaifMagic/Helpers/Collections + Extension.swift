//
//  Collections + Extension.swift
//  RaifMagic
//
//  Created by USOV Vasily on 01.07.2024.
//

import Foundation

extension Sequence {
    func asyncMap<T>(
        _ transform: @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}

extension Sequence {
    func asyncForEach(
        _ operation: @Sendable (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
