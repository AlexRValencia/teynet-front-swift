import Foundation
import Combine

// MARK: - Modelos para respuestas del API

// Estructura para la paginación
struct ProjectPaginationData: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let pages: Int
}

// Modelo para la respuesta de proyectos
struct ProjectsResponse: Codable {
    let ok: Bool
    let data: [ProjectData]
}

// Modelo para la respuesta de un proyecto individual
struct ProjectResponse: Codable {
    let ok: Bool
    let message: String?
    let data: ProjectData
}

// Estructura alternativa para respuestas del servidor con cliente como ID 
struct SimpleProjectResponse: Codable {
    let ok: Bool
    let message: String?
    let data: SimpleProjectData
    
    // Convertir a la estructura normal
    func toProjectResponse() -> ProjectResponse {
        let clientIdentifier: ClientIdentifier
        
        if let clientId = data.client {
            clientIdentifier = .id(clientId)
        } else {
            clientIdentifier = .none
        }
        
        // Transformar los IDs de equipo en objetos TeamMemberData
        let teamMembers = data.team?.compactMap { teamId -> TeamMemberData in
            // Intentar encontrar el nombre completo del usuario si está disponible
            let userViewModel = UserAdminViewModel.shared
            if !userViewModel.hasLoadedUsers {
                userViewModel.loadUsers()
            }
            
            if let user = userViewModel.users.first(where: { $0.id == teamId }) {
                return TeamMemberData(
                    _id: teamId,
                    fullName: user.fullName,
                    name: user.fullName,
                    id: teamId
                )
            } else {
                // Si no encontramos el usuario, usar solo el ID
                return TeamMemberData(
                    _id: teamId,
                    fullName: nil,
                    name: nil,
                    id: teamId
                )
            }
        }
        
        return ProjectResponse(
            ok: ok,
            message: message,
            data: ProjectData(
                id: data.id,
                name: data.name,
                client: clientIdentifier,
                status: data.status,
                health: data.health,
                description: data.description,
                startDate: data.startDate,
                endDate: data.endDate,
                team: teamMembers,
                points: data.points,
                materials: data.materials,
                createdBy: data.createdBy,
                createdAt: data.createdAt,
                updatedAt: data.updatedAt,
                updatedBy: data.updatedBy
            )
        )
    }
}

// Estructura simplificada para cuando el cliente es un string
struct SimpleProjectData: Codable {
    let id: String
    let name: String
    let client: String? // Hacemos client opcional para manejar valores nulos
    let status: String?
    let health: Double
    let description: String?
    let startDate: String?
    let endDate: String?
    let team: [String]?
    let points: [String]?
    let materials: [String]?
    let createdBy: String?
    let createdAt: String?
    let updatedAt: String?
    let updatedBy: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, client, status, health, description, startDate, endDate
        case team, points, materials, createdBy, createdAt, updatedAt, updatedBy
    }
}

// Modelo para manejar los datos del proyecto que vienen del API
struct ProjectData: Codable, Identifiable {
    let id: String
    let name: String
    let client: ClientIdentifier
    let status: String?  // Ahora es opcional
    let health: Double
    let description: String?  // Ahora es opcional
    let startDate: String?  // Ahora es opcional
    let endDate: String?
    let team: [TeamMemberData]?  // Ahora es opcional
    let points: [String]?
    let materials: [String]?
    let createdBy: String?  // Ahora es opcional
    let createdAt: String?  // Ahora es opcional
    let updatedAt: String?  // Ahora es opcional
    
    // Campos opcionales
    let updatedBy: String?
    
