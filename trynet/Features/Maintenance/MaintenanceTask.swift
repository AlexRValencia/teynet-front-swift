import Foundation
import SwiftUI

// Modelo para representar cada etapa de un mantenimiento y su porcentaje
struct MaintenanceStage: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var description: String
    var percentageValue: Double
    var isCompleted: Bool = false
    var photos: [MaintenancePhoto] = []
    
    // Para que sea Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MaintenanceStage, rhs: MaintenanceStage) -> Bool {
        return lhs.id == rhs.id
    }
}

// Modelo para representar una foto en una etapa
struct MaintenancePhoto: Identifiable, Hashable {
    var id = UUID()
    var imageData: Data?
    var imageName: String
    var caption: String
    var timestamp: Date
    
    // Para que sea Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MaintenancePhoto, rhs: MaintenancePhoto) -> Bool {
        return lhs.id == rhs.id
    }
}

struct MaintenanceTask: Identifiable, Hashable {
    let id: String
    let deviceName: String
    let taskType: String
    let maintenanceType: String
    let description: String
    var status: String
    let scheduledDate: String
    var completedDate: String?
    let assignedTo: String
    let priority: String
    let location: String
    let siteName: String
    
    // Datos adicionales opcionales
    var additionalData: [String: Any] = [:]
    
    // Propiedades computadas para acceder a los datos adicionales
    var damagedEquipment: [String] {
        return (additionalData["damagedEquipment"] as? [String]) ?? []
    }
    
    var cableInstalled: [String: String] {
        return (additionalData["cableInstalled"] as? [String: String]) ?? [:]
    }
    
    // Fotos
    var initialPhotos: [UIImage] {
        return (additionalData["initialPhotos"] as? [UIImage]) ?? []
    }
    
    var finalPhotos: [UIImage] {
        return (additionalData["finalPhotos"] as? [UIImage]) ?? []
    }
    
    // Etapas del mantenimiento con sus respectivos porcentajes
    var stages: [MaintenanceStage] {
        return (additionalData["stages"] as? [MaintenanceStage]) ?? [
            MaintenanceStage(name: "Llegada", description: "Foto para validar que se llegó al sitio", percentageValue: 0.10, isCompleted: false),
            MaintenanceStage(name: "Diagnóstico", description: "Identificar el problema y solicitar apoyo de ser necesario", percentageValue: 0.10, isCompleted: false),
            MaintenanceStage(name: "Materiales", description: "Verificar si se cuenta con los materiales o si hay que esperar a reunirlos", percentageValue: 0.50, isCompleted: false),
            MaintenanceStage(name: "Conclusión", description: "Foto de conclusión del servicio", percentageValue: 0.30, isCompleted: false)
        ]
    }
    
    // Indica si se ha solicitado apoyo
    var supportRequested: Bool {
        return (additionalData["supportRequested"] as? Bool) ?? false
    }
    
    // Detalles de la solicitud de apoyo
    var supportRequestDetails: String? {
        return additionalData["supportRequestDetails"] as? String
    }
    
    // Indica si se ha generado un reporte en PDF
    var hasGeneratedReport: Bool {
        return (additionalData["hasGeneratedReport"] as? Bool) ?? false
    }
    
    // URL del reporte PDF generado
    var reportURL: URL? {
        if let urlString = additionalData["reportURL"] as? String {
            return URL(string: urlString)
        }
        return nil
    }
    
    // Color basado en el tipo de mantenimiento
    var typeColor: Color {
        maintenanceType == "Correctivo" ? .red : .blue
    }
    
    // Color basado en la prioridad
    var priorityColor: Color {
        switch priority {
        case "Alta":
            return .red
        case "Media":
            return .orange
        case "Baja":
            return .green
        default:
            return .gray
        }
    }
    
    // Progreso total basado en las etapas completadas
    var progress: Double {
        var completedPercentage = 0.0
        for stage in stages {
            if stage.isCompleted {
                completedPercentage += stage.percentageValue
            }
        }
        return completedPercentage
    }
    
