import Foundation

// Modelo completo de usuario para administración
struct AdminUser: Identifiable, Codable, Hashable {
    let id: String
    let username: String
    let fullName: String
    let role: String
    let status: Bool
    let lastLogin: Date?
    let createdAt: Date
    let updatedAt: Date
    let createdBy: String?
    let modifiedBy: String?
    
    // Implementación de Hashable para permitir usar AdminUser con .sheet(item:)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AdminUser, rhs: AdminUser) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Inicializador para crear desde UserData
    init(from userData: AdminUserData) {
        print("🔍 Iniciando conversión de AdminUserData a AdminUser")
        print("   ID: \(userData._id)")
        
        self.id = userData._id
        
        // Manejar username
        if let username = userData.username {
            self.username = username
            print("   Username: \(username)")
        } else if let usuario = userData.usuario {
            self.username = usuario
            print("   Username (desde usuario): \(usuario)")
        } else {
            self.username = "Sin nombre de usuario"
            print("   ⚠️ No se encontró username, usando valor por defecto")
        }
        
        // Manejar fullName
        if let fullName = userData.fullName {
            self.fullName = fullName
            print("   FullName: \(fullName)")
        } else if let fullname = userData.fullname {
            self.fullName = fullname
            print("   FullName (desde fullname): \(fullname)")
        } else if let nombre = userData.nombre, let apellidos = userData.apellidos {
            self.fullName = "\(nombre) \(apellidos)"
            print("   FullName (desde nombre+apellidos): \(nombre) \(apellidos)")
        } else if let nombre = userData.nombre {
            self.fullName = nombre
            print("   FullName (desde nombre): \(nombre)")
        } else {
            self.fullName = "Sin nombre"
            print("   ⚠️ No se encontró fullName, usando valor por defecto")
        }
        
        // Manejar role
        if let role = userData.role {
            self.role = role
            print("   Role: \(role)")
        } else if let rol = userData.rol {
            self.role = rol
            print("   Role (desde rol): \(rol)")
        } else {
            self.role = "viewer" // Rol por defecto
            print("   ⚠️ No se encontró role, usando valor por defecto: viewer")
        }
        
        // Manejar status según el modelo del backend (string: "active", "inactive", "deleted")
        if let status = userData.status {
            self.status = status.lowercased() == "active"
            print("   Status (desde status string): \(status) -> \(self.status)")
        } else if let statusDB = userData.statusDB {
            self.status = statusDB.lowercased() == "active"
            print("   Status (desde statusDB string): \(statusDB) -> \(self.status)")
        } else if let statusDb = userData.statusDb {
            self.status = statusDb
            print("   Status (desde statusDb boolean): \(statusDb)")
        } else if let state = userData.state {
            self.status = state.lowercased() == "active"
            print("   Status (desde state): \(state) -> \(self.status)")
        } else {
            self.status = true // Por defecto activo
            print("   ⚠️ No se encontró status, usando valor por defecto: true")
        }

        // Manejar lastLogin
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let lastLoginStr = userData.lastLogin, let date = dateFormatter.date(from: lastLoginStr) {
            self.lastLogin = date
            print("   LastLogin: \(date)")
        } else {
            self.lastLogin = nil
            print("   LastLogin: nil (no se ha iniciado sesión o no hay datos)")
        }
        
        // Convertir strings de fecha a Date
        if let createdAtStr = userData.createdAt, let date = dateFormatter.date(from: createdAtStr) {
            self.createdAt = date
            print("   CreatedAt: \(date)")
        } else {
            self.createdAt = Date()
            print("   ⚠️ No se pudo convertir createdAt, usando fecha actual")
        }
        
        if let updatedAtStr = userData.updatedAt, let date = dateFormatter.date(from: updatedAtStr) {
            self.updatedAt = date
            print("   UpdatedAt: \(date)")
        } else {
            self.updatedAt = Date()
            print("   ⚠️ No se pudo convertir updatedAt, usando fecha actual")
        }
        
        // Convertir AnyCodable a String para createdBy
        if let createdByString = userData.created_by {
            self.createdBy = createdByString
            print("   CreatedBy (desde created_by): \(createdByString)")
        } else if let createdByValue = userData.createdBy {
            // Intentar convertir AnyCodable a String
            if let intValue = createdByValue.value as? Int {
                self.createdBy = String(intValue)
                print("   CreatedBy (desde Int): \(intValue)")
            } else if let stringValue = createdByValue.value as? String {
                self.createdBy = stringValue
                print("   CreatedBy (desde String): \(stringValue)")
            } else if let dict = createdByValue.value as? [String: Any] {
                // Manejar el caso cuando createdBy es un objeto
                if let userId = dict["_id"] as? String {
                    self.createdBy = userId
                    print("   CreatedBy (desde objeto): \(userId)")
                } else if let fullName = dict["fullName"] as? String {
                    self.createdBy = fullName
                    print("   CreatedBy (desde nombre): \(fullName)")
                } else {
                    self.createdBy = "Usuario del sistema"
                    print("   CreatedBy: usando valor por defecto (objeto sin ID)")
                }
            } else {
                self.createdBy = nil
                print("   ⚠️ No se pudo convertir createdBy")
            }
        } else {
            self.createdBy = nil
            print("   CreatedBy: nil")
        }
        
        // Convertir AnyCodable a String para modifiedBy
        if let modifiedByString = userData.modified_by {
            self.modifiedBy = modifiedByString
            print("   ModifiedBy (desde modified_by): \(modifiedByString)")
        } else if let modifiedByValue = userData.modifiedBy {
            // Intentar convertir AnyCodable a String
            if let intValue = modifiedByValue.value as? Int {
                self.modifiedBy = String(intValue)
                print("   ModifiedBy (desde Int): \(intValue)")
            } else if let stringValue = modifiedByValue.value as? String {
                self.modifiedBy = stringValue
                print("   ModifiedBy (desde String): \(stringValue)")
            } else if let dict = modifiedByValue.value as? [String: Any] {
                // Manejar el caso cuando modifiedBy es un objeto
                if let userId = dict["_id"] as? String {
                    self.modifiedBy = userId
                    print("   ModifiedBy (desde objeto): \(userId)")
                } else if let fullName = dict["fullName"] as? String {
                    self.modifiedBy = fullName
                    print("   ModifiedBy (desde nombre): \(fullName)")
                } else {
                    self.modifiedBy = "Usuario del sistema"
                    print("   ModifiedBy: usando valor por defecto (objeto sin ID)")
                }
            } else {
                self.modifiedBy = nil
                print("   ⚠️ No se pudo convertir modifiedBy")
            }
        } else {
            self.modifiedBy = nil
            print("   ModifiedBy: nil")
        }
        
        print("✅ Conversión completada para usuario ID: \(id)")
    }
    
