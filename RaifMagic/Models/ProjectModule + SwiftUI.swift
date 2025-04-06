//
//  ProjectIntergator + Types.swift
//  RaifMagic
//
//  Created by USOV Vasily on 13.02.2025.
//

import SwiftUI

// Implementation with type erasure
// Will be used as a dumb wrapper exactly until
// SwiftUI.Table allows passing id, like ForEach
// Now when passing modules to SwiftUI.Table, you have to wrap them in this object
struct AnyBindingModule: Identifiable, Hashable, Equatable {
    
    static func == (lhs: AnyBindingModule, rhs: AnyBindingModule) -> Bool {
        lhs.module.wrappedValue.compare(with: rhs.module.wrappedValue)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.module.wrappedValue.id)
    }
    
    var id: Int {
        module.wrappedValue.id
    }
    var module: Binding<any IProjectModule>
    init(module: Binding<any IProjectModule>) {
        self.module = module
    }
}

// Implementation with type erasure
// Will be used as a dumb wrapper where pods need to conform to the Equatable protocol (e.g. onChange)
struct AnyWrappedModule: Identifiable, Equatable {
    static func == (lhs: AnyWrappedModule, rhs: AnyWrappedModule) -> Bool {
        lhs.module.compare(with: rhs.module)
    }

    var id: Int {
        module.id
    }
    var module: any IProjectModule
    init(module: any IProjectModule) {
        self.module = module
    }
}
