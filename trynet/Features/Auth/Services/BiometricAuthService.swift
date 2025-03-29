import Foundation
import LocalAuthentication

enum BiometricType {
    case none
    case touchID
    case faceID
    
    var description: String {
        switch self {
        case .none:
            return "No disponible"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        }
    }
    
    var iconName: String {
        switch self {
        case .none:
            return "xmark.circle"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        }
    }
}

class BiometricAuthService {
    static let shared = BiometricAuthService()
    
    private init() {}
    
    // Determina el tipo de biometría disponible en el dispositivo
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        // Verificar si la biometría está disponible
        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            // Optic ID es una nueva forma de biometría introducida en iOS 17
            // Por ahora, lo tratamos como un tipo no soportado y devolvemos .none
            print("⚠️ Optic ID detectado pero no está implementado específicamente")
            return .none
        @unknown default:
            // Captura cualquier caso futuro que pueda añadirse en versiones posteriores de iOS
            print("⚠️ Tipo de biometría desconocido detectado: \(context.biometryType)")
            return .none
        }
    }
    
    // Verifica si la autenticación biométrica está disponible
    func isBiometricAuthAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // Realiza la autenticación biométrica
    func authenticateUser() async -> Result<Bool, Error> {
        // Crear un nuevo contexto para cada autenticación
        let context = LAContext()
        var error: NSError?
        
        // Verificar si la biometría está disponible
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                return .failure(error)
            }
            return .failure(NSError(domain: "BiometricAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "La autenticación biométrica no está disponible"]))
        }
        
        // Configurar el mensaje de razón
        let biometricType = getBiometricType()
        let reason = "Inicia sesión con \(biometricType.description) para acceder a TryNet"
        
        do {
            // Intentar autenticar
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return .success(success)
        } catch {
            return .failure(error)
        }
    }
    
    // Guarda las credenciales para uso con biometría
    func saveBiometricCredentials(username: String, password: String) {
        let credentials = ["username": username, "password": password]
        
        // Guardar en el Keychain
        if let data = try? JSONEncoder().encode(credentials) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.trynet.biometric",
                kSecAttrAccount as String: "biometricLogin",
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            // Primero intentamos eliminar cualquier entrada existente
            SecItemDelete(query as CFDictionary)
            
            // Luego guardamos la nueva entrada
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("❌ Error al guardar credenciales biométricas: \(status)")
            }
        }
    }
    
    // Recupera las credenciales guardadas
    func retrieveBiometricCredentials() -> (username: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.trynet.biometric",
            kSecAttrAccount as String: "biometricLogin",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, 
              let data = item as? Data,
              let credentials = try? JSONDecoder().decode([String: String].self, from: data),
              let username = credentials["username"],
              let password = credentials["password"] else {
            return nil
        }
        
        return (username, password)
    }
    
    // Elimina las credenciales guardadas
    func deleteBiometricCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.trynet.biometric",
            kSecAttrAccount as String: "biometricLogin"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("❌ Error al eliminar credenciales biométricas: \(status)")
        }
    }
    
    // Verifica si hay credenciales biométricas guardadas
    func hasBiometricCredentials() -> Bool {
        return retrieveBiometricCredentials() != nil
    }
} 
