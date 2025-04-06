//
//  ProjectsList.swift
//  RaifMagic
//
//  Created by USOV Vasily on 03.03.2025.
//

import SwiftUI

struct ProjectsListView: View {
    
    @Binding var projectURLs: [URL]
    @Binding var selectedProject: (any IProject)?
    @Binding var arguments: [String]?
    let forceOpenProjectList: Bool
    let di: IAppDIContainer
    private var projects: [any IProject]
    private var notSupportedURLs: [URL]
    
    @State private var showUI: Bool = false
    
    init(selectedProject: Binding<(any IProject)?>, projectURLs: Binding<[URL]>, arguments: Binding<[String]?>, forceOpenProjectList: Bool, di: IAppDIContainer) {
        self._projectURLs = projectURLs
        self.forceOpenProjectList = forceOpenProjectList
        self.di = di
        self._selectedProject = selectedProject
        var notSupportedURLs: [URL] = []
        var supportedProjects: [any IProject] = []
        projectURLs.wrappedValue.forEach { url in
            let projectsFromURL = di.projectsLoader.loadSupportedProjects(forURL: url)
            if projectsFromURL.isEmpty {
                notSupportedURLs.append(url)
            } else {
                supportedProjects.append(contentsOf: projectsFromURL)
            }
        }
        self.projects = supportedProjects
        self.notSupportedURLs = notSupportedURLs
        self._arguments = arguments
    }
    
    var body: some View {
        Form {
            Section {
                ForEach(projects, id: \.id) { project in
                    HStack {
                        Button {
                            selectedProject = project
                        } label: {
                            VStack(alignment: .leading) {
                                Text(project.projectID)
                                    .font(.title2)
                                Text(project.url.path())
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: {
                            projectURLs.removeAll(where: { $0 == project.url })
                        }, label: {
                            Image(systemName: "trash")
                        })
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            if notSupportedURLs.isEmpty == false {
                Section {
                    ForEach(notSupportedURLs, id: \.self) { url in
                        HStack {
                            Text(url.path())
                            Spacer()
                            Button(action: {
                                projectURLs.removeAll(where: { $0 == url })
                            }, label: {
                                Image(systemName: "trash")
                            })
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } header: {
                    Text("Остальные URL")
                } footer: {
                    Text("В данном разделе указаны добавленные URL, в которых нет поддерживаемых проектов. Возможно на текущем коммите еще не добавлены необходимые файлы для поддержки проекта")
                        .font(.footnote)
                }
                
            }
        }
        .opacity(showUI ? 1 : 0)
        .formStyle(.grouped)
        .task {
            // TODO: .task (with sleep for safety, or without it) lets execute onOpenURL, but for one moment user see current view
            do {
                try await Task.sleep(for: .seconds(0.3))
                
                if forceOpenProjectList == false, projects.count == 1, selectedProject == nil {
                    selectedProject = projects[0]
                } else {
                    withAnimation {
                        showUI = true
                    }
                }
            } catch {}
        }
    }
    
    private func openProjectIfNeeded() {
        guard selectedProject == nil else { return }
        if projects.count == 1 {
            selectedProject = projects[0]
        }
    }
}
