//
//  AppConfig.swift
//  RaifMagic
//
//  Created by USOV Vasily on 11.03.2025.
//

import AppKit

public enum AppConfig {
    /// Folder containing logs and other auxiliary files
    /// Also used for automatic project updates
    public static let temporaryDirectory = NSHomeDirectory() + "/raifMagic"
    /// Scheme when opening an application via deep link
    public static let scheme = "raifmagic"
    /// Version ID
    public static var appVersion: AppVersionIdentifier {
        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return AppVersionIdentifier(major: 0, minor: 0, patch: 0, isBeta: false)
        }
        let isBeta = versionString.hasSuffix("beta")
        let cleanedVersion = isBeta ? String(versionString.dropLast("beta".count)) : versionString
        let components = cleanedVersion.split(separator: ".")
        
        guard components.count == 3,
              let major = Int(components[0]),
              let minor = Int(components[1]),
              let patch = Int(components[2])
        else {
            return AppVersionIdentifier(major: 0, minor: 0, patch: 0, isBeta: false)
        }
        
        return AppVersionIdentifier(major: major, minor: minor, patch: patch, isBeta: isBeta)
    }
}
