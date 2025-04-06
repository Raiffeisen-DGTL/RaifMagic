//
//  SelectProjectView.swift
//  RaifMagic
//
//  Created by USOV Vasily on 17.06.2024.
//

import SwiftUI

struct ProjectsListMainView: View {
    
    @Binding var projectURLs: [URL]
    @Binding var arguments: [String]?
    @Binding var selectedProject: (any IProject)?
    let forceOpenProjectList: Bool
    
    @State private var isAddingNewProject = false
    @State private var navigationPath = NavigationPath()
    
    let di: IAppDIContainer
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if projectURLs.isEmpty {
                    noProjectInfo
                } else {
                    ProjectsListView(selectedProject: $selectedProject,
                                     projectURLs: $projectURLs,
                                     arguments: $arguments,
                                     forceOpenProjectList: forceOpenProjectList,
                                     di: di)
                }
            }
            .navigationDestination(for: Subscreen.self, destination: { screen in
                switch screen {
                case .updates:
                    GlobalUpdateAppVersionView(appUpdaterService: di.appUpdaterService)
                }
            })
        }
        .toolbar {
            VStack(spacing: 0) {
                Button {
                    navigationPath.append(Subscreen.updates)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .padding(.horizontal, 4)
                }
                Text("Обновления")
                    .font(.footnote)
                    .padding(.top, -3)
                    .foregroundStyle(Color.secondary)
            }
        }
        .animation(.default.speed(2), value: isAddingNewProject)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.folder],
                delegate: AddProjectDropDelegate(isAddingNewProject: $isAddingNewProject, di: di) { url in
            Task { @MainActor in
                if projectURLs.contains(where: { url == $0 }) == false {
                    projectURLs.append(url)
                }
            }
        })
        .overlay(alignment: .center, content: {
            if isAddingNewProject {
                ZStack {
                    Color(nsColor: NSColor.windowBackgroundColor)
                    VStack {
                        Image(systemName: "folder.fill.badge.plus")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, alignment: .center)
                        Text("Отпустите, чтобы добавить новый проект")
                            .font(.title)
                    }
                }
            }
        })
        .navigationTitle("Менеджер проектов")
    }
    
    private var noProjectInfo: some View {
        Group {
            Text("Добро пожаловать в RaifMagic")
                .font(.title)
            Text("Чтобы начать магию - добавь новый проект.\nДля этого перетянути папку с проектом прямо сюда")
                .font(.title2)
        }
        .multilineTextAlignment(.center)
    }
    
    // MARK: - Subtypes
    
    private enum Subscreen: String, Hashable {
        case updates
    }
}
