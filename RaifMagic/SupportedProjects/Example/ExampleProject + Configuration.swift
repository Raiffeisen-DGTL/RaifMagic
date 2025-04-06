//
//  RMobileConfiguration.swift
//  RaifMagic
//
//  Created by USOV Vasily on 12.02.2025.
//

import Foundation

extension ExampleProject {
    
    struct ProjectConfiguration: IProjectConfiguration, Decodable {
        var projectID: String
        let minimalSupportedRaifMagicVersion: AppVersionIdentifier
        
        init?(configurationFileURL: URL) {
            guard let configurationFileContent = try? Data(contentsOf: configurationFileURL),
                  let decoded = try? JSONDecoder().decode(Self.self, from: configurationFileContent)
            else { return nil }
            self = decoded
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.projectID = try container.decode(String.self, forKey: .projectID)
            
            let minVersion = try container.decode(String.self, forKey: .minimalSupportedRaifMagicVersion)
            let splittedVersion = minVersion.split(separator: ".")
            guard splittedVersion.count == 3, let major = Int(splittedVersion[0]), let minor = Int(splittedVersion[1]), let patch = Int(splittedVersion[2]) else {
                throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.minimalSupportedRaifMagicVersion], debugDescription: "Ошибка в синтаксисе версии"))
            }
            minimalSupportedRaifMagicVersion = AppVersionIdentifier(major: major, minor: minor, patch: patch, isBeta: false)
        }
        
        enum CodingKeys: String, CodingKey {
            case projectID = "project_id"
            case minimalSupportedRaifMagicVersion = "minimal_raif_magic_version"
        }
    }
}