    // CodingKeys para mapear los campos de la API
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case client
        case status
        case health
        case description
        case startDate
        case endDate
        case team
        case points
        case materials
        case createdBy
        case createdAt
        case updatedAt
        case updatedBy
    }
    
    // Función para convertir ProjectData a Project
    func toProject() -> Project {
        // Obtener el nombre del cliente
        var clientName = "Sin cliente"
        switch client {
        case .object(let clientData):
            clientName = clientData.safeName
        case .id(let clientId):
            // Intentar buscar el cliente por ID para obtener su nombre
            let clientManager = ClientManager.shared
            if let foundClient = clientManager.clients.first(where: { $0.id == clientId }) {
                clientName = foundClient.name
            } else {
                // Si el cliente no se encuentra en la caché actual, usar el ID como fallback
                clientName = clientId
            }
        case .none:
            clientName = "Sin cliente"
        }
        
        // Formatear la fecha de forma legible
        let formattedStartDate = formatDate(startDate ?? "")
        let formattedEndDate = formatDate(endDate ?? "")
        
        // Obtener nombres de los miembros del equipo
        var teamMembers: [String] = []
        // Primero obtener todos los IDs de los miembros del equipo
        let teamIds = team?.compactMap { $0.effectiveId } ?? []
        
        // Buscar los nombres de usuario correspondientes a estos IDs
        let userViewModel = UserAdminViewModel.shared
        if !userViewModel.hasLoadedUsers {
            userViewModel.loadUsers()
        }
        
        for userId in teamIds {
            if let user = userViewModel.users.first(where: { $0.id == userId }) {
                teamMembers.append(user.fullName)
            } else {
                // Si no encontramos el usuario, busquemos en el objeto TeamMemberData directamente
                if let memberData = team?.first(where: { $0.effectiveId == userId }),
                   let fullName = memberData.fullName, !fullName.isEmpty {
                    teamMembers.append(fullName)
                } else {
                    // Último recurso: usar el ID como fallback
                    teamMembers.append(userId)
                }
            }
        }
        
        return Project(
            id: id, 
            name: name, 
            status: status ?? "Sin estado",
            health: health,
            deadline: formattedEndDate,
            description: description ?? "",
            client: clientName,  // Usar el nombre del cliente en lugar del ID
            clientId: client.id, // Guardamos el ID del cliente en un nuevo campo
            startDate: formattedStartDate,
            team: teamMembers,  // Usar los nombres de los miembros
            teamIds: teamIds, // Guardar los IDs en un campo separado
            tasks: [],
            points: points != nil ? points!.map { pointId -> ProjectPoint in
                return ProjectPoint(
                    id: pointId,
                    name: "Punto sin nombre", 
                    type: .CCTV,
                    location: ProjectPoint.Location(latitude: 0, longitude: 0, address: nil),
                    city: "",
                    materialName: nil,
                    material: nil
                )
            } : nil
        )
    }
    
    // Función auxiliar para formatear fechas desde strings ISO 8601
    private func formatDate(_ dateString: String) -> String {
        // Si la fecha está vacía, devolvemos un string vacío
        if dateString.isEmpty {
            return ""
        }
        
        // Creamos un formateador para la entrada (formato ISO 8601)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Intentamos parsear con el formato completo
        if let date = isoFormatter.date(from: dateString) {
            // Crear un formateador para la salida (formato legible)
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d 'de' MMMM, yyyy"
            outputFormatter.locale = Locale(identifier: "es_ES") // Usar locale español
            return outputFormatter.string(from: date)
        }
        
        // Si no se puede parsear con el formato completo, intentamos sin fracciones de segundo
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d 'de' MMMM, yyyy"
            outputFormatter.locale = Locale(identifier: "es_ES") // Usar locale español
            return outputFormatter.string(from: date)
        }
        
        // Si no se puede parsear, intentamos con el formato simple dd/MM/yyyy
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "dd/MM/yyyy"
        if let date = simpleFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "d 'de' MMMM, yyyy"
            outputFormatter.locale = Locale(identifier: "es_ES") // Usar locale español
            return outputFormatter.string(from: date)
        }
        
        // Si tampoco se puede parsear, devolvemos el string original
        return dateString
    }
}

// Modelo para los datos del cliente que vienen en la respuesta de proyectos
struct ClientData: Codable {
    let name: String?
    let id: String?
    
    // Añadir valores por defecto para evitar problemas con valores nulos
    var safeName: String {
        return name ?? "Cliente sin nombre"
    }
    
    var safeId: String {
        return id ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case id = "_id"
    }
}

// Modelo para los miembros del equipo
struct TeamMemberData: Codable {
    let _id: String?
    let fullName: String?
    let name: String?
    let id: String?
    
    enum CodingKeys: String, CodingKey {
        case _id
        case fullName
        case name
        case id // Mantener este campo por compatibilidad
    }
    
    // Proporcionar el ID independientemente de dónde venga
    var effectiveId: String {
        return id ?? _id ?? ""
    }
}

// Tipo enum para manejar tanto objetos ClientData como strings de ID
enum ClientIdentifier: Codable {
    case object(ClientData)
    case id(String)
    case none
    
