import SwiftUI
import Foundation
import PDFKit

class MaintenanceManager: ObservableObject {
    @Published var tasks: [MaintenanceTask] = []
    @Published var supportRequests: [SupportRequest] = []
    
    // Estado para la generación de PDF
    @Published var isGeneratingPDF = false
    @Published var lastGeneratedPDF: URL?
    
    init() {
        loadInitialTasks()
    }
    
    private func loadInitialTasks() {
        // En una aplicación real, cargaríamos desde la API o base de datos
        tasks = [
            MaintenanceTask(
                id: "1",
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
            ),
            MaintenanceTask(
                id: "2",
                deviceName: "DVR 16 canales",
                taskType: "Limpieza",
                maintenanceType: "Preventivo",
                description: "Limpieza de polvo y revisión de configuración",
                status: "Pendiente",
                scheduledDate: "15/03/2023",
                completedDate: nil,
                assignedTo: "María López",
                priority: "Media",
                location: "Torreón",
                siteName: "T1-SISTEMA"
            ),
            MaintenanceTask(
                id: "3",
                deviceName: "Punto de acceso WiFi",
                taskType: "Reparación",
                maintenanceType: "Correctivo",
                description: "Reemplazo de fuente de alimentación dañada",
                status: "En desarrollo",
                scheduledDate: "05/03/2023",
                completedDate: nil,
                assignedTo: "Roberto Martínez",
                priority: "Baja",
                location: "Piedras Negras",
                siteName: "PN3-WIFI"
            ),
            MaintenanceTask(
                id: "4",
                deviceName: "Switch de red",
                taskType: "Actualización",
                maintenanceType: "Correctivo",
                description: "Actualización de firmware y configuración",
                status: "Finalizado",
                scheduledDate: "28/02/2023",
                completedDate: "02/03/2023",
                assignedTo: "Ana Gómez",
                priority: "Alta",
                location: "Monclova",
                siteName: "M2-RED"
            )
        ]
    }
    
    func addTask(_ task: MaintenanceTask) {
        tasks.append(task)
        // En una aplicación real, guardaríamos en la API o base de datos
    }
    
