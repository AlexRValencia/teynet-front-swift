import SwiftUI
import UIKit

// Extensión simple para deshabilitar la barra de asistente
extension UITextField {
    open override var canBecomeFirstResponder: Bool {
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []
        return super.canBecomeFirstResponder
    }
}

extension UITextView {
    open override var canBecomeFirstResponder: Bool {
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []
        return super.canBecomeFirstResponder
    }
}

@main
struct TrynetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Configuración global de la apariencia
        configureAppAppearance()
    }
    
    private func configureAppAppearance() {
        // También podemos deshabilitar la barra de asistente de manera global aquí
        UITextField.appearance().inputAssistantItem.leadingBarButtonGroups = []
        UITextField.appearance().inputAssistantItem.trailingBarButtonGroups = []
        UITextView.appearance().inputAssistantItem.leadingBarButtonGroups = []
        UITextView.appearance().inputAssistantItem.trailingBarButtonGroups = []
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onAppear {
                    // Configurar observador de notificación para sesión expirada
                    setupSessionExpirationObserver()
                }
        }
    }
    
    private func setupSessionExpirationObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SessionExpired"),
            object: nil,
            queue: .main
        ) { _ in
            // Cerrar sesión en AuthViewModel cuando el token expira
            if authViewModel.isAuthenticated {
                print("📣 Notificación recibida: La sesión ha expirado")
                authViewModel.sessionExpired()
            }
        }
    }
} 