    // Verifica si cumple con el requisito mínimo de fotos (al menos 4)
    var hasMinimumRequiredPhotos: Bool {
        let stagePhotosCount = stages.reduce(0) { count, stage in
            count + stage.photos.count
        }
        let allPhotosCount = stagePhotosCount + initialPhotos.count + finalPhotos.count
        return allPhotosCount >= 4
    }
    
    // Propiedad calculada para acceder a las fotos de las etapas de manera más conveniente
    var stagePhotos: [UIImage?] {
        return stages.map { stage in
            if let photoData = stage.photos.first?.imageData {
                return UIImage(data: photoData)
            }
            return nil
        }
    }
    
    // Para hacerlo Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MaintenanceTask, rhs: MaintenanceTask) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Inicializador más completo para crear tareas con datos adicionales
    init(id: String, deviceName: String, taskType: String, maintenanceType: String, 
         description: String, status: String, scheduledDate: String, completedDate: String? = nil, 
         assignedTo: String, priority: String, location: String, siteName: String,
         additionalData: [String: Any] = [:]) {
        
        self.id = id
        self.deviceName = deviceName
        self.taskType = taskType
        self.maintenanceType = maintenanceType
        self.description = description
        self.status = status
        self.scheduledDate = scheduledDate
        self.completedDate = completedDate
        self.assignedTo = assignedTo
        self.priority = priority
        self.location = location
        self.siteName = siteName
        self.additionalData = additionalData
    }
    
    var statusColor: Color {
        switch status {
        case "Pendiente":
            return .yellow
        case "En desarrollo":
            return .blue
        case "Finalizado":
            return .green
        case "Cancelado":
            return .red
        default:
            return .gray
        }
    }
}

// Extensión para MaintenanceTask con funcionalidades adicionales
extension MaintenanceTask {
    // Crear una tarea de muestra para previsualizaciones
    static func sampleTask() -> MaintenanceTask {
        return MaintenanceTask(
            id: "sample-1",
            deviceName: "Cámara IP exterior",
            taskType: "Revisión",
            maintenanceType: "Preventivo",
            description: "REVISION ELECTRICA DE EQUIPOS, SOPLETEADO DE GABINETES Y REVISION DE CONEXIONES, LIMPIEZA DE CAMARAS Y EQUIPOS, AJUSTES NECESARIOS DE CAMARAS Y AJUSTE DE TORNILLERIA.",
            status: "Finalizado",
            scheduledDate: "10/02/2023",
            completedDate: "12/02/2023",
            assignedTo: "Carlos Sánchez",
            priority: "Alta",
            location: "Acuña",
            siteName: "A1-CCTV",
            additionalData: ["damagedEquipment": ["Fuente de poder", "Cable UTP"],
                           "cableInstalled": ["UTP": "5", "Eléctrico": "3", "Fibra": "0"]]
        )
    }
    
