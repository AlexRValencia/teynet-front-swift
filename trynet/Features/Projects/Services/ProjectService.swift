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
        return ProjectResponse(
            ok: ok,
            message: message,
            data: ProjectData(
                id: data.id,
                name: data.name,
                client: .id(data.client),
                status: data.status,
                health: data.health,
                description: data.description,
                startDate: data.startDate,
                endDate: data.endDate,
                team: data.team?.compactMap { TeamMemberData(
                    _id: $0,
                    fullName: nil,
                    name: nil,
                    id: $0
                ) },
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
    let client: String // Aquí el cliente es un string (ID) en lugar de un objeto
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
        let clientStr: String
        switch client {
        case .object(let clientData):
            clientStr = clientData.safeName
        case .id(let clientId):
            clientStr = clientId
        }
        
        // Formatear la fecha de forma legible
        let formattedStartDate = formatDate(startDate ?? "")
        let formattedEndDate = formatDate(endDate ?? "")
        
        return Project(
            id: id, 
            name: name, 
            status: status ?? "Sin estado",  // Valor por defecto para status
            health: health,
            deadline: formattedEndDate,
            description: description ?? "",  // Valor por defecto para description
            client: clientStr,  // Usar el cliente según el formato recibido
            startDate: formattedStartDate,  // Fecha formateada
            team: team?.compactMap { $0.effectiveId } ?? [],  // Usar compactMap para filtrar valores nil
            tasks: [],  // Array vacío de tareas por defecto
            points: points != nil ? points!.map { pointId -> ProjectPoint in
                // Crear un ProjectPoint con valores por defecto
                return ProjectPoint(
                    id: pointId,
                    name: "Punto sin nombre", 
                    type: .CCTV,  // Tipo por defecto
                    location: ProjectPoint.Location(latitude: 0, longitude: 0, address: nil),
                    city: "",
                    materialName: nil,
                    material: nil
                )
            } : nil  // Si points es nil, devolvemos nil
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let clientData = try? container.decode(ClientData.self) {
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
                                        let errorDetail = "🔑 Falta la clave '\(key.stringValue)' en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
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
            projectDict["startDate"] = project.startDate
        }
        
        if !project.deadline.isEmpty {
            projectDict["endDate"] = project.deadline
        }
        
        // Para el campo client necesitamos un ObjectId
        // Verificamos si el cliente contiene un ID de MongoDB válido
        if let clientId = extractClientId(from: project.client) {
            // Si parece un ObjectId válido, lo usamos directamente
            print("✅ ID de cliente encontrado: \(clientId)")
            projectDict["client"] = clientId
        } else {
            // Intentamos buscar el cliente por nombre en el ClientManager
            let clientManager = ClientManager.shared
            if let client = clientManager.clients.first(where: { $0.name == project.client }) {
                // Si encontramos el cliente, usamos su ID
                print("✅ Cliente encontrado en el gestor: \(client.name) con ID: \(client.id)")
                projectDict["client"] = client.id
            } else {
                // Si no encontramos el cliente, mostramos advertencia
                print("⚠️ ADVERTENCIA: No se encontró el cliente \"\(project.client)\" en la base de datos")
                print("⚠️ Debe seleccionar un cliente existente antes de crear el proyecto")
                
                // Usamos un ID temporal para que el backend rechace la solicitud
                projectDict["client"] = "000000000000000000000000" // ID inválido
            }
        }
        
        // Si tiene miembros en el equipo, los enviamos como un array
        if !project.team.isEmpty {
            // El equipo debe ser un array de strings (IDs de los miembros)
            // Si los IDs ya están en formato correcto, los usamos directamente
            let validTeamIds = project.team.filter { 
                $0.count == 24 && $0.range(of: "^[0-9a-f]{24}$", options: .regularExpression) != nil
            }
            
            if !validTeamIds.isEmpty {
                projectDict["team"] = validTeamIds
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
} 