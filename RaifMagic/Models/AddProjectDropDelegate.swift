//
//  DropDelegate.swift
//  RaifMagic
//
//  Created by USOV Vasily on 28.05.2024.
//

import SwiftUI

struct AddProjectDropDelegate: DropDelegate {
    @Binding var isAddingNewProject: Bool
    let di: IAppDIContainer
    let needAddURLWithProjects: @Sendable (URL) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        var hasProviders = false
        info.itemProviders(for: [.fileURL]).forEach { [needAddURLWithProjects] provider in
            hasProviders = true
            let _ = provider.loadObject(ofClass: URL.self) { url, error in
                if let error {
                    Task {
                        await di.logger.log(.warning, message: error.localizedDescription)
                    }
                    return
                }
                guard let url else {
                    Task {
                        await di.logger.log(.warning, message: "Не удалось распарсить адрес добавленного объекта. Адрес - \(url?.absoluteString ?? "nil")")
                    }
                    return
                }
                needAddURLWithProjects(url)
            }
        }
        return hasProviders ? true : false
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        isAddingNewProject = true
        return nil
    }
    
    func dropEntered(info: DropInfo) {
        isAddingNewProject = true
    }
    
    func dropExited(info: DropInfo) {
        isAddingNewProject = false
    }
}
