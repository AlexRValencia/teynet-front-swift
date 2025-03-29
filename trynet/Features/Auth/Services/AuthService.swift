import Foundation
import Combine

// Modelos para autenticación
struct LoginRequest: Codable {
    let username: String
    let password: String
}

// Estructura adaptada a la respuesta real del backend
struct LoginResponse: Codable {
    let ok: Bool
    let data: LoginResponseData
}

struct LoginResponseData: Codable {
    let accessToken: String
    let exp: Int
    let user: String
    let dataUser: UserData
    let refreshToken: String
    
    // Añadimos CodingKeys para mapear campos específicos si es necesario
    enum CodingKeys: String, CodingKey {
        case accessToken
        case exp
        case user
        case dataUser
        case refreshToken
    }
}

struct UserData: Codable {
    let rol: String?
    let statusDB: String?
    let _id: String
    let createdBy: Codable?
    let modifiedBy: Codable?
    let username: String
    let fullName: String
    let role: String
    let statusDb: Bool?  // Hacemos statusDb opcional
    let createdAt: String
    let updatedAt: String
    // Campos adicionales en la respuesta del servidor
    let status: String?
    let name: String?
    let updatedBy: Codable?
    let created_by: String?
    let modified_by: String?
    let id: String?
    
    // Añadimos CodingKeys para mapear los campos del servidor a nuestro modelo
    enum CodingKeys: String, CodingKey {
        case rol
        case statusDB
        case _id
        case createdBy
        case modifiedBy
        case username
        case fullName
        case role
        case statusDb
        case createdAt
        case updatedAt
        // Campos adicionales en la respuesta del servidor
        case status
        case name
        case updatedBy
        case created_by
        case modified_by
        case id
    }
    
    init(from decoder: Decoder) throws {
        print("🔍 Iniciando decodificación de UserData...")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            _id = try container.decode(String.self, forKey: ._id)
            print("✅ _id decodificado correctamente: \(_id)")
        } catch {
            print("❌ Error decodificando _id: \(error)")
            throw error
        }
        
        do {
            username = try container.decode(String.self, forKey: .username)
            print("✅ username decodificado correctamente: \(username)")
        } catch {
            print("❌ Error decodificando username: \(error)")
            throw error
        }
        
        do {
            fullName = try container.decode(String.self, forKey: .fullName)
            print("✅ fullName decodificado correctamente: \(fullName)")
        } catch {
            print("❌ Error decodificando fullName: \(error)")
            throw error
        }
        
        do {
            role = try container.decode(String.self, forKey: .role)
            print("✅ role decodificado correctamente: \(role)")
        } catch {
            print("❌ Error decodificando role: \(error)")
            throw error
        }
        
        // Hacemos rol opcional para evitar errores
        do {
            rol = try container.decodeIfPresent(String.self, forKey: .rol)
            print("✅ rol decodificado correctamente: \(rol ?? "nil")")
        } catch {
            print("❌ Error decodificando rol: \(error)")
            rol = nil
        }
        
        // Hacemos statusDB opcional para evitar errores
        do {
            statusDB = try container.decodeIfPresent(String.self, forKey: .statusDB)
            print("✅ statusDB decodificado correctamente: \(statusDB ?? "nil")")
        } catch {
            print("❌ Error decodificando statusDB: \(error)")
            statusDB = nil
        }
        
        // Intentamos decodificar statusDb del campo original, si no existe, lo derivamos de statusDB
        if let statusDbValue = try? container.decodeIfPresent(Bool.self, forKey: .statusDb) {
            statusDb = statusDbValue
            print("✅ statusDb decodificado correctamente como Bool: \(statusDbValue)")
        } else if let statusDbString = try? container.decodeIfPresent(String.self, forKey: .statusDb) {
            statusDb = statusDbString.lowercased() == "active" || statusDbString.lowercased() == "true"
            print("✅ statusDb decodificado correctamente como String y convertido a Bool: \(statusDb ?? false)")
        } else {
            // Si no hay campo statusDb, derivamos el valor de statusDB
            if let statusDBValue = statusDB {
                statusDb = statusDBValue.lowercased() == "active" || statusDBValue.lowercased() == "true"
                print("✅ statusDb derivado de statusDB: \(statusDb ?? false)")
            } else {
                print("⚠️ No se pudo determinar statusDb, se establece como nil")
                statusDb = nil
            }
        }
        
        do {
            createdAt = try container.decode(String.self, forKey: .createdAt)
            print("✅ createdAt decodificado correctamente: \(createdAt)")
        } catch {
            print("❌ Error decodificando createdAt: \(error)")
            throw error
        }
        