    // Inicializador para crear un nuevo usuario
    init(id: String = UUID().uuidString, 
         username: String, 
         fullName: String, 
         role: String, 
         status: Bool = true,
         lastLogin: Date? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         createdBy: String? = nil,
         modifiedBy: String? = nil) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.role = role
        self.status = status
        self.lastLogin = lastLogin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.modifiedBy = modifiedBy
    }
}

// Modelo para crear o actualizar un usuario
struct UserCreateUpdateRequest: Codable {
    let username: String
    let fullName: String
    let role: String
    let password: String?
    let status: String
    
    init(from user: AdminUser, password: String? = nil) {
        self.username = user.username
        self.fullName = user.fullName
        self.role = user.role
        self.password = password
        self.status = user.status ? "active" : "inactive"
    }
    
    init(username: String, fullName: String, role: String, password: String? = nil, status: Bool = true) {
        self.username = username
        self.fullName = fullName
        self.role = role
        self.password = password
        self.status = status ? "active" : "inactive"
    }
}

// Estructura para la paginación
struct PaginationData: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let pages: Int
}

// Estructura para la respuesta de usuarios
struct UsersData: Codable {
    let users: [AdminUserData]
    let pagination: PaginationData
}

// Respuesta de la API para operaciones de usuarios
struct UsersResponse: Codable {
    let ok: Bool
    let data: UsersData
}

// Respuesta para un solo usuario
struct UserResponse: Codable {
    let ok: Bool
    let data: AdminUserData
}

