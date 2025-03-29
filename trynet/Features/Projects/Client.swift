import Foundation
import SwiftUI
import Combine

struct Client: Identifiable, Hashable, Codable {
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
}

// Respuestas del API
struct ClientResponse: Codable {
    let ok: Bool
    let data: Client
    let message: String?
}

struct ClientsResponse: Codable {
    let ok: Bool
    let data: [Client]
    let message: String?
}

// Clase para gestionar los clientes conectándose al backend
class ClientManager: ObservableObject {
    static let shared = ClientManager()
    
    @Published var clients: [Client] = [
        Client(id: "1", name: "Corporativo Norte", contactPerson: "Roberto Sánchez", email: "contacto@corpnorte.mx", phone: "871-123-4567", address: "Blvd. Independencia 1500, Torreón"),
        Client(id: "2", name: "Municipio Torreón", contactPerson: "Laura Garza", email: "sistemas@torreon.gob.mx", phone: "871-765-4321", address: "Plaza Principal s/n, Centro, Torreón"),
        Client(id: "3", name: "Grupo Empresarial MTY", contactPerson: "Carlos Martínez", email: "cmartinez@gemty.com", phone: "81-8888-5555", address: "Av. Constitución 1200, Monterrey"),
        Client(id: "4", name: "Interno", contactPerson: "Ana Gómez", email: "agomez@trynet.mx", phone: "844-552-3344", address: "Oficinas Centrales"),
    ]
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    
    // Endpoints para gestión de clientes
    private enum Endpoints {
        static let clients = "/clients"  // Endpoint base para clientes
    }
    
    private init() {
        // Cargar clientes al inicializar
        loadClients()
    }
    
    // Cargar todos los clientes desde el API
    func loadClients() {
        apiClient.request(endpoint: Endpoints.clients, method: "GET")
            .map { (response: ClientsResponse) -> [Client] in
                return response.data
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("Error al cargar clientes: \(error.message)")
                    case .finished:
                        print("Carga de clientes completada exitosamente")
                    }
                },
                receiveValue: { [weak self] clients in
                    self?.clients = clients
                }
            )
            .store(in: &cancellables)
    }
    
    // Agregar un nuevo cliente
    func addClient(_ client: Client) -> AnyPublisher<Client, APIError> {
        let body: [String: Any] = [
            "name": client.name,
            "legalName": client.legalName,
            "rfc": client.rfc,
            "contactPerson": client.contactPerson,
            "email": client.email,
            "phone": client.phone,
            "address": client.address,
            "notes": client.notes,
            "active": client.active
        ]
        
        return apiClient.request(
            endpoint: Endpoints.clients,
            method: "POST",
            body: body
        )
        .map { (response: ClientResponse) -> Client in
            let newClient = response.data
            // Actualizamos la lista local
            DispatchQueue.main.async {
                self.clients.append(newClient)
            }
            return newClient
        }
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
    func updateClient(_ client: Client) -> AnyPublisher<Client, APIError> {
        let body: [String: Any] = [
            "name": client.name,
            "legalName": client.legalName,
            "rfc": client.rfc,
            "contactPerson": client.contactPerson,
            "email": client.email,
            "phone": client.phone,
            "address": client.address,
            "notes": client.notes,
            "active": client.active
        ]
        
        return apiClient.request(
            endpoint: "\(Endpoints.clients)/\(client.id)",
            method: "PUT",
            body: body
        )
        .map { (response: ClientResponse) -> Client in
            let updatedClient = response.data
            // Actualizamos la lista local
            DispatchQueue.main.async {
                if let index = self.clients.firstIndex(where: { $0.id == client.id }) {
                    self.clients[index] = updatedClient
                }
            }
            return updatedClient
        }
        .eraseToAnyPublisher()
    }
    
    // Eliminar un cliente
    func deleteClient(id: String) -> AnyPublisher<Bool, APIError> {
        return apiClient.request(
            endpoint: "\(Endpoints.clients)/\(id)",
            method: "DELETE"
        )
        .map { (response: ClientResponse) -> Bool in
            // Actualizamos la lista local
            DispatchQueue.main.async {
                self.clients.removeAll { $0.id == id }
            }
            return response.ok
        }
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
} 