        do {
            updatedAt = try container.decode(String.self, forKey: .updatedAt)
            print("✅ updatedAt decodificado correctamente: \(updatedAt)")
        } catch {
            print("❌ Error decodificando updatedAt: \(error)")
            throw error
        }
        
        // Campos opcionales
        print("🔍 Decodificando campos opcionales...")
        status = try? container.decode(String.self, forKey: .status)
        name = try? container.decode(String.self, forKey: .name)
        id = try? container.decode(String.self, forKey: .id)
        created_by = try? container.decode(String.self, forKey: .created_by)
        modified_by = try? container.decode(String.self, forKey: .modified_by)
        
        // Para campos que pueden ser de diferentes tipos
        print("🔍 Decodificando campos con tipos múltiples...")
        if let createdByString = try? container.decode(String.self, forKey: .createdBy) {
            createdBy = createdByString
            print("✅ createdBy decodificado como String: \(createdByString)")
        } else {
            // Si no es un string, decodificamos como un tipo anónimo (se pierde la información pero no falla)
            if let createdByDict = try? container.decode([String: String].self, forKey: .createdBy) {
                createdBy = createdByDict
                print("✅ createdBy decodificado como Dictionary: \(createdByDict)")
            } else {
                print("⚠️ createdBy no pudo ser decodificado, se establece como nil")
                createdBy = nil
            }
        }
        
        if let modifiedByString = try? container.decode(String.self, forKey: .modifiedBy) {
            modifiedBy = modifiedByString
            print("✅ modifiedBy decodificado como String: \(modifiedByString)")
        } else {
            // Si no es un string, decodificamos como un tipo anónimo (se pierde la información pero no falla)
            if let modifiedByDict = try? container.decode([String: String].self, forKey: .modifiedBy) {
                modifiedBy = modifiedByDict
                print("✅ modifiedBy decodificado como Dictionary: \(modifiedByDict)")
            } else {
                print("⚠️ modifiedBy no pudo ser decodificado, se establece como nil")
                modifiedBy = nil
            }
        }
        
        if let updatedByString = try? container.decode(String.self, forKey: .updatedBy) {
            updatedBy = updatedByString
            print("✅ updatedBy decodificado como String: \(updatedByString)")
        } else {
            // Si no es un string, decodificamos como un tipo anónimo
            if let updatedByDict = try? container.decode([String: String].self, forKey: .updatedBy) {
                updatedBy = updatedByDict
                print("✅ updatedBy decodificado como Dictionary: \(updatedByDict)")
            } else {
                print("⚠️ updatedBy no pudo ser decodificado, se establece como nil")
                updatedBy = nil
            }
        }
        
        print("✅ UserData decodificado completamente.")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(_id, forKey: ._id)
        try container.encode(username, forKey: .username)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(role, forKey: .role)
        
        if let rol = rol {
            try container.encode(rol, forKey: .rol)
        }
        
        if let statusDB = statusDB {
            try container.encode(statusDB, forKey: .statusDB)
        }
        
        if let statusDb = statusDb {
            try container.encode(statusDb, forKey: .statusDb)
        }
        
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // Codificar campos opcionales si existen
        if let status = status {
            try container.encode(status, forKey: .status)
        }
        if let name = name {
            try container.encode(name, forKey: .name)
        }
        if let id = id {
            try container.encode(id, forKey: .id)
        }
        if let created_by = created_by {
            try container.encode(created_by, forKey: .created_by)
        }
        if let modified_by = modified_by {
            try container.encode(modified_by, forKey: .modified_by)
        }
        
        // Codificar los campos que pueden ser de diferentes tipos
        if let createdByString = createdBy as? String {
            try container.encode(createdByString, forKey: .createdBy)
        } else if let createdByDict = createdBy as? [String: String] {
            try container.encode(createdByDict, forKey: .createdBy)
        }
        
        if let modifiedByString = modifiedBy as? String {
            try container.encode(modifiedByString, forKey: .modifiedBy)
        } else if let modifiedByDict = modifiedBy as? [String: String] {
            try container.encode(modifiedByDict, forKey: .modifiedBy)
        }
        
        if let updatedByString = updatedBy as? String {
            try container.encode(updatedByString, forKey: .updatedBy)
        } else if let updatedByDict = updatedBy as? [String: String] {
            try container.encode(updatedByDict, forKey: .updatedBy)
        }
    }
}

// Mantenemos la estructura User para uso interno en la app
struct User: Codable {
    let id: String
    let username: String
    let name: String
    let role: String
}

