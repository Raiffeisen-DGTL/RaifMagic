//
//  AnalyticsService.swift
//  RaifMagic
//
//  Created by USOV Vasily on 15.10.2024.
//
import Foundation

protocol IAnalyticsService: Sendable {
    func log(event: AnalyticsEvent)
}

final class FirebaseAnalyticsService: IAnalyticsService {
    func log(event: AnalyticsEvent) {
        switch event {
        case .openProject: return
        case let .openScreen(name, additional): return
        case let .startGenerateProject(raifMagic: raifMagic, xcode: xcode, method: method): return
        case .endGeneration(duration: let duration): return
        case .failureGeneration: return
        case .useSwiftFormat(forModule: let name): return
        }
    }
}

enum AnalyticsEvent {
    case openProject
    case openScreen(name: String, additionalData: [String: Any] = [:])
    case startGenerateProject(raifMagic: String, xcode: String, method: GenerationMethod)
    case endGeneration(duration: TimeInterval)
    case failureGeneration
    case useSwiftFormat(forModule: String)
    
    enum GenerationMethod: String {
        case externalTerminal
        case internalConsole
    }
}