    // Obtener el ID del cliente de forma segura
    var id: String? {
        switch self {
        case .object(let clientData):
            return clientData.safeId
        case .id(let clientId):
            return clientId
        case .none:
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            // Si es nulo, usamos el caso none
            self = .none
        } else if let clientData = try? container.decode(ClientData.self) {
            self = .object(clientData)
        } else if let clientId = try? container.decode(String.self) {
            self = .id(clientId)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "No se pudo decodificar ni como ClientData ni como String"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .object(let clientData):
            try container.encode(clientData)
        case .id(let clientId):
            try container.encode(clientId)
        case .none:
            try container.encodeNil()
        }
    }
}

// MARK: - Servicio de Proyectos
class ProjectService {
    static let shared = ProjectService()
    private let apiClient = APIClient.shared
    var cancellables = Set<AnyCancellable>()
    
    // Endpoints para gestión de proyectos
    private enum Endpoints {
        static let projects = "/projects"
    }
    
    private init() {}
    
    // Obtener todos los proyectos
    func getProjects() -> AnyPublisher<[Project], APIError> {
        return self.apiClient.request(endpoint: Endpoints.projects, method: "GET")
            .map { (response: ProjectsResponse) -> [Project] in
                return response.data.map { $0.toProject() }
            }
            .eraseToAnyPublisher()
    }
    
    // Obtener un proyecto por ID
    func getProject(id: String) -> AnyPublisher<Project, APIError> {
        return self.apiClient.request(endpoint: Endpoints.projects + "/" + id, method: "GET")
            .map { (response: ProjectResponse) -> Project in
                return response.data.toProject()
            }
            .eraseToAnyPublisher()
    }
    
