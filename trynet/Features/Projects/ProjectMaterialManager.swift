import Foundation
import SwiftUI
import Combine

class ProjectMaterialManager: ObservableObject {
    static let shared = ProjectMaterialManager()
    
    @Published var projectMaterials: [String: [ProjectMaterial]] = [:]
    @Published var materialMovements: [MaterialMovement] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let inventoryManager = InventoryManager.shared
    
    private init() {
        // Inicializar con datos de demo
        loadDemoData()
    }
    
    // Cargar datos de demostración
    private func loadDemoData() {
        let projectId1 = "project1"
        let projectId2 = "project2"
        
        // Generar algunos materiales de demostración
        let demoMaterials1 = [
            ProjectMaterial(
                inventoryItemId: "1",
                projectId: projectId1,
                name: "Cámara Hikvision DS-2CD2143G0-I",
                category: "Cámaras",
                assignedQuantity: 5,
                usedQuantity: 3,
                location: "Almacén Principal",
                dateAssigned: Date().addingTimeInterval(-86400 * 7), // 7 días atrás
                serialNumbers: ["HIK-4523-789", "HIK-4523-790", "HIK-4523-791"]
            ),
            ProjectMaterial(
                inventoryItemId: "3",
                projectId: projectId1,
                name: "Radio Ubiquiti NBE-5AC-Gen2",
                category: "Redes",
                assignedQuantity: 2,
                usedQuantity: 2,
                location: "Almacén Secundario",
                dateAssigned: Date().addingTimeInterval(-86400 * 5) // 5 días atrás
            ),
            ProjectMaterial(
                inventoryItemId: "5",
                projectId: projectId1,
                name: "Cable UTP CAT6 Exterior (305m)",
                category: "Cables",
                assignedQuantity: 2,
                usedQuantity: 1,
                location: "Almacén Secundario",
                dateAssigned: Date().addingTimeInterval(-86400 * 3) // 3 días atrás
            ),
        ]
        
        let demoMaterials2 = [
            ProjectMaterial(
                inventoryItemId: "2",
                projectId: projectId2,
                name: "Cámara Dahua IPC-HDW5442TM-AS",
                category: "Cámaras",
                assignedQuantity: 4,
                usedQuantity: 0,
                location: "Almacén Principal",
                dateAssigned: Date().addingTimeInterval(-86400 * 2) // 2 días atrás
            ),
            ProjectMaterial(
                inventoryItemId: "7",
                projectId: projectId2,
                name: "Gabinete exterior IP65",
                category: "Accesorios",
                assignedQuantity: 3,
                usedQuantity: 1,
                location: "Almacén Secundario",
                dateAssigned: Date().addingTimeInterval(-86400 * 1) // 1 día atrás
            ),
        ]
        
        // Generar algunos movimientos de demostración
        let demoMovements = [
            MaterialMovement(
                id: UUID().uuidString,
                projectMaterialId: demoMaterials1[0].id,
                date: demoMaterials1[0].dateAssigned,
                movementType: .assigned,
                quantity: demoMaterials1[0].assignedQuantity,
                performedBy: "Alex Gómez",
                location: demoMaterials1[0].location,
                notes: "Asignación inicial para el proyecto"
            ),
            MaterialMovement(
                id: UUID().uuidString,
                projectMaterialId: demoMaterials1[0].id,
                date: Date().addingTimeInterval(-86400 * 3), // 3 días atrás
                movementType: .used,
                quantity: 2,
                performedBy: "Carlos Martínez",
                location: "Sitio de Obra",
                notes: "Instaladas en entrada principal"
            ),
            MaterialMovement(
                id: UUID().uuidString,
                projectMaterialId: demoMaterials1[0].id,
                date: Date().addingTimeInterval(-86400 * 1), // 1 día atrás
                movementType: .used,
                quantity: 1,
                performedBy: "Carlos Martínez",
                location: "Sitio de Obra",
                notes: "Instalada en área de estacionamiento"
            ),
            MaterialMovement(
                id: UUID().uuidString,
                projectMaterialId: demoMaterials1[1].id,
                date: demoMaterials1[1].dateAssigned,
                movementType: .assigned,
                quantity: demoMaterials1[1].assignedQuantity,
                performedBy: "Alex Gómez",
                location: demoMaterials1[1].location,
                notes: nil
            ),
            MaterialMovement(
                id: UUID().uuidString,
                projectMaterialId: demoMaterials1[1].id,
                date: Date().addingTimeInterval(-86400 * 2), // 2 días atrás
                movementType: .used,
                quantity: 2,
                performedBy: "Carlos Martínez",
                location: "Sitio de Obra",
                notes: "Instalados en torre principal"
            ),
        ]
        
        // Guardar los datos de demostración
        projectMaterials[projectId1] = demoMaterials1
        projectMaterials[projectId2] = demoMaterials2
        materialMovements = demoMovements
    }
    
