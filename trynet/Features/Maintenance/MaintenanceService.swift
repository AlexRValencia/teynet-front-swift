import Foundation
import Combine
import SwiftUI

// Estructura para manejar la respuesta de tareas de mantenimiento del API
struct MaintenanceResponse: Codable {
    let ok: Bool
    let data: MaintenanceData
    
    struct MaintenanceData: Codable {
        let maintenance: [MaintenanceTaskDTO]
        let pagination: PaginationInfo
    }
    
    struct PaginationInfo: Codable {
        let total: Int
        let page: Int
        let limit: Int
        let totalPages: Int
    }
}

// Estructura para manejar la respuesta de una tarea específica
struct MaintenanceDetailResponse: Codable {
    let ok: Bool
    let data: MaintenanceTaskDTO
}

// Estructura para manejar la respuesta de creación de una tarea
struct MaintenanceCreateResponse: Codable {
    let ok: Bool
    let message: String
    let data: MaintenanceTaskDTO
}

// DTO para la tarea de mantenimiento (Data Transfer Object)
struct MaintenanceTaskDTO: Codable {
    let id: String
    let deviceName: String
    let taskType: String
    let maintenanceType: String
    let description: String
    let status: String
    let scheduledDate: String
    let completedDate: String?
    let assignedTo: String
    let priority: String
    let location: String
    let siteName: String
    let stages: [MaintenanceStageDTO]?
    let supportRequested: Bool?
    let supportRequestDetails: String?
    
    // Propiedades adicionales que pueden estar en la respuesta
    let projectId: String?
    let projectName: String?
    let pointId: String?
    let pointType: String?
    let pointCoordinates: [Double]?
    let pointLatitude: Double?
    let pointLongitude: Double?
    let damagedEquipment: [String]?
    let cableInstalled: [String: Double]?
    
    // Método para convertir el DTO a un modelo de dominio
    func toMaintenanceTask() -> MaintenanceTask {
        // Creamos un diccionario para los datos adicionales
        var additionalData: [String: Any] = [:]
        
        // Convertimos las etapas si existen
        if let stages = stages {
            let domainStages = stages.map { $0.toMaintenanceStage() }
            additionalData["stages"] = domainStages
        }
        
        // Agregamos otros datos adicionales
        if let supportRequested = supportRequested {
            additionalData["supportRequested"] = supportRequested
        }
        
        if let supportRequestDetails = supportRequestDetails {
            additionalData["supportRequestDetails"] = supportRequestDetails
        }
        
        // Para manejo de coordenadas
        if let coordinates = processCoordinates() {
            additionalData["pointCoordinates"] = coordinates
            if coordinates.count >= 2 {
                additionalData["pointLatitude"] = coordinates[0]
                additionalData["pointLongitude"] = coordinates[1]
            }
        }
        
        // Para manejo de detalles del proyecto
        if let projectId = projectId {
            additionalData["projectId"] = projectId
        }
        
        if let projectName = projectName {
            additionalData["projectName"] = projectName
        }
        
        if let pointId = pointId {
            additionalData["pointId"] = pointId
        }
        
        if let pointType = pointType {
            additionalData["pointType"] = pointType
        }
        
        // Para el cable instalado
        if let cableInstalledMap = processCableInstalled() {
            additionalData["cableInstalled"] = cableInstalledMap
        }
        
        // Para el equipo dañado
        if let damagedEquipment = damagedEquipment {
            additionalData["damagedEquipment"] = damagedEquipment
        }
        
        // Creamos la tarea con los datos del DTO
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
}

// DTO para una etapa de mantenimiento
struct MaintenanceStageDTO: Codable {
    let name: String
    let description: String
    let percentageValue: Double
    let isCompleted: Bool
    let photos: [MaintenancePhotoDTO]?
    
    // Método para convertir a un modelo de dominio
    func toMaintenanceStage() -> MaintenanceStage {
        let stagePhotos = photos?.map { $0.toMaintenancePhoto() } ?? []
        
        return MaintenanceStage(
            name: name,
            description: description,
            percentageValue: percentageValue,
            isCompleted: isCompleted,
            photos: stagePhotos
        )
    }
}

// DTO para una foto de mantenimiento
struct MaintenancePhotoDTO: Codable {
    let imageUrl: String?
    let imageData: String? // Base64
    let imageName: String
    let caption: String
    let timestamp: String
    
