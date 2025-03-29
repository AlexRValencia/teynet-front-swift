import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("🚀 Aplicación iniciada")
        
        // Verificar estado de autenticación al iniciar
        validateTokenIfNeeded()
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 Aplicación entrando en primer plano")
        
        // Verificar estado de autenticación al volver a la app
        validateTokenIfNeeded()
    }
    
    private func validateTokenIfNeeded() {
        // Verificar si hay token guardado
        if let _ = UserDefaults.standard.string(forKey: "authToken") {
            // Comprobar si hay fecha de expiración guardada
            if let expirationTime = UserDefaults.standard.object(forKey: "tokenExpiration") as? Int {
                let currentTime = Int(Date().timeIntervalSince1970)
                let isExpired = currentTime >= expirationTime
                
                if isExpired {
                    print("🕒 Token expirado detectado en AppDelegate. Limpiando datos de sesión...")
                    
                    // Limpiar datos de sesión
                    UserDefaults.standard.removeObject(forKey: "authToken")
                    UserDefaults.standard.removeObject(forKey: "userId")
                    UserDefaults.standard.removeObject(forKey: "userName")
                    UserDefaults.standard.removeObject(forKey: "userRole")
                    UserDefaults.standard.removeObject(forKey: "username")
                    UserDefaults.standard.removeObject(forKey: "refreshToken")
                    UserDefaults.standard.removeObject(forKey: "tokenExpiration")
                    
                    // Notificar a la aplicación que la sesión expiró
                    NotificationCenter.default.post(
                        name: Notification.Name("SessionExpired"),
                        object: nil
                    )
                }
            }
        }
    }
} 