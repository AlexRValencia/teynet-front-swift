import SwiftUI

enum TabSelection {
    case monitoring
    case projects
    case maintenance
    case reports
    case inventory
    case admin
}

class MainTabViewModel: ObservableObject {
    @Published var selectedTab: TabSelection = .projects
    
    func navigateTo(_ tab: TabSelection) {
        withAnimation {
            selectedTab = tab
        }
    }
} 