    // Método para convertir a un modelo de dominio
    func toMaintenancePhoto() -> MaintenancePhoto {
        var photoData: Data? = nil
        
        // Convertir de Base64 a Data si existe
        if let imageDataString = imageData {
            photoData = Data(base64Encoded: imageDataString)
        }
        
        // Convertir el timestamp a Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = dateFormatter.date(from: timestamp) ?? Date()
        
        return MaintenancePhoto(
            imageData: photoData,
            imageName: imageName,
            caption: caption,
            timestamp: date
        )
    }
}

// Estructura vacía para respuestas sin contenido en este servicio
private struct MaintenanceEmptyResponse: Codable {}

// Servicio para comunicarse con el backend de mantenimiento
class MaintenanceService {
    private var cancellables = Set<AnyCancellable>()
    
    // Obtener todas las tareas de mantenimiento
    func fetchMaintenanceTasks() -> AnyPublisher<[MaintenanceTask], APIError> {
        return APIClient.shared.request(endpoint: "/maintenance/tasks")
            .map { (response: MaintenanceResponse) -> [MaintenanceTask] in
                return response.data.maintenance.map { $0.toMaintenanceTask() }
            }
            .eraseToAnyPublisher()
    }
    
    // Obtener una tarea específica
    func fetchMaintenanceTask(id: String) -> AnyPublisher<MaintenanceTask, APIError> {
        return APIClient.shared.request(endpoint: "/maintenance/tasks/\(id)")
            .map { (response: MaintenanceDetailResponse) -> MaintenanceTask in
                return response.data.toMaintenanceTask()
            }
            .eraseToAnyPublisher()
    }
    
