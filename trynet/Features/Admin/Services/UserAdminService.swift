import Foundation
import Combine

// Importamos el módulo donde está definido EmptyResponse
// import AuthServices

// Estructura para respuestas vacías en el contexto de Admin
struct AdminEmptyResponse: Codable { 
    let ok: Bool
    let message: String?
}

class UserAdminService {
    static let shared = UserAdminService()
    private let apiClient = APIClient.shared
    var cancellables = Set<AnyCancellable>()
    
    // Endpoints para gestión de usuarios (actualizados para las nuevas rutas)
    private enum Endpoints {
        static let users = "/user"  // Endpoint base para usuarios
    }
    
    private init() {}
    
    // Obtener todos los usuarios
    func getUsers() -> AnyPublisher<[AdminUser], APIError> {
        return self.apiClient.request(endpoint: Endpoints.users, method: "GET")
            .map { (response: UsersResponse) -> [AdminUser] in
                return response.data.users.map { AdminUser(from: $0) }
            }
            .eraseToAnyPublisher()
    }
    
    // Obtener un usuario por ID
    func getUser(id: String) -> AnyPublisher<AdminUser, APIError> {
        return self.apiClient.request(endpoint: Endpoints.users + "/" + id, method: "GET")
            .map { (response: UserResponse) -> AdminUser in
                return AdminUser(from: response.data)
            }
            .eraseToAnyPublisher()
    }
    
    // Obtener historial de cambios de un usuario
    func getUserHistory(id: String, page: Int = 1, limit: Int = 20) -> AnyPublisher<UserHistoryResponse, APIError> {
        let queryParams = "?page=\(page)&limit=\(limit)"
        return self.apiClient.request(endpoint: Endpoints.users + "/" + id + "/history" + queryParams, method: "GET")
            .eraseToAnyPublisher()
    }
    
    // Crear un nuevo usuario
    func createUser(user: UserCreateUpdateRequest) -> AnyPublisher<AdminUser, APIError> {
        let body: [String: Any] = [
            "username": user.username,
            "fullName": user.fullName,
            "role": user.role,
            "password": user.password ?? "",
            "status": user.status, // Ya es string en UserCreateUpdateRequest
            "notes": "Creación de usuario desde la aplicación móvil"
        ]
        
        print("🔄 Creando nuevo usuario: \(user.username)")
        print("📦 Datos a enviar: \(body)")
        
        return self.apiClient.request(
            endpoint: Endpoints.users,
            method: "POST",
            body: body
        )
        .map { (response: UserResponse) -> AdminUser in
            print("✅ Usuario creado exitosamente")
            print("📄 Respuesta recibida: \(response)")
            let adminUser = AdminUser(from: response.data)
            print("🧩 Datos del usuario creado: \(adminUser)")
            return adminUser
        }
        .eraseToAnyPublisher()
    }
    
    // Actualizar datos de un usuario
    func updateUser(_ user: AdminUser, password: String? = nil) -> AnyPublisher<AdminUser, APIError> {
        var body: [String: Any] = [
            "username": user.username,
            "fullName": user.fullName,
            "role": user.role,
            "status": user.status ? "active" : "inactive", // Convertir booleano a string para backend
            "notes": "Actualización desde la aplicación móvil"
        ]
        
        // Incluir contraseña solo si se proporciona
        if let password = password, !password.isEmpty {
            body["password"] = password
            print("🔐 Incluyendo nueva contraseña en actualización de usuario")
        }
        
        print("🔄 Actualizando usuario ID: \(user.id)")
        print("📦 Datos a enviar: \(body)")
        
        return self.apiClient.request(
            endpoint: Endpoints.users + "/" + user.id,
            method: "PUT",
            body: body
        )
        .map { (response: UserResponse) -> AdminUser in
            print("✅ Usuario actualizado exitosamente")
            print("📄 Respuesta recibida: \(response)")
            let adminUser = AdminUser(from: response.data)
            print("🧩 Datos del usuario actualizado: \(adminUser)")
            return adminUser
        }
        .eraseToAnyPublisher()
    }
    
