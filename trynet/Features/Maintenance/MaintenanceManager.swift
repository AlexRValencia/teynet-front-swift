import SwiftUI
import Foundation
import PDFKit
import Combine

class MaintenanceManager: ObservableObject {
    @Published var tasks: [MaintenanceTask] = []
    @Published var supportRequests: [SupportRequest] = []
    
    // Para filtrar tareas
    @Published var currentStatusFilter: String = "Todos"
    @Published var currentTypeFilter: String = "Todos"
    @Published var filteredTasks: [MaintenanceTask] = []
    
    // Estado para la generación de PDF
    @Published var isGeneratingPDF = false
    @Published var lastGeneratedPDF: URL?
    
    // Estado para indicar carga y errores
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Servicio para comunicación con el backend
    private let maintenanceService = MaintenanceService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTasks()
    }
    
    // Método para cargar tareas desde el backend
    func loadTasks() {
        isLoading = true
        
        maintenanceService.fetchMaintenanceTasks()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.message
                        print("❌ Error al cargar tareas de mantenimiento: \(error.message)")
                    }
                },
                receiveValue: { [weak self] fetchedTasks in
                    guard let self = self else { return }
                    
                    self.tasks = fetchedTasks
                    self.filterTasks() // Aplicar filtros actuales
                    
                    // Procesar para soporte - aquí se adaptaría a la nueva estructura de datos
                    self.processSupportRequests()
                    
                    // Para depuración, mostramos información sobre las tareas
                    print("📊 Tareas cargadas: \(fetchedTasks.count)")
                    
                    if !fetchedTasks.isEmpty {
                        // Verificamos las coordenadas y otros datos clave
                        for task in fetchedTasks {
                            if let coords = task.pointCoordinates {
                                print("📍 Coordenadas para \(task.siteName): \(coords)")
                            }
                            
                            // Verificar cable instalado
                            if !task.cableInstalled.isEmpty {
                                print("🔌 Cable instalado para \(task.siteName): \(task.cableInstalled)")
                            }
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Método privado para cargar datos iniciales de ejemplo (modo offline)
    private func loadInitialTasks() {
        print("📱 Cargando datos de ejemplo para modo offline")
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
    
    // Método para refrescar tareas (recargar desde el backend)
    func refreshTasks() {
        loadTasks()
    }
    
    // Añadir una nueva tarea
    func addTask(_ task: MaintenanceTask) {
        isLoading = true
        
        maintenanceService.createMaintenanceTask(task: task)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.message
                        print("❌ Error al crear tarea de mantenimiento: \(error.message)")
                        
                        // Añadimos la tarea localmente de todos modos para no perder los datos
                        self?.tasks.append(task)
                    }
                },
                receiveValue: { [weak self] newTask in
                    self?.tasks.append(newTask)
                    print("✅ Tarea de mantenimiento creada con éxito: \(newTask.id)")
                }
            )
            .store(in: &cancellables)
    }
    
    // Actualizar una tarea existente
    func updateTask(_ updatedTask: MaintenanceTask) {
        // Primero actualizamos localmente para que la UI refleje los cambios inmediatamente
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            tasks[index] = updatedTask
        }
        
        // Luego enviamos la actualización al backend
        maintenanceService.updateMaintenanceTask(task: updatedTask)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error al actualizar tarea de mantenimiento: \(error.message)")
                    }
                },
                receiveValue: { _ in
                    print("✅ Tarea de mantenimiento actualizada con éxito: \(updatedTask.id)")
                }
            )
            .store(in: &cancellables)
    }
    
    // Actualizar solo el estado de una tarea
    func updateTaskStatus(taskId: String, newStatus: String) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            // Crear una copia de la tarea con el nuevo estado
            var updatedTask = tasks[index]
            updatedTask.status = newStatus
            
            // Si el estado es "Finalizado", actualizar la fecha de finalización
            if newStatus == "Finalizado" {
                updatedTask.completedDate = getCurrentDateString()
            }
            
            // Actualizar localmente
            tasks[index] = updatedTask
            
            // Actualizar en el backend
            updateTask(updatedTask)
        }
    }
    
    // Eliminar una tarea
    func deleteTask(id: String) {
        // Primero eliminamos localmente para actualizar la UI inmediatamente
        tasks.removeAll { $0.id == id }
        
        // Luego enviamos la solicitud de eliminación al backend
        maintenanceService.deleteMaintenanceTask(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error al eliminar tarea de mantenimiento: \(error.message)")
                    }
                },
                receiveValue: { success in
                    if success {
                        print("✅ Tarea de mantenimiento eliminada con éxito: \(id)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Filtrar tareas basado en los filtros actuales
    func filterTasks() {
        filteredTasks = tasks.filter { task in
            (currentStatusFilter == "Todos" || task.status == currentStatusFilter) &&
            (currentTypeFilter == "Todos" || task.maintenanceType == currentTypeFilter)
        }
    }
    
    // Actualizar filtros y aplicarlos
    func updateFilters(statusFilter: String, typeFilter: String) {
        currentStatusFilter = statusFilter
        currentTypeFilter = typeFilter
        filterTasks()
    }
    
    // Procesar tareas para encontrar solicitudes de soporte
    func processSupportRequests() {
        // Limpiar las solicitudes anteriores que fueron creadas localmente
        supportRequests.removeAll { request in
            // Solo conservar las que tienen un ID que no sea un UUID local
            return request.id.contains("-")
        }
        
        // Buscar tareas con solicitudes de soporte
        for task in tasks {
            if task.supportRequested, let details = task.supportRequestDetails {
                // Verificar si ya existe una solicitud para esta tarea
                if !supportRequests.contains(where: { $0.taskId == task.id }) {
                    // Crear una nueva solicitud de soporte
                    let supportRequest = SupportRequest(
                        id: "SR-\(task.id)", // Prefijo para distinguir de UUIDs locales
                        taskId: task.id,
                        details: details,
                        status: "Pendiente",
                        requestDate: Date(), // Usamos la fecha actual como aproximación
                        deviceName: task.deviceName,
                        location: task.location,
                        siteName: task.siteName
                    )
                    supportRequests.append(supportRequest)
                }
            }
        }
    }
    
    // Completar una etapa de mantenimiento
    func completeStage(taskId: String, stageName: String, photo: UIImage) {
        // Primero actualizamos localmente la tarea
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
        
        // Luego enviamos la actualización al backend
        maintenanceService.completeStage(taskId: taskId, stageName: stageName, photo: photo)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error al completar etapa de mantenimiento: \(error.message)")
                    }
                },
                receiveValue: { updatedTask in
                    print("✅ Etapa \(stageName) completada con éxito para tarea: \(taskId)")
                    
                    // Actualizar la tarea local con la versión del servidor
                    if let index = self.tasks.firstIndex(where: { $0.id == taskId }) {
                        self.tasks[index] = updatedTask
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Solicitar apoyo para una tarea
    func requestSupport(taskId: String, details: String) {
        // Primero actualizamos localmente
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            let updatedTask = tasks[index].updatedWithSupportRequest(details: details)
            tasks[index] = updatedTask
            
            // Crear una nueva solicitud de apoyo local
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
        
        // Luego enviamos la solicitud al backend
        maintenanceService.requestSupport(taskId: taskId, details: details)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error al solicitar apoyo: \(error.message)")
                    }
                },
                receiveValue: { updatedTask in
                    print("✅ Solicitud de apoyo enviada con éxito para tarea: \(taskId)")
                    
                    // Actualizar la tarea local con la versión del servidor
                    if let index = self.tasks.firstIndex(where: { $0.id == taskId }) {
                        self.tasks[index] = updatedTask
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Obtener fecha actual en formato string
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: Date())
    }
    
    // Generar PDF para una tarea
    func generatePDFReport(for task: MaintenanceTask, completion: @escaping (URL?) -> Void) {
        // Iniciar el indicador de actividad
        isGeneratingPDF = true
        
        // Crear un documento PDF
        let pdfData = createPDFContent(for: task)
        
        // Guardar el PDF en el sistema de archivos
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsDirectory.appendingPathComponent("Mantenimiento_\(task.id)_\(Date().timeIntervalSince1970).pdf")
        
        do {
            try pdfData.write(to: pdfURL)
            
            // Actualizar la tarea con la URL del PDF
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                let updatedTask = tasks[index].updatedWithGeneratedReport(url: pdfURL)
                tasks[index] = updatedTask
                
                // Actualizar en el backend
                updateTask(updatedTask)
            }
            
            lastGeneratedPDF = pdfURL
            isGeneratingPDF = false
            completion(pdfURL)
        } catch {
            print("Error al guardar el PDF: \(error)")
            isGeneratingPDF = false
            completion(nil)
        }
    }
    
    // Crear contenido del PDF
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
                addTextLine("Fecha finalización:", completedDate, y: &yPos)
            }
            
            addTextLine("Descripción:", "", y: &yPos)
            
            let descriptionAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.black
            ]
            let descriptionRect = CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: 100)
            task.description.draw(in: descriptionRect, withAttributes: descriptionAttributes)
            
            yPos += 120
            
            // Etapas del mantenimiento
            let stagesTitle = "Etapas del mantenimiento"
            let stagesTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: attributeFont,
                .foregroundColor: UIColor.black
            ]
            let stagesTitleRect = CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: 30)
            stagesTitle.draw(in: stagesTitleRect, withAttributes: stagesTitleAttributes)
            
            yPos += 40
            
            for stage in task.stages {
                let stageAttributes: [NSAttributedString.Key: Any] = [
                    .font: textFont,
                    .foregroundColor: UIColor.black
                ]
                
                let statusText = stage.isCompleted ? "✓ Completado" : "○ Pendiente"
                let stageText = "\(stage.name) (\(Int(stage.percentageValue * 100))%): \(statusText)"
                let stageRect = CGRect(x: 70, y: yPos, width: pageRect.width - 140, height: 20)
                stageText.draw(in: stageRect, withAttributes: stageAttributes)
                
                yPos += 25
            }
            
            // Fotos (aquí solo mencionamos que hay fotos)
            yPos += 20
            let photosTitle = "Fotos adjuntas: \(task.stagePhotos.filter { $0 != nil }.count)"
            let photosTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: attributeFont,
                .foregroundColor: UIColor.black
            ]
            let photosTitleRect = CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: 30)
            photosTitle.draw(in: photosTitleRect, withAttributes: photosTitleAttributes)
        }
        
        return data
    }
}

// Modelo para solicitudes de apoyo
struct SupportRequest: Identifiable {
    let id: String
    let taskId: String
    let details: String
    var status: String
    let requestDate: Date
    let deviceName: String
    let location: String
    let siteName: String
    var responseDetails: String?
    var responseDate: Date?
    
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
    
    var statusColor: Color {
        switch status {
        case "Pendiente":
            return .orange
        case "En proceso":
            return .blue
        case "Resuelto":
            return .green
        case "Rechazado":
            return .red
        default:
            return .gray
        }
    }
} 