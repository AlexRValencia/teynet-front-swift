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
    let data: ProjectData
}

// Modelo para manejar los datos del proyecto que vienen del API
struct ProjectData: Codable, Identifiable {
    let id: String
    let name: String
    let client: ClientData
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
        case id
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
        return Project(
            id: id, 
            name: name, 
            status: status ?? "Sin estado",  // Valor por defecto para status
            health: health,
            deadline: endDate ?? "",
            description: description ?? "",  // Valor por defecto para description
            client: client.safeName,  // Usar el método safeName en vez de la propiedad directamente
            manager: team?.first?.fullName ?? "",  // Manejar team opcional
            startDate: startDate ?? "",  // Proporcionar valor por defecto
            team: team?.compactMap { $0.id } ?? [],  // Usar compactMap para filtrar valores nil
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
        case id
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
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
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
} 