    // MARK: - Funciones de acceso a datos
    
    // Obtener materiales para un proyecto específico
    func getMaterialsForProject(projectId: String) -> [ProjectMaterial] {
        return projectMaterials[projectId] ?? []
    }
    
    // Obtener un material específico por su ID
    func getMaterial(id: String) -> ProjectMaterial? {
        for materials in projectMaterials.values {
            if let material = materials.first(where: { $0.id == id }) {
                return material
            }
        }
        return nil
    }
    
    // Obtener movimientos para un material específico
    func getMovementsForMaterial(materialId: String) -> [MaterialMovement] {
        return materialMovements.filter { $0.projectMaterialId == materialId }
            .sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Funciones de modificación de datos
    
    // Asignar un material del inventario a un proyecto
    func assignMaterialToProject(inventoryItemId: String, projectId: String, quantity: Int, notes: String? = nil) -> Bool {
        // Verificar que el ítem de inventario existe y hay suficiente disponible
        guard let inventoryItem = inventoryManager.getItem(id: inventoryItemId),
              inventoryItem.available >= quantity else {
            errorMessage = "No hay suficiente stock disponible"
            return false
        }
        
        // Crear el material del proyecto
        let projectMaterial = ProjectMaterial.fromInventoryItem(
            inventoryItem,
            projectId: projectId,
            assignedQuantity: quantity,
            notes: notes
        )
        
        // Actualizar el inventario
        if !inventoryManager.assignToProject(itemId: inventoryItemId, quantity: quantity, projectId: projectId) {
            errorMessage = "Error al actualizar el inventario"
            return false
        }
        
        // Registrar el movimiento de asignación
        let movement = MaterialMovement(
            id: UUID().uuidString,
            projectMaterialId: projectMaterial.id,
            date: Date(),
            movementType: .assigned,
            quantity: quantity,
            performedBy: "Usuario Actual", // En una app real, esto vendría del sistema de autenticación
            location: inventoryItem.location,
            notes: notes
        )
        
        // Guardar los datos
        if projectMaterials[projectId] != nil {
            projectMaterials[projectId]!.append(projectMaterial)
        } else {
            projectMaterials[projectId] = [projectMaterial]
        }
        
        materialMovements.append(movement)
        
        return true
    }
    
    // Registrar uso de material en un proyecto
    func useMaterial(materialId: String, quantity: Int, location: String, notes: String? = nil) -> Bool {
        // Encontrar el material y su índice
        var materialIndex: Int = -1
        var projectId: String = ""
        
        for (pid, materials) in projectMaterials {
            if let index = materials.firstIndex(where: { $0.id == materialId }) {
                materialIndex = index
                projectId = pid
                break
            }
        }
        
        guard materialIndex >= 0, !projectId.isEmpty else {
            errorMessage = "Material no encontrado"
            return false
        }
        
        // Verificar que hay suficiente material asignado sin usar
        let material = projectMaterials[projectId]![materialIndex]
        let remaining = material.assignedQuantity - material.usedQuantity
        
        guard remaining >= quantity else {
            errorMessage = "No hay suficiente material disponible"
            return false
        }
        
        // Actualizar la cantidad usada
        projectMaterials[projectId]![materialIndex].usedQuantity += quantity
        
        // Registrar el movimiento
        let movement = MaterialMovement(
            id: UUID().uuidString,
            projectMaterialId: materialId,
            date: Date(),
            movementType: .used,
            quantity: quantity,
            performedBy: "Usuario Actual", // En una app real, esto vendría del sistema de autenticación
            location: location,
            notes: notes
        )
        
        materialMovements.append(movement)
        
        return true
    }
    
    // Devolver material al inventario
    func returnMaterial(materialId: String, quantity: Int, notes: String? = nil) -> Bool {
        // Encontrar el material y su índice
        var materialIndex: Int = -1
        var projectId: String = ""
        
        for (pid, materials) in projectMaterials {
            if let index = materials.firstIndex(where: { $0.id == materialId }) {
                materialIndex = index
                projectId = pid
                break
            }
        }
        
        guard materialIndex >= 0, !projectId.isEmpty else {
            errorMessage = "Material no encontrado"
            return false
        }
        
        // Obtener el material
        let material = projectMaterials[projectId]![materialIndex]
        
        // Verificar que no se devuelve más de lo asignado
        guard material.assignedQuantity >= quantity else {
            errorMessage = "No se puede devolver más de lo asignado"
            return false
        }
        
        // Actualizar el inventario
        if !inventoryManager.returnFromProject(
            itemId: material.inventoryItemId,
            quantity: quantity,
            projectId: projectId
        ) {
            errorMessage = "Error al actualizar el inventario"
            return false
        }
        
        // Actualizar la cantidad asignada
        projectMaterials[projectId]![materialIndex].assignedQuantity -= quantity
        
        // Si la cantidad asignada es 0, eliminar el material del proyecto
        if projectMaterials[projectId]![materialIndex].assignedQuantity == 0 {
            projectMaterials[projectId]!.remove(at: materialIndex)
            
            // Si no quedan materiales para el proyecto, eliminar la entrada
            if projectMaterials[projectId]!.isEmpty {
                projectMaterials.removeValue(forKey: projectId)
            }
        }
        
        // Registrar el movimiento
        let movement = MaterialMovement(
            id: UUID().uuidString,
            projectMaterialId: materialId,
            date: Date(),
            movementType: .returned,
            quantity: quantity,
            performedBy: "Usuario Actual", // En una app real, esto vendría del sistema de autenticación
            location: material.location,
            notes: notes
        )
        
        materialMovements.append(movement)
        
        return true
    }
    
    // Registrar material dañado o perdido
    func reportDamagedOrLost(materialId: String, quantity: Int, movementType: MaterialMovement.MovementType, location: String, notes: String?) -> Bool {
        // Verificar que el tipo de movimiento es válido
        guard movementType == .damaged || movementType == .lost else {
            errorMessage = "Tipo de movimiento no válido"
            return false
        }
        
        // Encontrar el material y su índice
        var materialIndex: Int = -1
        var projectId: String = ""
        
        for (pid, materials) in projectMaterials {
            if let index = materials.firstIndex(where: { $0.id == materialId }) {
                materialIndex = index
                projectId = pid
                break
            }
        }
        
        guard materialIndex >= 0, !projectId.isEmpty else {
            errorMessage = "Material no encontrado"
            return false
        }
        
        // Obtener el material
        let material = projectMaterials[projectId]![materialIndex]
        
        // Verificar que hay suficiente material sin usar
        let available = material.assignedQuantity - material.usedQuantity
        
        guard available >= quantity else {
            errorMessage = "No hay suficiente material disponible"
            return false
        }
        
        // Marcar como usado (ya que está dañado o perdido)
        projectMaterials[projectId]![materialIndex].usedQuantity += quantity
        
        // Registrar el movimiento
        let movement = MaterialMovement(
            id: UUID().uuidString,
            projectMaterialId: materialId,
            date: Date(),
            movementType: movementType,
            quantity: quantity,
            performedBy: "Usuario Actual", // En una app real, esto vendría del sistema de autenticación
            location: location,
            notes: notes
        )
        
        materialMovements.append(movement)
        
        return true
    }
    
    // MARK: - Métodos de estadísticas
    
    // Obtener estadísticas de materiales por proyecto
    func getProjectMaterialStats(projectId: String) -> (total: Int, used: Int, value: Double) {
        let materials = projectMaterials[projectId] ?? []
        
        let totalItems = materials.reduce(0) { $0 + $1.assignedQuantity }
        let usedItems = materials.reduce(0) { $0 + $1.usedQuantity }
        
        // Para el valor, necesitaríamos recuperar el precio de cada ítem del inventario
        var totalValue: Double = 0
        for material in materials {
            if let item = inventoryManager.getItem(id: material.inventoryItemId),
               let price = item.price {
                totalValue += price * Double(material.assignedQuantity)
            }
        }
        
        return (totalItems, usedItems, totalValue)
    }
    
    // Obtener el top de materiales más utilizados entre todos los proyectos
    func getTopUsedMaterials(limit: Int = 5) -> [(material: ProjectMaterial, usageCount: Int)] {
        var materialUsage: [String: (material: ProjectMaterial, count: Int)] = [:]
        
        // Contar el uso de cada material por su inventoryItemId
        for materials in projectMaterials.values {
            for material in materials {
                if let existingCount = materialUsage[material.inventoryItemId]?.count {
                    materialUsage[material.inventoryItemId] = (material, existingCount + material.usedQuantity)
                } else {
                    materialUsage[material.inventoryItemId] = (material, material.usedQuantity)
                }
            }
        }
        
        // Convertir a array y ordenar
        let topMaterials = materialUsage.values
            .sorted(by: { $0.count > $1.count })
            .prefix(limit)
            .map { ($0.material, $0.count) }
        
        return Array(topMaterials)
    }
} 