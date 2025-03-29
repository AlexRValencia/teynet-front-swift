import Foundation

struct ProjectMaterial: Identifiable, Hashable {
    let id: String
    let inventoryItemId: String
    let projectId: String
    var name: String
    var category: String
    var assignedQuantity: Int
    var usedQuantity: Int
    var location: String
    var dateAssigned: Date
    var serialNumbers: [String]?
    var notes: String?
    
    // Propiedades calculadas
    var remainingQuantity: Int {
        return assignedQuantity - usedQuantity
    }
    
    var usagePercentage: Double {
        guard assignedQuantity > 0 else { return 0 }
        return Double(usedQuantity) / Double(assignedQuantity)
    }
    
    // Inicializador
    init(id: String = UUID().uuidString,
         inventoryItemId: String,
         projectId: String,
         name: String,
         category: String,
         assignedQuantity: Int,
         usedQuantity: Int = 0,
         location: String,
         dateAssigned: Date = Date(),
         serialNumbers: [String]? = nil,
         notes: String? = nil) {
        self.id = id
        self.inventoryItemId = inventoryItemId
        self.projectId = projectId
        self.name = name
        self.category = category
        self.assignedQuantity = assignedQuantity
        self.usedQuantity = usedQuantity
        self.location = location
        self.dateAssigned = dateAssigned
        self.serialNumbers = serialNumbers
        self.notes = notes
    }
    
    // Factory method para crear desde un InventoryItem
    static func fromInventoryItem(_ item: InventoryItem, 
                                 projectId: String, 
                                 assignedQuantity: Int, 
                                 notes: String? = nil) -> ProjectMaterial {
        return ProjectMaterial(
            inventoryItemId: item.id,
            projectId: projectId,
            name: item.name,
            category: item.category,
            assignedQuantity: assignedQuantity,
            location: item.location,
            serialNumbers: item.serialNumber != nil ? [item.serialNumber!] : nil,
            notes: notes
        )
    }
}

// Estados posibles para el material del proyecto
enum MaterialStatus: String, CaseIterable {
    case assigned = "Asignado"
    case inUse = "En uso"
    case fullyUsed = "Totalmente utilizado"
    case partialReturn = "Devolución parcial"
    case returned = "Devuelto"
    
    var systemImage: String {
        switch self {
        case .assigned:
            return "shippingbox"
        case .inUse:
            return "hammer"
        case .fullyUsed:
            return "checkmark.circle"
        case .partialReturn:
            return "arrow.left.circle.dotted"
        case .returned:
            return "arrow.left.circle"
        }
    }
    
    var color: String {
        switch self {
        case .assigned:
            return "blue"
        case .inUse:
            return "orange"
        case .fullyUsed:
            return "green"
        case .partialReturn:
            return "purple"
        case .returned:
            return "gray"
        }
    }
    
    // Determinar el estado basado en el uso del material
    static func fromUsage(assigned: Int, used: Int, returned: Bool = false) -> MaterialStatus {
        if returned {
            return .returned
        }
        
        if used == 0 {
            return .assigned
        } else if used < assigned {
            return .inUse
        } else {
            return .fullyUsed
        }
    }
}

// Registro histórico de movimientos de material
struct MaterialMovement: Identifiable, Hashable {
    let id: String
    let projectMaterialId: String
    let date: Date
    let movementType: MovementType
    let quantity: Int
    let performedBy: String
    let location: String?
    let notes: String?
    
    enum MovementType: String, CaseIterable {
        case assigned = "Asignado"
        case used = "Utilizado"
        case returned = "Devuelto"
        case transferred = "Transferido"
        case damaged = "Dañado"
        case lost = "Perdido"
        
        var systemImage: String {
            switch self {
            case .assigned:
                return "arrow.right.circle"
            case .used:
                return "hammer"
            case .returned:
                return "arrow.left.circle"
            case .transferred:
                return "arrow.right.arrow.left"
            case .damaged:
                return "exclamationmark.triangle"
            case .lost:
                return "xmark.circle"
            }
        }
    }
} 