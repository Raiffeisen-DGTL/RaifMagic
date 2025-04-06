//
//  EnvironmentService.swift
//  RaifMagic
//
//  Created by USOV Vasily on 07.06.2024.
//

import Foundation
import SwiftUI
import ServiceManagement
import CommandExecutor
import MagicIntegration

/// Service for working with user environment
/// Environment installation, application version update, password update - everything here
protocol IAppUpdaterService: Sendable {
    /// Download available versions of the application
    func fetchAvailableAppVersions() async throws -> [AppVersionIdentifier]
    
    /// Next available version without breaking changes after current version
    func lastAvailableAppVersion(
        after requiredVersion: AppVersionIdentifier,
        comparedWith currentVersion: AppVersionIdentifier
    ) async throws -> AppVersionIdentifier?

    /// Update application
    func updateApp(toVersion: AppVersionIdentifier) async throws
}

final class JFrogAppUpdaterService: IAppUpdaterService {
    private let logger: Logger
    private let commandExecutor: CommandExecutor
    private let artifactoryRepoPath: String
        
    private enum Config {
        static let releaseGUIArchiveName = "raifMagic"
        static let artifactoryVersionsFileName = "versions.json"
        
    }
    
    init(logger: Logger, commandExecutor: CommandExecutor, artifactoryRepoPath: String) {
        self.logger = logger
        self.commandExecutor = commandExecutor
        self.artifactoryRepoPath = artifactoryRepoPath
    }
    
    // TODO: work with beta
    func lastAvailableAppVersion(
        after requiredVersion: AppVersionIdentifier,
        comparedWith currentVersion: AppVersionIdentifier
    ) async throws -> AppVersionIdentifier? {
        guard let lastAvailableAppVersion = try await lastAvailableAppVersion(onMajor: requiredVersion.major) else {
            return nil
        }
        return lastAvailableAppVersion.isVersionHigher(than: currentVersion) ? lastAvailableAppVersion : nil
    }
    
    func updateApp(toVersion version: AppVersionIdentifier) async throws {
        let versions = try await fetchAvailableAppVersions()
        guard versions.contains(where: { $0.major == version.major && $0.minor == version.minor && $0.patch == version.patch && $0.isBeta == version.isBeta }) else {
            throw EnvironmentServiceError.tryUpdateToUnavailableAppVersion
        }
        
        try await updateGUI(toVersion: version)
    }
    
    private func updateGUI(toVersion version: AppVersionIdentifier) async throws {
        @AppStorage("artifactoryAPIKey") var artifactoryAccessToken = ""
        try? FileManager.default.removeItem(atPath: AppConfig.temporaryDirectory + "/\(Config.releaseGUIArchiveName).zip")
        try await commandExecutor.execute(textCommand: "rm -fr \(Config.releaseGUIArchiveName).app", atPath: AppConfig.temporaryDirectory)
        try await commandExecutor.execute(textCommand: "curl --header \"X-JFrog-Art-Api: \(artifactoryAccessToken)\" \"\(artifactoryRepoPath)/\(version.asString)/\(Config.releaseGUIArchiveName).zip\" --output \(AppConfig.temporaryDirectory)/\(Config.releaseGUIArchiveName).zip")
        try await commandExecutor.execute(textCommand: "unzip \(Config.releaseGUIArchiveName).zip", atPath: AppConfig.temporaryDirectory)
        try? FileManager.default.removeItem(atPath: AppConfig.temporaryDirectory + "/\(Config.releaseGUIArchiveName).zip")
        try FileManager.default.removeItem(atPath: Bundle.main.bundlePath)
        try await commandExecutor.execute(textCommand: "cp -R RaifMagic.app \(Bundle.main.bundlePath)", atPath: AppConfig.temporaryDirectory)
        
        Task {
            try await Task.sleep(for: .seconds(1))
            let proc = Process()
            proc.executableURL = Bundle.main.executableURL
            try proc.run()
            await MainActor.run {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    public func fetchAvailableAppVersions() async throws -> [AppVersionIdentifier] {
        try await fetchAvailableRawAppVersions().map(\.asAppVersionIdentifier)
    }
    
    /// Requests and returns data about available versions in raw form (as DTO)
    private func fetchAvailableRawAppVersions() async throws -> [AppVersionDTO] {
        @AppStorage("artifactoryAPIKey") var artifactoryAccessToken = ""
        let url = URL(string: "\(artifactoryRepoPath)/\(Config.artifactoryVersionsFileName)")!
        var request = URLRequest(url: url)
        request.addValue(artifactoryAccessToken, forHTTPHeaderField: "X-JFrog-Art-Api")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([AppVersionDTO].self, from: data)
    }
    
    /// Retrieves the last available version of the app for a specific major version.
    ///
    /// - Parameters:
    ///   - major: The major version number. Only versions without breaking changes with this exact major version number are considered.
    ///   - includeBeta: A Boolean value indicating whether to include beta versions in the search. Defaults to `false`.
    /// - Returns: An optional `AppVersionIdentifier` representing the highest version available for the specified major version, or `nil` if no such version is found.
    private func lastAvailableAppVersion(onMajor major: Int, includeBeta: Bool = false) async throws -> AppVersionIdentifier? {
        try await fetchAvailableAppVersions()
            .filter { $0.major == major }
            .filter { includeBeta ? true : !$0.isBeta }
            .sorted { $0.isVersionHigher(than: $1) }
            .first
    }
}

private struct AppVersionDTO: Codable, AppVersionDescribable {
    let major: Int
    let minor: Int
    let patch: Int
    let isBeta: Bool
    let publishedAt: Date
    let updatedAt: Date
    
    var asAppVersionIdentifier: AppVersionIdentifier {
        AppVersionIdentifier(major: major, minor: minor, patch: patch, isBeta: isBeta)
    }
}

enum EnvironmentServiceError: Error {
    case tryUpdateToUnavailableAppVersion
}


