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
        
        // Buscar campos adicionales en la respuesta del servidor
        // Estos campos son agregados por la implementación del backend
        
        // Para manejo de coordenadas
        if let coordinates = extractDataFromAnyJSON("pointCoordinates", ofType: [Double].self) {
            additionalData["pointCoordinates"] = coordinates
        }
        
        // Para manejo de detalles del proyecto
        if let projectId = extractDataFromAnyJSON("projectId", ofType: String.self) {
            additionalData["projectId"] = projectId
        }
        
        if let projectName = extractDataFromAnyJSON("projectName", ofType: String.self) {
            additionalData["projectName"] = projectName
        }
        
        if let pointId = extractDataFromAnyJSON("pointId", ofType: String.self) {
            additionalData["pointId"] = pointId
        }
        
        if let pointType = extractDataFromAnyJSON("pointType", ofType: String.self) {
            additionalData["pointType"] = pointType
        }
        
        // Para el cable instalado
        if let cableInstalled = extractDataFromAnyJSON("cableInstalled", ofType: [String: Any].self) {
            additionalData["cableInstalled"] = cableInstalled
        }
        
        // Para el equipo dañado
        if let damagedEquipment = extractDataFromAnyJSON("damagedEquipment", ofType: [String].self) {
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
    
    // Función auxiliar para extraer datos de cualquier tipo de la respuesta JSON
    private func extractDataFromAnyJSON<T>(_ key: String, ofType: T.Type) -> T? {
        // Esta función sería implementada en una versión real del servicio
        // con acceso al JSON original. Para el propósito de este ejemplo, retorna nil.
        return nil
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
        // Preparar el cuerpo de la petición con los datos del modelo
        var body: [String: Any] = [
            "deviceName": task.deviceName,
            "taskType": task.taskType,
            "maintenanceType": task.maintenanceType,
            "description": task.description,
            "status": task.status,
            "scheduledDate": task.scheduledDate,
            "assignedTo": task.assignedTo,
            "priority": task.priority,
            "location": task.location,
            "siteName": task.siteName
        ]
        
        // Agregar datos del punto del proyecto si existen
        if let projectId = task.additionalData["projectId"] as? String {
            body["projectId"] = projectId
        }
        
        if let pointId = task.additionalData["pointId"] as? String {
            body["pointId"] = pointId
        }
        
        if let pointCoordinates = task.additionalData["pointCoordinates"] as? [Double], 
           pointCoordinates.count == 2 {
            body["pointLatitude"] = pointCoordinates[0]
            body["pointLongitude"] = pointCoordinates[1]
        }
        
        // Agregar equipos dañados si existen
        if let damagedEquipment = task.additionalData["damagedEquipment"] as? [String], 
           !damagedEquipment.isEmpty {
            body["damagedEquipment"] = damagedEquipment
        }
        
        // Agregar cables instalados si existen
        if let cableInstalled = task.additionalData["cableInstalled"] as? [String: String], 
           !cableInstalled.isEmpty {
            body["cableInstalled"] = cableInstalled
        }
        
        return APIClient.shared.request(
            endpoint: "/maintenance/tasks",
            method: "POST",
            body: body
        )
        .map { (taskDTO: MaintenanceTaskDTO) -> MaintenanceTask in
            return taskDTO.toMaintenanceTask()
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
            return Fail(error: APIError.unknown).eraseToAnyPublisher()
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