    func updateTask(_ updatedTask: MaintenanceTask) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
            // En una aplicación real, actualizaríamos en la API o base de datos
        }
    }
    
    func updateTaskStatus(taskId: String, newStatus: String) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].status = newStatus
            // Si el estado es "Finalizado", actualizar la fecha de finalización
            if newStatus == "Finalizado" {
                tasks[index].completedDate = getCurrentDateString()
            }
        }
    }
    
    func deleteTask(id: String) {
        tasks.removeAll { $0.id == id }
        // En una aplicación real, eliminaríamos de la API o base de datos
    }
    
    func getFilteredTasks(statusFilter: String, typeFilter: String) -> [MaintenanceTask] {
        return tasks.filter { task in
            (statusFilter == "Todos" || task.status == statusFilter) &&
            (typeFilter == "Todos" || task.maintenanceType == typeFilter)
        }
    }
    
    func completeStage(taskId: String, stageName: String, photo: UIImage) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            let updatedTask = tasks[index].updatedWithCompletedStage(stageName: stageName, photo: photo)
            tasks[index] = updatedTask
            
            // Si todas las etapas están completas, marcamos la tarea como completada
            if updatedTask.progress >= 1.0 {
                updateTaskStatus(taskId: taskId, newStatus: "Finalizado")
            } else {
                updateTaskStatus(taskId: taskId, newStatus: "En desarrollo")
            }
        }
    }
    
    func requestSupport(taskId: String, details: String) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            let updatedTask = tasks[index].updatedWithSupportRequest(details: details)
            tasks[index] = updatedTask
            
            // Crear una nueva solicitud de apoyo
            let supportRequest = SupportRequest(
                id: UUID().uuidString,
                taskId: taskId,
                details: details,
                status: "Pendiente",
                requestDate: Date(),
                deviceName: updatedTask.deviceName,
                location: updatedTask.location,
                siteName: updatedTask.siteName
            )
            
            supportRequests.append(supportRequest)
        }
    }
    
    func generatePDFReport(for task: MaintenanceTask, completion: @escaping (URL?) -> Void) {
        // Iniciar el indicador de actividad
        isGeneratingPDF = true
        
        // Simular la generación de un PDF (en una aplicación real, esto sería más complejo)
        DispatchQueue.global(qos: .userInitiated).async {
            // Crear un documento PDF
            let pdfData = self.createPDFContent(for: task)
            
            // Guardar el PDF en el sistema de archivos
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let pdfURL = documentsDirectory.appendingPathComponent("Mantenimiento_\(task.id)_\(Date().timeIntervalSince1970).pdf")
            
            do {
                try pdfData.write(to: pdfURL)
                
                DispatchQueue.main.async {
                    // Actualizar la tarea con la URL del PDF
                    if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                        let updatedTask = self.tasks[index].updatedWithGeneratedReport(url: pdfURL)
                        self.tasks[index] = updatedTask
                    }
                    
                    self.lastGeneratedPDF = pdfURL
                    self.isGeneratingPDF = false
                    completion(pdfURL)
                }
            } catch {
                print("Error al guardar el PDF: \(error)")
                DispatchQueue.main.async {
                    self.isGeneratingPDF = false
                    completion(nil)
                }
            }
        }
    }
    
    private func createPDFContent(for task: MaintenanceTask) -> Data {
        // En una app real, aquí se utilizaría PDFKit para crear un PDF completo
        // Esta es una implementación simplificada
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Trynet Mantenimiento",
            kCGPDFContextAuthor: "Sistema de mantenimiento Trynet",
            kCGPDFContextTitle: "Reporte de mantenimiento: \(task.deviceName)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Dibujar contenido del PDF
            let textFont = UIFont.systemFont(ofSize: 12)
            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let attributeFont = UIFont.boldSystemFont(ofSize: 14)
            
            // Título
            let title = "Reporte de Mantenimiento"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let titleRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: 50)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Información básica
            var yPos: CGFloat = 120
            
            // Función para añadir una línea de texto
            func addTextLine(_ label: String, _ value: String, y: inout CGFloat) {
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: attributeFont,
                    .foregroundColor: UIColor.black
                ]
                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: textFont,
                    .foregroundColor: UIColor.black
                ]
                
                let labelRect = CGRect(x: 50, y: y, width: 150, height: 20)
                let valueRect = CGRect(x: 200, y: y, width: pageRect.width - 250, height: 20)
                
                label.draw(in: labelRect, withAttributes: labelAttributes)
                value.draw(in: valueRect, withAttributes: valueAttributes)
                
                y += 25
            }
            
            addTextLine("Dispositivo:", task.deviceName, y: &yPos)
            addTextLine("Tipo:", "\(task.taskType) - \(task.maintenanceType)", y: &yPos)
            addTextLine("Estado:", task.status, y: &yPos)
            addTextLine("Asignado a:", task.assignedTo, y: &yPos)
            addTextLine("Ubicación:", "\(task.location) - \(task.siteName)", y: &yPos)
            addTextLine("Fecha programada:", task.scheduledDate, y: &yPos)
            
            if let completedDate = task.completedDate {
                addTextLine("Fecha finalizado:", completedDate, y: &yPos)
            }
            
            yPos += 20
            
            // Descripción
            let descriptionLabel = "Descripción:"
            let descLabelRect = CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: 20)
            descriptionLabel.draw(in: descLabelRect, withAttributes: [.font: attributeFont])
            
            yPos += 25
            
            let descRect = CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: 100)
            task.description.draw(in: descRect, withAttributes: [.font: textFont])
            
            yPos += 120
            
            // Progreso
            let progressLabel = "Progreso: \(Int(task.progress * 100))%"
            progressLabel.draw(in: CGRect(x: 50, y: yPos, width: 200, height: 20), withAttributes: [.font: attributeFont])
            
            yPos += 25
            
            // Etapas
            let stagesLabel = "Etapas del mantenimiento:"
            stagesLabel.draw(in: CGRect(x: 50, y: yPos, width: 300, height: 20), withAttributes: [.font: attributeFont])
            
            yPos += 25
            
            for stage in task.stages {
                let stageText = "• \(stage.name): \(stage.isCompleted ? "Completada" : "Pendiente") - \(Int(stage.percentageValue * 100))%"
                stageText.draw(in: CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: 20), withAttributes: [.font: textFont])
                yPos += 20
            }
            
            // Añadir más información según sea necesario
        }
        
        return data
    }
    
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: Date())
    }
}

// Modelo para las solicitudes de apoyo
struct SupportRequest: Identifiable {
    let id: String
    let taskId: String
    let details: String
    var status: String // "Pendiente", "En desarrollo", "Finalizado"
    let requestDate: Date
    let deviceName: String
    let location: String
    let siteName: String
    var responseDate: Date?
    var responseDetails: String?
    
    var formattedRequestDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: requestDate)
    }
    
    var formattedResponseDate: String? {
        guard let date = responseDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
} 