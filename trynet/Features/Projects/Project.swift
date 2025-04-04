import Foundation

struct Project: Identifiable, Hashable {
    var id: String
    var name: String
    var status: String
    var health: Double // Salud del proyecto basada en el estado operativo de los dispositivos
    var deadline: String
    var description: String
    var client: String // Ahora contiene el nombre del cliente
    var clientId: String? // ID del cliente para operaciones de backend
    var budget: Double?
    var startDate: String
    var team: [String] // Ahora contiene los nombres de los miembros
    var teamIds: [String] // IDs de los miembros para operaciones de backend
    var tasks: [ProjectTask]
    var points: [ProjectPoint]? // Puntos del proyecto (opcional)
    
    // Para Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Constructor con valores predeterminados para facilitar la creación
    init(id: String, name: String, status: String, health: Double = 1.0, deadline: String, 
         description: String = "", client: String = "", clientId: String? = nil,
         budget: Double? = nil, startDate: String = "", 
         team: [String] = [], teamIds: [String] = [], 
         tasks: [ProjectTask] = [], points: [ProjectPoint]? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.health = health
        self.deadline = deadline
        self.description = description
        self.client = client
        self.clientId = clientId
        self.budget = budget
        self.startDate = startDate
        self.team = team
        self.teamIds = teamIds
        self.tasks = tasks
        self.points = points
    }
}

struct ProjectTask: Identifiable, Hashable {
    var id: String
    var name: String
    var description: String
    var status: String
    var assignedTo: String?
    var dueDate: String?
    var priority: String
    
    // Para Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ProjectTask, rhs: ProjectTask) -> Bool {
        return lhs.id == rhs.id
    }
} 