    // Método para crear una nueva tarea con datos adicionales como equipos dañados, cables, etc.
    static func createTask(id: String = UUID().uuidString, deviceName: String, taskType: String,
                          maintenanceType: String, description: String, status: String = "Pendiente",
                          scheduledDate: String, completedDate: String? = nil, assignedTo: String,
                          priority: String, location: String, siteName: String,
                          damagedEquipment: [String] = [], cableInstalled: [String: String] = [:],
                          initialPhotos: [UIImage] = [], finalPhotos: [UIImage] = []) -> MaintenanceTask {
        
        var additionalData: [String: Any] = [:]
        
        if !damagedEquipment.isEmpty {
            additionalData["damagedEquipment"] = damagedEquipment
        }
        
        if !cableInstalled.isEmpty {
            additionalData["cableInstalled"] = cableInstalled
        }
        
        if !initialPhotos.isEmpty {
            additionalData["initialPhotos"] = initialPhotos
        }
        
        if !finalPhotos.isEmpty {
            additionalData["finalPhotos"] = finalPhotos
        }
        
        // Inicializar etapas del mantenimiento
        let defaultStages = [
            MaintenanceStage(name: "Llegada", description: "Foto para validar que se llegó al sitio", percentageValue: 0.10, isCompleted: false),
            MaintenanceStage(name: "Diagnóstico", description: "Identificar el problema y solicitar apoyo de ser necesario", percentageValue: 0.10, isCompleted: false),
            MaintenanceStage(name: "Materiales", description: "Verificar si se cuenta con los materiales o si hay que esperar a reunirlos", percentageValue: 0.50, isCompleted: false),
            MaintenanceStage(name: "Conclusión", description: "Foto de conclusión del servicio", percentageValue: 0.30, isCompleted: false)
        ]
        
        additionalData["stages"] = defaultStages
        
        return MaintenanceTask(
            id: id,
            deviceName: deviceName,
            taskType: taskType,
            maintenanceType: maintenanceType,
            description: description,
            status: status,
            scheduledDate: scheduledDate,
            completedDate: completedDate,
            assignedTo: assignedTo,
            priority: priority,
            location: location,
            siteName: siteName,
            additionalData: additionalData
        )
    }
    
    // Método para actualizar una etapa de la tarea
    func updatedWithCompletedStage(stageName: String, photo: UIImage) -> MaintenanceTask {
        var updatedAdditionalData = additionalData
        var updatedStages = self.stages
        
        if let index = updatedStages.firstIndex(where: { $0.name == stageName }) {
            var updatedStage = updatedStages[index]
            updatedStage.isCompleted = true
            
            // Añadir foto a la etapa
            let newPhoto = MaintenancePhoto(
                imageData: photo.jpegData(compressionQuality: 0.8),
                imageName: "\(stageName)_\(Date().timeIntervalSince1970)",
                caption: "Foto para la etapa: \(stageName)",
                timestamp: Date()
            )
            
            updatedStage.photos.append(newPhoto)
            updatedStages[index] = updatedStage
        }
        
        updatedAdditionalData["stages"] = updatedStages
        
        return MaintenanceTask(
            id: id,
            deviceName: deviceName,
            taskType: taskType,
            maintenanceType: maintenanceType,
            description: description,
            status: self.progress >= 1.0 ? "Finalizado" : "En desarrollo",
            scheduledDate: scheduledDate,
            completedDate: self.progress >= 1.0 ? getCurrentDateString() : completedDate,
            assignedTo: assignedTo,
            priority: priority,
            location: location,
            siteName: siteName,
            additionalData: updatedAdditionalData
        )
    }
    
    // Método para solicitar apoyo
    func updatedWithSupportRequest(details: String) -> MaintenanceTask {
        var updatedAdditionalData = additionalData
        updatedAdditionalData["supportRequested"] = true
        updatedAdditionalData["supportRequestDetails"] = details
        
        return MaintenanceTask(
            id: id,
            deviceName: deviceName,
            taskType: taskType,
            maintenanceType: maintenanceType,
            description: description,
            status: status,
            scheduledDate: scheduledDate,
            completedDate: completedDate,
            assignedTo: assignedTo,
            priority: priority,
            location: location,
            siteName: siteName,
            additionalData: updatedAdditionalData
        )
    }
    
    // Método para marcar que se ha generado un reporte PDF
    func updatedWithGeneratedReport(url: URL) -> MaintenanceTask {
        var updatedAdditionalData = additionalData
        updatedAdditionalData["hasGeneratedReport"] = true
        updatedAdditionalData["reportURL"] = url.absoluteString
        
        return MaintenanceTask(
            id: id,
            deviceName: deviceName,
            taskType: taskType,
            maintenanceType: maintenanceType,
            description: description,
            status: status,
            scheduledDate: scheduledDate,
            completedDate: completedDate,
            assignedTo: assignedTo,
            priority: priority,
            location: location,
            siteName: siteName,
            additionalData: updatedAdditionalData
        )
    }
    
    // Método auxiliar para obtener la fecha actual formateada
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: Date())
    }
} 