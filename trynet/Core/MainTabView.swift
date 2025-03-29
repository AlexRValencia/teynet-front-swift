import SwiftUI

struct MainTabView: View {
    @StateObject private var tabViewModel = MainTabViewModel()
    @ObservedObject var maintenanceManager: MaintenanceManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showReconnectAlert = false
    
    // Color personalizado para la barra de pestañas
    private let selectedTabColor = Color.blue
    private let unselectedTabColor = Color.gray
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Barra de navegación personalizada
                navigationBar
                
                // Contenido principal con TabView
                TabView(selection: $tabViewModel.selectedTab) {
                    ProjectsView()
                        .tabItem {
                            Label("Proyectos", systemImage: "list.bullet.clipboard")
                                .accessibility(label: Text("Gestión de proyectos"))
                        }
                        .tag(TabSelection.projects)
                        
                    MaintenanceView(maintenanceManager: maintenanceManager)
                        .tabItem {
                            Label("Mantenimiento", systemImage: "wrench.and.screwdriver")
                                .accessibility(label: Text("Tareas de mantenimiento"))
                        }
                        .tag(TabSelection.maintenance)
                    
                    ReportsView()
                        .tabItem {
                            Label("Reportes", systemImage: "chart.bar")
                                .accessibility(label: Text("Reportes y análisis"))
                        }
                        .tag(TabSelection.reports)
                    
                    InventoryView()
                        .tabItem {
                            Label("Inventario", systemImage: "shippingbox")
                                .accessibility(label: Text("Gestión de inventario"))
                        }
                        .tag(TabSelection.inventory)
                        
                    MonitoringView()
                        .tabItem {
                            Label("Monitoreo", systemImage: "waveform.path.ecg")
                                .accessibility(label: Text("Monitoreo en vivo"))
                        }
                        .tag(TabSelection.monitoring)
                    
                    // Pestaña de administración solo visible para administradores
                    if isAdmin {
                        UserAdminView()
                            .tabItem {
                                Label("Administración", systemImage: "person.2.badge.gearshape")
                                    .accessibility(label: Text("Administración del sistema"))
                            }
                            .tag(TabSelection.admin)
                            // Usar lazy loading para que solo se cargue cuando se seleccione esta pestaña
                            .task {
                                // Solo cargar datos cuando esta pestaña esté activa
                                if tabViewModel.selectedTab == .admin {
                                    print("🔄 Pestaña de administración activa - cargando datos...")
                                }
                            }
                    }
                }
            }
            
            // Mensaje de confirmación para biometría
            if authViewModel.showBiometricConfirmation {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: authViewModel.biometricType.iconName)
                            .foregroundColor(.white)
                        
                        Text(authViewModel.biometricConfirmationMessage)
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.8))
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)
                }
                .zIndex(100)
                .transition(.opacity)
                .animation(.easeInOut, value: authViewModel.showBiometricConfirmation)
            }
        }
        .accentColor(selectedTabColor) // Color para pestañas seleccionadas
        .onAppear {
            // Configuración de la apariencia de UITabBar
            setupTabBarAppearance()
            
            // Intentar reconectar al backend si estamos en modo fallback
            if authViewModel.isUsingFallback {
                authViewModel.reconnectToBackend()
            }
        }
        .alert("¿Reconectar al servidor?", isPresented: $showReconnectAlert) {
            Button("Cerrar sesión y reconectar", role: .destructive) {
                authViewModel.logout()
            }
            Button("Seguir en modo fallback", role: .cancel) { }
        } message: {
            Text("Se ha detectado que el servidor local está disponible. ¿Deseas cerrar sesión y reconectar usando el backend real?")
        }
    }
    
    // Verificar si el usuario es administrador
    private var isAdmin: Bool {
        return authViewModel.currentUser?.role == "admin"
    }
    
    // Barra de navegación personalizada
    private var navigationBar: some View {
        VStack(spacing: 0) {
            HStack {
                Text(navigationTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                
                if authViewModel.isUsingFallback {
                    Spacer().frame(width: 8)
                    
                    // Indicador de modo fallback
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("Modo Demo")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .onTapGesture {
                        // Al tocar el indicador, intentamos reconectar
                        authViewModel.reconnectToBackend()
                        
                        // Verificamos si el servidor está disponible
                        AuthService.shared.pingServer()
                            .receive(on: DispatchQueue.main)
                            .sink { isAvailable in
                                if isAvailable && authViewModel.isUsingFallback {
                                    // Si estamos en modo fallback y el servidor está disponible,
                                    // preguntamos si quiere reconectar
                                    showReconnectAlert = true
                                }
                            }
                            .store(in: &AuthService.shared.cancellables)
                    }
                }
                
                Spacer()
                
                // Información del usuario
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(authViewModel.currentUser?.name ?? "Usuario")
                            .font(.footnote)
                            .fontWeight(.medium)
                        
                        Text(authViewModel.currentUser?.role.capitalized ?? "")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer().frame(width: 8)
                
                Button(action: {
                    authViewModel.logout()
                }) {
                    HStack(spacing: 4) {
                        Text("Salir")
                            .font(.subheadline)
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Cerrar sesión")
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            Divider()
        }
        .background(Color(.systemBackground).opacity(0.95))
    }
    
    private var navigationTitle: String {
        switch tabViewModel.selectedTab {
        case .monitoring:
            return "Monitoreo en Vivo"
        case .projects:
            return "Proyectos"
        case .maintenance:
            return "Mantenimiento"
        case .reports:
            return "Reportes"
        case .inventory:
            return "Inventario"
        case .admin:
            return "Administración"
        }
    }
    
    // Configuración de la apariencia del UITabBar
    private func setupTabBarAppearance() {
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
        
        // Configuración de apariencia para iOS 15+
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    NavigationView {
        MainTabView(maintenanceManager: MaintenanceManager())
            .environmentObject(AuthViewModel())
    }
} 