class AuthService {
    static let shared = AuthService()
    private let apiClient = APIClient.shared
    var cancellables = Set<AnyCancellable>()
    
    // Endpoints (ajustar según tu estructura de API)
    private enum Endpoints {
        static let login = "/authn/login"
        static let refreshToken = "/authn/refresh"
        static let logout = "/authn/logout"
        static let profile = "/users/profile"
        static let status = "/status" // Endpoint para verificar disponibilidad del servidor
    }
    
    private init() {}
    
    // Método para iniciar sesión
    func login(username: String, password: String) -> AnyPublisher<User, APIError> {
        let loginRequest = LoginRequest(username: username, password: password)
        let body: [String: Any] = [
            "username": loginRequest.username,
            "password": loginRequest.password
        ]
        
        print("🔑 Intentando iniciar sesión con usuario: \(username)")
        print("🌐 Endpoint completo: \(apiClient.baseURL + Endpoints.login)")
        print("📦 Datos enviados: { username: \(username), password: ****** }")
        
        return apiClient.request(
            endpoint: Endpoints.login,
            method: "POST",
            body: body,
            requiresAuth: false
        )
        .handleEvents(receiveOutput: { (response: LoginResponse) in
            print("✅ Login exitoso para el usuario: \(username)")
            print("🧩 Datos del usuario recibidos: role=\(response.data.dataUser.role), statusDB=\(response.data.dataUser.statusDB ?? "nil")")
            
            // Guardar el token para futuras peticiones (ahora es accessToken)
            self.apiClient.authToken = response.data.accessToken
            
            // También guardamos el refreshToken
            UserDefaults.standard.set(response.data.refreshToken, forKey: "refreshToken")
            
            // Guardar datos del usuario
            let userData = response.data.dataUser
            UserDefaults.standard.set(userData._id, forKey: "userId")
            UserDefaults.standard.set(userData.fullName, forKey: "userName")
            UserDefaults.standard.set(userData.role, forKey: "userRole")
            UserDefaults.standard.set(userData.username, forKey: "username")
            
            // Guardamos el status derivado
            let userStatus: Bool
            if let statusDb = userData.statusDb {
                userStatus = statusDb
            } else if let statusDB = userData.statusDB {
                userStatus = statusDB.lowercased() == "active" || statusDB.lowercased() == "true"
            } else {
                userStatus = true // Por defecto asumimos que está activo
            }
            UserDefaults.standard.set(userStatus, forKey: "userStatus")
            
            // Tratamos createdBy y modifiedBy según su tipo
            let createdByValue: String
            if let createdByString = userData.createdBy as? String {
                createdByValue = createdByString
            } else if let createdByDict = userData.createdBy as? [String: String], let id = createdByDict["_id"] {
                createdByValue = id
            } else {
                createdByValue = "unknown"
            }
            UserDefaults.standard.set(createdByValue, forKey: "createdBy")
            
            // Guardar fecha de expiración
            UserDefaults.standard.set(response.data.exp, forKey: "tokenExpiration")
        }, receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("❌ Error de login: \(error.message)")
            }
        })
        .map { response -> User in
            // Convertimos los datos del usuario de la respuesta a nuestro modelo User
            let userData = response.data.dataUser
            print("🔄 Convirtiendo datos de usuario a modelo User: ID=\(userData._id), Username=\(userData.username)")
            return User(
                id: userData._id,
                username: userData.username,
                name: userData.fullName,
                role: userData.role
            )
        }
        .eraseToAnyPublisher()
    }
    
    // Método para cerrar sesión
    func logout() {
        // Si el backend requiere una llamada para invalidar el token
        if apiClient.authToken != nil {
            // Intenta hacer logout en el servidor
            apiClient.request(endpoint: Endpoints.logout, method: "POST")
                .sink(
                    receiveCompletion: { _ in
                        self.clearLocalUserData()
                    },
                    receiveValue: { (_: EmptyResponse) in
                        print("✅ Logout exitoso en el servidor")
                    }
                )
                .store(in: &cancellables)
        } else {
            // Si no hay token, simplemente limpia los datos locales
            clearLocalUserData()
        }
    }
    
    private func clearLocalUserData() {
        print("🧹 Limpiando datos locales del usuario")
        
        // Limpiar token y datos del usuario
        apiClient.authToken = nil
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userRole")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "tokenExpiration")
    }
    
    // Verificar si el usuario está autenticado
    func isAuthenticated() -> Bool {
        // Primero verificamos si existe un token
        guard let _ = apiClient.authToken else {
            print("❌ No hay token de autenticación guardado")
            return false
        }
        
        // Verificar si el token está expirado
        guard let tokenExpiration = UserDefaults.standard.object(forKey: "tokenExpiration") as? Int else {
            print("⚠️ No se encontró fecha de expiración del token")
            return false
        }
        
        let currentTime = Int(Date().timeIntervalSince1970)
        let isExpired = currentTime >= tokenExpiration
        
        if isExpired {
            print("🕒 Token expirado. Expiración: \(Date(timeIntervalSince1970: TimeInterval(tokenExpiration)))")
            
            // Limpiar token expirado
            clearLocalUserData()
            return false
        }
        
        print("✅ Token válido. Expira: \(Date(timeIntervalSince1970: TimeInterval(tokenExpiration)))")
        return true
    }
    
    // Obtener usuario actual
    func getCurrentUser() -> User? {
        guard 
            let id = UserDefaults.standard.string(forKey: "userId"),
            let username = UserDefaults.standard.string(forKey: "username"),
            let name = UserDefaults.standard.string(forKey: "userName"),
            let role = UserDefaults.standard.string(forKey: "userRole")
        else {
            return nil
        }
        
        return User(id: id, username: username, name: name, role: role)
    }
    
    // Actualizar perfil del usuario desde el servidor
    func refreshUserProfile() -> AnyPublisher<User, APIError>? {
        guard isAuthenticated() else {
            return nil
        }
        
        return apiClient.request(endpoint: Endpoints.profile, method: "GET")
            .handleEvents(receiveOutput: { (user: User) in
                print("✅ Perfil de usuario actualizado: \(user.name)")
                
                // Actualizar datos del usuario
                UserDefaults.standard.set(user.id, forKey: "userId")
                UserDefaults.standard.set(user.name, forKey: "userName")
                UserDefaults.standard.set(user.role, forKey: "userRole")
                UserDefaults.standard.set(user.username, forKey: "username")
            })
            .eraseToAnyPublisher()
    }
    
    // Verificar si el servidor está disponible (versión optimizada)
    func pingServer() -> AnyPublisher<Bool, Never> {
        // Crear una URL Request optimizada para verificación rápida
        guard let url = URL(string: apiClient.baseURL + Endpoints.status) else {
            print("❌ URL inválida para verificación del servidor: \(apiClient.baseURL + Endpoints.status)")
            return Just(false).eraseToAnyPublisher()
        }
        
        print("🔍 Intentando conectar a: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD" // Usamos HEAD en lugar de GET para menor tráfico
        request.timeoutInterval = 1.5 // Reducimos el timeout para verificaciones más rápidas
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData // Aseguramos que no se use caché
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { data, response -> Bool in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Respuesta no HTTP al verificar el servidor")
                    return false
                }
                let isSuccess = httpResponse.statusCode >= 200 && httpResponse.statusCode < 400
                print(isSuccess ? "✅ Servidor respondió con éxito (código \(httpResponse.statusCode))" : 
                                 "❌ Servidor respondió con error (código \(httpResponse.statusCode))")
                return isSuccess
            }
            .catch { error -> AnyPublisher<Bool, Never> in
                // Mostrar información detallada sobre el error para depuración
                print("❌ Error al verificar el servidor: \(error.localizedDescription)")
                
                // URLSession.DataTaskPublisher.Failure ya es URLError, no necesitamos cast
                let urlError = error
                switch urlError.code {
                case .timedOut:
                    print("   - Timeout: El servidor tardó demasiado en responder")
                case .cannotFindHost:
                    print("   - Host no encontrado: Verifica el nombre del host")
                case .cannotConnectToHost:
                    print("   - No se puede conectar al host: El servidor puede estar apagado")
                case .networkConnectionLost:
                    print("   - Conexión perdida: Verifica tu conexión a internet")
                default:
                    print("   - Código de error URLError: \(urlError.code.rawValue)")
                }
                
                if let failingURL = urlError.failureURLString {
                    print("   - URL que falló: \(failingURL)")
                }
                
                return Just(false).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { isAvailable in
                if isAvailable {
                    print("✅ Servidor disponible (ping rápido)")
                } else {
                    print("❌ Servidor no disponible (ping rápido)")
                }
            })
            .eraseToAnyPublisher()
    }
}

// Estructura auxiliar para respuestas vacías
struct EmptyResponse: Codable { }

// Estructura para respuesta del estado del servidor
struct StatusResponse: Codable {
    let status: String
    let version: String
} 