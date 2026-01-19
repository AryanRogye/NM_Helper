//
//  SidebarWorkspaceTabView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/19/26.
//

import SwiftUI

struct SidebarWorkspaceTabView: View {
    @Bindable var vm: NMViewModel

    var body: some View {
        Sidebar(vm: vm)
    }
}
