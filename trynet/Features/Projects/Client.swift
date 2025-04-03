import Foundation
import SwiftUI
import Combine

struct Client: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var legalName: String
    var rfc: String
    var contactPerson: String
    var email: String
    var phone: String
    var address: String
    var notes: String
    var active: Bool
    
    // Para Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Client, rhs: Client) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Constructor con valores predeterminados
    init(id: String = UUID().uuidString,
         name: String,
         legalName: String = "",
         rfc: String = "",
         contactPerson: String = "",
         email: String = "",
         phone: String = "",
         address: String = "",
         notes: String = "",
         active: Bool = true) {
        self.id = id
        self.name = name
        self.legalName = legalName
        self.rfc = rfc
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.address = address
        self.notes = notes
        self.active = active
    }
    
    // Añadir CodingKeys para mapear _id a id
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, legalName, rfc, contactPerson, email, phone, address, notes, active
    }
    
    // Método para crear una copia sin ID para creación de nuevos clientes
    func toCreateDTO() -> [String: Any] {
        return [
            "name": name,
            "legalName": legalName,
            "rfc": rfc,
            "contactPerson": contactPerson,
            "email": email,
            "phone": phone,
            "address": address,
            "notes": notes,
            "active": active
        ]
    }
    
    // Método para crear una copia para actualización
    func toUpdateDTO() -> [String: Any] {
        return [
            "name": name,
            "legalName": legalName,
            "rfc": rfc,
            "contactPerson": contactPerson,
            "email": email,
            "phone": phone,
            "address": address,
            "notes": notes,
            "active": active
        ]
    }
}

// Estructura para manejar la paginación
struct ClientPaginationData: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
}

// Estructura para el contenido de datos de clientes en la respuesta
struct ClientsData: Codable {
    let clients: [Client]
    let pagination: ClientPaginationData
}

// Respuestas del API
struct ClientResponse: Codable {
    let ok: Bool
    let data: Client
    let message: String?
}

struct ClientsResponse: Codable {
    let ok: Bool
    let data: ClientsData
    let message: String?
}

// Clase para gestionar los clientes conectándose al backend
class ClientManager: ObservableObject {
    static let shared = ClientManager()
    
    @Published var clients: [Client] = []
    @Published var pagination: ClientPaginationData?
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Estado de paginación
    @Published var currentPage: Int = 1
    @Published var hasMorePages: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let basePath = "/clients"
    
    // Endpoints para gestión de clientes
    private enum Endpoints {
        static let clients = "/clients"  // Endpoint base para clientes
    }
    
    private init() {
        // Cargar clientes al inicializar
        loadClients()
    }
    
    // Cargar todos los clientes desde el API con paginación y filtros
    func loadClients(page: Int = 1, search: String? = nil, active: Bool? = nil) {
        isLoading = true
        errorMessage = nil
        
        // Crear parámetros de consulta
        var parameters: [String: String] = ["page": "\(page)"]
        
        // Añadir parámetros de filtrado si existen
        if let search = search, !search.isEmpty {
            parameters["search"] = search
        }
        
        if let active = active {
            parameters["active"] = active ? "true" : "false"
        }
        
        apiClient.request(.get, path: basePath, parameters: parameters)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Error al cargar clientes: \(error.message)"
                }
            })
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] (response: ClientsResponse) in
                    guard let self = self else { return }
                    
                    self.pagination = response.data.pagination
                    
                    // Determinar si hay más páginas
                    self.hasMorePages = response.data.pagination.page < response.data.pagination.totalPages
                    
                    // Actualizar la página actual
                    self.currentPage = response.data.pagination.page
                    
                    // Si es la primera página o un refresh, reemplazar los clientes
                    if page == 1 {
                        self.clients = response.data.clients
                    } else {
                        // Agregar los nuevos clientes a la lista existente
                        self.clients.append(contentsOf: response.data.clients)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Refrescar la lista de clientes (volver a la primera página)
    func refreshClients() {
        // Mantener filtros actuales pero volver a la página 1
        loadClients(page: 1)
    }
    
    // Cargar la siguiente página de clientes
    func loadNextPage() {
        guard hasMorePages, !isLoading else { return }
        
        // Cargar la siguiente página
        loadClients(page: currentPage + 1)
    }
    
    // Agregar un nuevo cliente
    func addClient(_ client: Client) -> AnyPublisher<ClientResponse, APIError> {
        isLoading = true
        errorMessage = nil
        
        // Para nuevos clientes, usamos el DTO sin ID
        return apiClient.request(.post, path: basePath, body: client.toCreateDTO())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Error al agregar cliente: \(error.message)"
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Obtener un cliente por ID
    func getClient(byId id: String) -> Client? {
        return clients.first { $0.id == id }
    }
    
    // Obtener un cliente por nombre
    func getClient(byName name: String) -> Client? {
        return clients.first { $0.name.lowercased() == name.lowercased() }
    }
    
    // Actualizar un cliente existente
    func updateClient(_ client: Client) -> AnyPublisher<ClientResponse, APIError> {
        isLoading = true
        errorMessage = nil
        
        return apiClient.request(.put, path: "\(basePath)/\(client.id)", body: client.toUpdateDTO())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Error al actualizar cliente: \(error.message)"
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Eliminar un cliente
    func deleteClient(id: String) -> AnyPublisher<ClientResponse, APIError> {
        isLoading = true
        errorMessage = nil
        
        return apiClient.request(.delete, path: "\(basePath)/\(id)")
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Error al eliminar cliente: \(error.message)"
                }
            })
            .eraseToAnyPublisher()
    }
    
    // Obtener todos los clientes (de la memoria)
    func getAllClients() -> [Client] {
        return clients
    }
    
    // Obtener clientes activos
    func getActiveClients() -> [Client] {
        return clients.filter { $0.active }
    }
    
    // Buscar clientes por texto
    func searchClients(text: String) {
        // Reiniciar a la primera página con el texto de búsqueda
        loadClients(page: 1, search: text)
    }
    
    // Filtrar clientes por estado (activo/inactivo)
    func filterClientsByStatus(active: Bool?) {
        loadClients(page: 1, active: active)
    }
} 