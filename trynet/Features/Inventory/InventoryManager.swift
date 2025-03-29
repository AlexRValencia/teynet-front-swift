import Foundation
import SwiftUI
import Combine

class InventoryManager: ObservableObject {
    static let shared = InventoryManager()
    
    @Published var inventoryItems: [InventoryItem] = []
    @Published var filteredItems: [InventoryItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private init() {
        // Inicializar con datos de demo
        loadDemoData()
    }
    
    // Cargar datos de demostración
    private func loadDemoData() {
        self.inventoryItems = [
            InventoryItem(id: "1", name: "Cámara Hikvision DS-2CD2143G0-I", category: "Cámaras", quantity: 15, available: 8, location: "Almacén Principal", price: 120.00, supplier: "Hikvision", serialNumber: "HIK-4523-789"),
            InventoryItem(id: "2", name: "Cámara Dahua IPC-HDW5442TM-AS", category: "Cámaras", quantity: 10, available: 5, location: "Almacén Principal", price: 180.50, supplier: "Dahua", serialNumber: "DAH-5678-321"),
            InventoryItem(id: "3", name: "Radio Ubiquiti NBE-5AC-Gen2", category: "Redes", quantity: 8, available: 3, location: "Almacén Secundario", price: 75.99, supplier: "Ubiquiti Networks", serialNumber: "UBQ-7890-456"),
            InventoryItem(id: "4", name: "Switch PoE TP-Link TL-SG1016PE", category: "Redes", quantity: 5, available: 2, location: "Almacén Principal", price: 160.75, supplier: "TP-Link", serialNumber: "TPL-3456-789"),
            InventoryItem(id: "5", name: "Cable UTP CAT6 Exterior (305m)", category: "Cables", quantity: 20, available: 15, location: "Almacén Secundario", price: 45.50, supplier: "AMP Netconnect", serialNumber: "AMP-5678-012"),
            InventoryItem(id: "6", name: "Fuente de alimentación 48V", category: "Accesorios", quantity: 30, available: 22, location: "Almacén Principal", price: 18.99, supplier: "Generic Power", serialNumber: "PWSP-789-345"),
            InventoryItem(id: "7", name: "Gabinete exterior IP65", category: "Accesorios", quantity: 12, available: 8, location: "Almacén Secundario", price: 35.75, supplier: "TechBox", serialNumber: "TB-4567-890"),
            InventoryItem(id: "8", name: "NVR Hikvision 16 canales", category: "Servidores", quantity: 3, available: 1, location: "Almacén Principal", price: 350.00, supplier: "Hikvision", serialNumber: "HIKNVR-567-123")
        ]
        
        self.filteredItems = self.inventoryItems
    }
    
    // En una app real, esta función cargaría datos del backend
    func loadInventory() {
        self.isLoading = true
        self.errorMessage = nil
        
        // Simulación de carga de red
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // En una app real, aquí iría una llamada a la API
            self.isLoading = false
            
            // Si hay un error, establecer mensaje:
            // self.errorMessage = "Error al cargar inventario"
        }
    }
    
    // Filtrar inventario por categoría
    func filterByCategory(_ category: String?) {
        if let category = category, category != "Todos" {
            self.filteredItems = self.inventoryItems.filter { $0.category == category }
        } else {
            self.filteredItems = self.inventoryItems
        }
    }
    
    // Filtrar inventario por texto de búsqueda
    func searchItems(query: String) {
        if query.isEmpty {
            self.filteredItems = self.inventoryItems
        } else {
            self.filteredItems = self.inventoryItems.filter {
                $0.name.lowercased().contains(query.lowercased()) ||
                $0.category.lowercased().contains(query.lowercased()) ||
                $0.supplier?.lowercased().contains(query.lowercased()) ?? false ||
                $0.serialNumber?.lowercased().contains(query.lowercased()) ?? false
            }
        }
    }
    
    // Añadir un nuevo ítem al inventario
    func addItem(_ item: InventoryItem) {
        self.inventoryItems.append(item)
        self.filteredItems = self.inventoryItems
    }
    
    // Actualizar un ítem existente
    func updateItem(_ item: InventoryItem) {
        if let index = self.inventoryItems.firstIndex(where: { $0.id == item.id }) {
            self.inventoryItems[index] = item
            self.filteredItems = self.inventoryItems
        }
    }
    
    // Eliminar un ítem
    func deleteItem(id: String) {
        self.inventoryItems.removeAll(where: { $0.id == id })
        self.filteredItems = self.inventoryItems
    }
    
    // Obtener un ítem por ID
    func getItem(id: String) -> InventoryItem? {
        return self.inventoryItems.first(where: { $0.id == id })
    }
    
    // Asignar material a un proyecto (esto actualizaría la disponibilidad)
    func assignToProject(itemId: String, quantity: Int, projectId: String) -> Bool {
        guard let index = self.inventoryItems.firstIndex(where: { $0.id == itemId }) else {
            return false
        }
        
        if self.inventoryItems[index].available >= quantity {
            self.inventoryItems[index].available -= quantity
            
            // En una app real, aquí registraríamos la asignación en una base de datos
            
            return true
        }
        
        return false
    }
    
    // Devolver material de un proyecto
    func returnFromProject(itemId: String, quantity: Int, projectId: String) -> Bool {
        guard let index = self.inventoryItems.firstIndex(where: { $0.id == itemId }) else {
            return false
        }
        
        if self.inventoryItems[index].quantity >= (self.inventoryItems[index].available + quantity) {
            self.inventoryItems[index].available += quantity
            
            // En una app real, aquí registraríamos la devolución en una base de datos
            
            return true
        }
        
        return false
    }
    
    // MARK: - Métodos de informes y estadísticas
    
    // Obtener el valor total del inventario
    func getTotalInventoryValue() -> Double {
        return self.inventoryItems.reduce(0) { $0 + (($1.price ?? 0) * Double($1.quantity)) }
    }
    
    // Obtener el número de ítems sin stock disponible
    func getOutOfStockCount() -> Int {
        return self.inventoryItems.filter { $0.available == 0 }.count
    }
    
    // Obtener ítems con bajo stock (menos del 20% disponible)
    func getLowStockItems() -> [InventoryItem] {
        return self.inventoryItems.filter {
            $0.available > 0 && Double($0.available) / Double($0.quantity) < 0.2
        }
    }
    
    // Obtener estadísticas por categoría
    func getStatsByCategory() -> [String: (count: Int, total: Int, value: Double)] {
        var stats: [String: (count: Int, total: Int, value: Double)] = [:]
        
        for category in InventoryItem.categories {
            let items = self.inventoryItems.filter { $0.category == category }
            let count = items.count
            let total = items.reduce(0) { $0 + $1.quantity }
            let value = items.reduce(0.0) { $0 + (($1.price ?? 0) * Double($1.quantity)) }
            
            stats[category] = (count, total, value)
        }
        
        return stats
    }
} 