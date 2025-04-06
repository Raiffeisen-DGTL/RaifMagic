//
//  CodeStyler + Extensions.swift
//  RaifMagic
//
//  Created by USOV Vasily on 01.04.2025.
//

extension Logger: @retroactive ICodeStylerLogger {
    public func log(error: String) {
        Task {
            await self.log(.warning, message: "[CodeStyler] \(error)")
        }
    }
    
    public func log(message: String) {
        Task {
            await self.log(.debug, message: "[CodeStyler] \(message)")
        }
    }
}