// Enumeración de roles disponibles
enum UserRole: String, CaseIterable, Identifiable {
    case admin = "admin"
    case technician = "technician"
    case supervisor = "supervisor"
    case viewer = "viewer"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .admin: return "Administrador"
        case .technician: return "Técnico"
        case .supervisor: return "Supervisor"
        case .viewer: return "Visualizador"
        }
    }
}

// Modelo de datos de usuario para decodificación
struct AdminUserData: Codable {
    let _id: String
    let username: String?
    let fullname: String?
    let fullName: String?
    let role: String?
    let rol: String?
    let statusDb: Bool?
    let statusDB: String?
    let status: String?
    let lastLogin: String?
    let createdAt: String?
    let updatedAt: String?
    let createdBy: AnyCodable?
    let modifiedBy: AnyCodable?
    let created_by: String?
    let modified_by: String?
    let __v: Int?
    
    // Campos adicionales para compatibilidad
    let usuario: String?
    let nombre: String?
    let apellidos: String?
    let state: String?
    
    enum CodingKeys: String, CodingKey {
        case _id
        case username
        case fullname
        case fullName
        case role
        case rol
        case statusDb
        case statusDB
        case status
        case lastLogin
        case createdAt
        case updatedAt
        case createdBy
        case modifiedBy
        case created_by
        case modified_by
        case __v
        case usuario
        case nombre
        case apellidos
        case state
    }
}

// Estructura para manejar valores JSON dinámicos
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

// Estructura para el performedBy
struct PerformedByData: Codable {
    let _id: String
    let fullName: String?
    let username: String?
    
    // A veces performedBy viene como un String (ID) en lugar de un objeto
    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let stringValue = try? container.decode(String.self) {
                self._id = stringValue
                self.fullName = nil
                self.username = nil
                return
            }
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(String.self, forKey: ._id)
        self.fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
    }
    
    enum CodingKeys: String, CodingKey {
        case _id
        case fullName
        case username
    }
}

// Modelo para el historial de un usuario
struct UserHistory: Identifiable, Codable {
    let id: String
    let userId: String
    let action: String
    let changes: [String: AnyCodable]?
    let previousData: [String: AnyCodable]?
    let notes: String?
    let createdAt: Date
    let createdBy: String?
    let createdByName: String?
    let ipAddress: String?
    let userAgent: String?
    
    init(from historyData: UserHistoryData) {
        self.id = historyData._id
        self.userId = historyData.entityId
        self.action = historyData.action
        self.changes = historyData.changes
        self.previousData = historyData.previousData
        self.notes = historyData.notes
        self.ipAddress = historyData.ipAddress
        self.userAgent = historyData.userAgent
        
        // Convertir string de fecha a Date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let createdAtStr = historyData.createdAt, let date = dateFormatter.date(from: createdAtStr) {
            self.createdAt = date
        } else {
            self.createdAt = Date()
        }
        
        // Manejar performedBy
        if let performedBy = historyData.performedBy {
            self.createdBy = performedBy._id
            self.createdByName = performedBy.fullName
        } else {
            self.createdBy = nil
            self.createdByName = nil
        }
    }
}

// Modelo de datos de historial para decodificación
struct UserHistoryData: Codable {
    let _id: String
    let entityType: String
    let entityId: String
    let action: String
    let changes: [String: AnyCodable]?
    let previousData: [String: AnyCodable]?
    let performedBy: PerformedByData?
    let ipAddress: String?
    let userAgent: String?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case _id
        case entityType
        case entityId
        case action
        case changes
        case previousData
        case performedBy
        case ipAddress
        case userAgent
        case notes
        case createdAt
        case updatedAt
    }
}

// Estructura para los datos de historial
struct UserHistoryDataResponse: Codable {
    let history: [UserHistoryData]
    let pagination: PaginationData
}

// Respuesta de la API para historial de usuarios
struct UserHistoryResponse: Codable {
    let ok: Bool
    let data: UserHistoryDataResponse
}

// La estructura EmptyResponse ya está definida en AuthService.swift
// struct EmptyResponse: Codable {
//    let ok: Bool
//    let message: String?
// } 