    // Método para refrescar la lista de proyectos (versión async/await)
    func fetchProjects() async throws -> [Project] {
        return try await withCheckedThrowingContinuation { continuation in
            getProjects()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break // No hacemos nada ya que el valor se maneja en receiveValue
                        case .failure(let error):
                            print("❌ Error al recargar proyectos: \(error.message)")
                            
                            // Información detallada para errores de decodificación
                            if case .decodingError(let decodingError, let data) = error {
                                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                                    print("📄 Respuesta recibida: \(responseString)")
                                }
                                
                                print("📄 Error específico de decodificación: \(decodingError)")
                                
                                // Intentar identificar exactamente qué falló en la decodificación
                                if let decodingError = decodingError as? DecodingError {
                                    switch decodingError {
                                    case .keyNotFound(let key, let context):
                                        let errorDetail = "�� Falta la clave '\(key.stringValue)' en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                                        print(errorDetail)
                                    case .valueNotFound(let type, let context):
                                        let errorDetail = "📭 Valor nulo para tipo \(type) en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                                        print(errorDetail)
                                    case .typeMismatch(let type, let context):
                                        let errorDetail = "❌ Tipo de dato incorrecto, se esperaba \(type) en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                                        print(errorDetail)
                                    default:
                                        print("🤔 Otro error de decodificación: \(decodingError)")
                                    }
                                }
                            }
                            
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { projects in
                        continuation.resume(returning: projects)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    // Crear un nuevo proyecto
    func createProject(project: Project) -> AnyPublisher<Project, APIError> {
        print("📝 Creando nuevo proyecto: \(project.name)")
        
        // Convertir el proyecto a un diccionario para enviarlo en la solicitud
        var projectDict: [String: Any] = [
            "name": project.name,
            "status": project.status,
            "description": project.description,
        ]
        
        // Añadir fechas si no están vacías
        if !project.startDate.isEmpty {
            // Convertir fecha de formato localizado a ISO8601
            if let isoDate = convertToISODate(project.startDate) {
                projectDict["startDate"] = isoDate
            } else {
                print("⚠️ No se pudo convertir la fecha de inicio: \(project.startDate)")
                // Intentamos convertir a un formato que el backend pueda entender
                projectDict["startDate"] = project.startDate
            }
        }
        
        if !project.deadline.isEmpty {
            // Convertir fecha de formato localizado a ISO8601
            if let isoDate = convertToISODate(project.deadline) {
                projectDict["endDate"] = isoDate
            } else {
                print("⚠️ No se pudo convertir la fecha de fin: \(project.deadline)")
                // Intentamos convertir a un formato que el backend pueda entender
                projectDict["endDate"] = project.deadline
            }
        }
        
        // Para el campo client necesitamos un ObjectId
        if let clientId = project.clientId, !clientId.isEmpty {
            // Usamos directamente el ID del cliente proporcionado
            projectDict["client"] = clientId
            print("✅ Usando ID de cliente: \(clientId)")
        } else if !project.client.isEmpty {
            // Si no tenemos ID pero tenemos nombre, intentamos buscar el cliente por nombre
            let clientManager = ClientManager.shared
            if let foundClient = clientManager.clients.first(where: { $0.name == project.client }) {
                projectDict["client"] = foundClient.id
                print("✅ Encontrado cliente por nombre: \(project.client) con ID: \(foundClient.id)")
            } else {
                print("⚠️ ADVERTENCIA: No se encontró el cliente \"\(project.client)\" en la base de datos")
                // Usamos un ID temporal para que el backend rechace la solicitud
                projectDict["client"] = "000000000000000000000000" // ID inválido
            }
        } else {
            print("⚠️ ADVERTENCIA: No se proporcionó ID de cliente")
            // Usamos un ID temporal para que el backend rechace la solicitud
            projectDict["client"] = "000000000000000000000000" // ID inválido
        }
        
        // Si tiene miembros en el equipo, los enviamos como un array
        if !project.teamIds.isEmpty {
            // Usamos directamente los IDs del equipo proporcionados
            projectDict["team"] = project.teamIds
            print("✅ Usando IDs de equipo: \(project.teamIds)")
        } else if !project.team.isEmpty {
            // Si no tenemos IDs pero tenemos nombres, intentamos buscar los usuarios por nombre
            let userViewModel = UserAdminViewModel.shared
            let foundTeamIds = project.team.compactMap { memberName -> String? in
                if let user = userViewModel.users.first(where: { $0.fullName == memberName }) {
                    return user.id
                }
                return nil
            }
            
            if !foundTeamIds.isEmpty {
                projectDict["team"] = foundTeamIds
                print("✅ Encontrados IDs de equipo por nombres: \(foundTeamIds)")
            } else {
                print("⚠️ ADVERTENCIA: No se encontraron IDs para los miembros del equipo")
            }
        }
        
        print("📤 Enviando proyecto con datos: \(projectDict)")
        
        // Primero intentamos decodificar con la estructura SimpleProjectResponse
        return apiClient.request(.post, path: Endpoints.projects, body: projectDict)
            .mapError { error -> APIError in
                // Si es un error de decodificación, lo mostramos detalladamente
                if case .decodingError(let decodingError, let data) = error, 
                   let data = data,
                   let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Error decodificando: \(decodingError)")
                    print("📄 Respuesta recibida: \(responseString)")
                }
                return error
            }
            .flatMap { (response: SimpleProjectResponse) -> AnyPublisher<Project, APIError> in
                // Convertir de la respuesta simple a ProjectResponse
                let projectResponse = response.toProjectResponse()
                let project = projectResponse.data.toProject()
                print("✅ Proyecto creado correctamente: \(project.id)")
                return Just(project)
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Método auxiliar para extraer ID de cliente
    private func extractClientId(from clientString: String) -> String? {
        // Si el clientString es un ID de MongoDB (24 caracteres hexadecimales)
        if clientString.count == 24 && clientString.range(of: "^[0-9a-f]{24}$", options: .regularExpression) != nil {
            return clientString
        }
        // En caso contrario, asumimos que es un nombre y no un ID
        return nil
    }
    
    // Función auxiliar para convertir fechas a formato ISO8601
    private func convertToISODate(_ dateString: String) -> String? {
        // Si la fecha está vacía, devolvemos nil
        if dateString.isEmpty {
            return nil
        }
        
        // Creamos un formateador para el formato español "d 'de' MMMM, yyyy"
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "d 'de' MMMM, yyyy"
        inputFormatter.locale = Locale(identifier: "es_ES")
        
        // Intentamos parsear con el formato español
        if let date = inputFormatter.date(from: dateString) {
            // Convertimos a formato ISO 8601
            let outputFormatter = ISO8601DateFormatter()
            outputFormatter.formatOptions = [.withInternetDateTime]
            return outputFormatter.string(from: date)
        }
        
        // Si no se puede parsear con el formato español, intentamos con otros formatos
        let alternativeFormatters = [
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "MM/dd/yyyy",
            "yyyy/MM/dd"
        ]
        
        let formatter = DateFormatter()
        for format in alternativeFormatters {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                let outputFormatter = ISO8601DateFormatter()
                outputFormatter.formatOptions = [.withInternetDateTime]
                return outputFormatter.string(from: date)
            }
        }
        
        // Si no se puede parsear con ningún formato, devolvemos nil
        return nil
    }
    
    // Función auxiliar para uso externo (pruebas)
    func testDateConversion(dateString: String) -> String? {
        return convertToISODate(dateString)
    }
} 