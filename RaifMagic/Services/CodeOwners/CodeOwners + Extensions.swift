//
//  CodeOwners + Extensions.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.02.2025.
//

extension Logger: @retroactive CodeOwnersServiceLogger {
    nonisolated public func log(codeOwnerServiceMessage message: String) {
        Task {
            await self.log(.debug, message: "[CodeOwnerService] \(message)")
        }
    }
}
