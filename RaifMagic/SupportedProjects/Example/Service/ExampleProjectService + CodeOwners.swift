//
//  ExampleProjectService + CodeOwners.swift
//  RaifMagic
//
//  Created by USOV Vasily on 14.02.2025.
//

extension ExampleProject.ProjectService: CodeOwnersSupported {    
    var codeOnwersDeveloperTeamMemberInfoFetcher: any DeveloperTeamMemberInfoFetcher {
        GitlabAPIService(baseUrlPath: "https://gitlabci.yourcompany.ru", projectID: 0) {
            "Gitlab Token"
        }
    }
}

extension GitlabAPIService: @retroactive DeveloperTeamMemberInfoFetcher {
    public func fetchTeamMember(byUsername username: String) async throws -> DeveloperTeam.Member? {
        guard let user = try await fetchUserInfo(byUsername: username) else {
            return nil
        }
        return DeveloperTeam.Member(username: username, name: user.name, gitlabID: user.gitlabID)
    }
}
