import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSessionExpiredAlert = false
    @StateObject private var maintenanceManager = MaintenanceManager()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView(maintenanceManager: maintenanceManager)
            } else {
                LoginView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SessionExpired"))) { _ in
            showSessionExpiredAlert = true
        }
        .alert(isPresented: $showSessionExpiredAlert) {
            Alert(
                title: Text("Sesión expirada"),
                message: Text("Su sesión ha expirado. Por favor inicie sesión nuevamente."),
                dismissButton: .default(Text("OK")) {
                    authViewModel.logout()
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
} 