    // Crear una nueva tarea de mantenimiento
    func createMaintenanceTask(task: MaintenanceTask) -> AnyPublisher<MaintenanceTask, APIError> {
        // Preparar el cuerpo de la petición con los datos obligatorios
        var body: [String: Any] = [
            "deviceName": task.deviceName,
            "taskType": task.taskType,
            "maintenanceType": task.maintenanceType,
            "status": "Pendiente", // Siempre pendiente al crear
            "scheduledDate": task.scheduledDate,
            "priority": task.priority,
            "location": task.location,
            "siteName": task.siteName,
            "description": task.description.isEmpty ? "Tarea de mantenimiento programada" : task.description,
            "assignedTo": task.assignedTo.isEmpty ? "Por asignar" : task.assignedTo,
            "observations": task.description.isEmpty ? "Tarea de mantenimiento programada" : task.description
        ]
        
        // Agregar datos del punto del proyecto (obligatorio)
        if let projectId = task.additionalData["projectId"] as? String {
            body["projectId"] = projectId
            body["project"] = projectId // Añadir también como 'project' para el backend
        }
        
        if let projectName = task.additionalData["projectName"] as? String {
            body["projectName"] = projectName
        }
        
        if let pointId = task.additionalData["pointId"] as? String {
            body["pointId"] = pointId
            body["point"] = pointId // Añadir también como 'point' para el backend
        }
        
        if let pointType = task.additionalData["pointType"] as? String {
            body["pointType"] = pointType
        }
        
        if let pointCoordinates = task.additionalData["pointCoordinates"] as? [Double], 
           pointCoordinates.count == 2 {
            body["pointLatitude"] = pointCoordinates[0]
            body["pointLongitude"] = pointCoordinates[1]
            body["pointCoordinates"] = pointCoordinates // Añadir como array para el backend
        }
        
        // Agregar campos opcionales solo si tienen valor
        if !task.description.isEmpty {
            body["description"] = task.description
            body["observations"] = task.description
        }
        
        if !task.assignedTo.isEmpty {
            body["assignedTo"] = task.assignedTo
        }
        
        // Agregar equipos dañados solo si existen y no están vacíos
        if let damagedEquipment = task.additionalData["damagedEquipment"] as? [String], 
           !damagedEquipment.isEmpty {
            body["damagedEquipment"] = damagedEquipment
        }
        
        // Agregar cables instalados solo si existen y no están vacíos
        if let cableInstalled = task.additionalData["cableInstalled"] as? [String: String], 
           !cableInstalled.isEmpty {
            body["cableInstalled"] = cableInstalled
        }
        
        // Agregar fotos iniciales si existen
        if let initialPhotos = task.additionalData["initialPhotos"] as? [UIImage], 
           !initialPhotos.isEmpty {
            // Aquí iría la lógica para procesar y subir las fotos
            // Por ahora solo indicamos que hay fotos
            body["hasInitialPhotos"] = true
        }
        
        // Agregar fotos finales si existen
        if let finalPhotos = task.additionalData["finalPhotos"] as? [UIImage], 
           !finalPhotos.isEmpty {
            // Aquí iría la lógica para procesar y subir las fotos
            // Por ahora solo indicamos que hay fotos
            body["hasFinalPhotos"] = true
        }
        
        // Imprimir la solicitud para depuración
        print("📤 Enviando solicitud de creación de tarea: \(body)")
        
        return APIClient.shared.request(
            endpoint: "/maintenance/tasks",
            method: "POST",
            body: body
        )
        .map { (response: MaintenanceCreateResponse) -> MaintenanceTask in
            print("✅ Tarea creada con éxito: \(response.data.id)")
            return response.data.toMaintenanceTask()
        }
        .catch { error in
            print("❌ Error al crear tarea: \(error.message)")
            return Fail<MaintenanceTask, APIError>(error: error).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // Actualizar una tarea existente
    func updateMaintenanceTask(task: MaintenanceTask) -> AnyPublisher<MaintenanceTask, APIError> {
        // Preparar el cuerpo de la petición
        let body: [String: Any] = [
            "deviceName": task.deviceName,
            "taskType": task.taskType,
            "maintenanceType": task.maintenanceType,
            "description": task.description,
            "status": task.status,
            "scheduledDate": task.scheduledDate,
            "completedDate": task.completedDate ?? "",
            "assignedTo": task.assignedTo,
            "priority": task.priority,
            "location": task.location,
            "siteName": task.siteName
        ]
        
        return APIClient.shared.request(
            endpoint: "/maintenance/tasks/\(task.id)",
            method: "PUT",
            body: body
        )
        .map { (taskDTO: MaintenanceTaskDTO) -> MaintenanceTask in
            return taskDTO.toMaintenanceTask()
        }
        .eraseToAnyPublisher()
    }
    
    // Completar una etapa de una tarea
    func completeStage(taskId: String, stageName: String, photo: UIImage) -> AnyPublisher<MaintenanceTask, APIError> {
        // Convertir la imagen a base64
        guard let imageData = photo.jpegData(compressionQuality: 0.7) else {
            return Fail<MaintenanceTask, APIError>(error: APIError.unknown).eraseToAnyPublisher()
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Preparar el cuerpo de la petición
        let body: [String: Any] = [
            "stageName": stageName,
            "photoData": base64String,
            "photoCaption": "Foto de \(stageName)",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        return APIClient.shared.request(
            endpoint: "/maintenance/tasks/\(taskId)/stages/complete",
            method: "POST",
            body: body
        )
        .map { (taskDTO: MaintenanceTaskDTO) -> MaintenanceTask in
            return taskDTO.toMaintenanceTask()
        }
        .eraseToAnyPublisher()
    }
    
    // Eliminar una tarea
    func deleteMaintenanceTask(id: String) -> AnyPublisher<Bool, APIError> {
        return APIClient.shared.request(
            endpoint: "/maintenance/tasks/\(id)",
            method: "DELETE"
        )
        .map { (_: MaintenanceEmptyResponse) -> Bool in
            return true
        }
        .eraseToAnyPublisher()
    }
    
    // Solicitar apoyo para una tarea
    func requestSupport(taskId: String, details: String) -> AnyPublisher<MaintenanceTask, APIError> {
        let body: [String: Any] = [
            "details": details
        ]
        
        return APIClient.shared.request(
            endpoint: "/maintenance/tasks/\(taskId)/support",
            method: "POST",
            body: body
        )
        .map { (taskDTO: MaintenanceTaskDTO) -> MaintenanceTask in
            return taskDTO.toMaintenanceTask()
        }
        .eraseToAnyPublisher()
    }
} 