    // Eliminar un usuario
    func deleteUser(id: String) -> AnyPublisher<Bool, APIError> {
        return self.apiClient.request(
            endpoint: Endpoints.users + "/" + id,
            method: "DELETE"
        )
        .map { (_: EmptyResponse) -> Bool in
            return true
        }
        .eraseToAnyPublisher()
    }
    
    // Cambiar la contraseña de un usuario
    func changePassword(id: String, newPassword: String) -> AnyPublisher<Bool, APIError> {
        // Verificar que el ID del usuario sea válido
        guard !id.isEmpty else {
            print("❌ ID de usuario vacío")
            return Fail(error: APIError.serverError(statusCode: 400, message: "ID de usuario no válido")).eraseToAnyPublisher()
        }
        
        // Verificar requisitos de contraseña (exactamente los mismos que el backend)
        if newPassword.count < 8 {
            print("⚠️ La contraseña debe tener al menos 8 caracteres")
            return Fail(error: APIError.serverError(statusCode: 400, message: "La contraseña debe tener al menos 8 caracteres")).eraseToAnyPublisher()
        }
        
        // Verificar que la contraseña contenga al menos una letra y un número
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*#?&]{8,}$"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        if !passwordTest.evaluate(with: newPassword) {
            print("⚠️ La contraseña debe contener al menos una letra y un número")
            return Fail(error: APIError.serverError(statusCode: 400, message: "La contraseña debe contener al menos una letra y un número")).eraseToAnyPublisher()
        }
        
        let body: [String: Any] = [
            "password": newPassword,
            "notes": "Cambio de contraseña desde la aplicación móvil"
        ]
        
        print("🔐 Cambiando contraseña para usuario ID: \(id)")
        print("📋 Body enviado: \(body)")
        
        // Usamos EXCLUSIVAMENTE el endpoint específico para cambio de contraseña
        // El endpoint general no procesa el campo password según el código del backend
        let endpoint = Endpoints.users + "/" + id + "/password"
        print("🌐 Endpoint: \(self.apiClient.baseURL + endpoint)")
        
        return self.apiClient.request(
            endpoint: endpoint,
            method: "PATCH",
            body: body
        )
        .map { (_: EmptyResponse) -> Bool in
            print("✅ Contraseña actualizada exitosamente")
            return true
        }
        .catch { error -> AnyPublisher<Bool, APIError> in
            print("❌ Error al cambiar contraseña: \(error)")
            
            // Proporcionar un mensaje más detallado basado en los posibles errores del backend
            if case let .serverError(statusCode, message) = error {
                if statusCode == 400 {
                    print("⚠️ Error de validación: \(message)")
                } else if statusCode == 404 {
                    print("⚠️ Usuario no encontrado")
                } else {
                    print("⚠️ Error del servidor: \(statusCode) \(message)")
                }
            }
            
            return Fail(error: error).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // Cambiar el estado de un usuario (activar/desactivar)
    func toggleUserStatus(id: String, active: Bool) -> AnyPublisher<AdminUser, APIError> {
        let newStatus = active ? "active" : "inactive"
        let body: [String: Any] = [
            "status": newStatus,
            "notes": "Cambio de estado desde la aplicación móvil"
        ]
        
        print("🔄 Cambiando estado de usuario ID: \(id) a \(newStatus)")
        
        return self.apiClient.request(
            endpoint: Endpoints.users + "/" + id,
            method: "PUT", // Usamos PUT para actualizar el usuario
            body: body
        )
        .map { (response: UserResponse) -> AdminUser in
            print("✅ Estado de usuario actualizado exitosamente a \(newStatus)")
            print("📄 Respuesta recibida: \(response)")
            let adminUser = AdminUser(from: response.data)
            print("🧩 Datos del usuario actualizado: \(adminUser)")
            return adminUser
        }
        .eraseToAnyPublisher()
    }
} 
