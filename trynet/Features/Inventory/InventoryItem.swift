import Foundation

struct InventoryItem: Identifiable, Hashable {
    var id: String
    var name: String
    var category: String
    var quantity: Int
    var available: Int
    var location: String
    var price: Double?
    var supplier: String?
    var serialNumber: String?
    var lastCheckDate: String?
    var notes: String?
    var image: String? // URL o nombre del recurso de imagen
    
    // Para Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: InventoryItem, rhs: InventoryItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Categorías predefinidas
    static let categories = [
        "Cámaras", "Cables", "Servidores", "Redes", "Sensores", "Herramientas", "Accesorios", "Otros"
    ]
    
    // Ubicaciones predefinidas
    static let locations = [
        "Almacén Principal", "Almacén Secundario", "Oficina Central", "Taller", "En Tránsito", "Asignado a Proyecto"
    ]
} 