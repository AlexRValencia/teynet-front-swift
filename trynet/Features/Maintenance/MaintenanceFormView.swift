import SwiftUI
import PhotosUI
// Importaciones necesarias
import Foundation
// Comentamos la importación problemática
// import trynet.Features.Maintenance.MaintenanceTask

struct MaintenanceFormView: View {
    @Binding var isPresented: Bool
    var onSave: (MaintenanceTask) -> Void
    
    // Datos básicos (obligatorios)
    @State private var taskType = "Revisión"
    @State private var maintenanceType = "Preventivo"
    @State private var scheduledDate = Date()
    @State private var priority = "Media"
    @State private var location = ""
    @State private var siteName = ""
    
    // Selección de punto existente
    @State private var showingPointSelector = false
    @State private var selectedProject: Project? = nil
    @State private var selectedPoint: ProjectPoint? = nil
    @ObservedObject private var projectViewModel = ProjectViewModel()
    @ObservedObject private var projectManager = ProjectManager.shared
    
    // Colecciones para los pickers
    let taskTypes = ["Revisión", "Actualización", "Limpieza", "Reparación", "Instalación"]
    let maintenanceTypes = ["Preventivo", "Correctivo"]
    let priorities = ["Alta", "Media", "Baja"]
    
    // Verificar si un punto ha sido seleccionado
    private var isPointSelected: Bool {
        return selectedPoint != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Sección 1: Selección de punto existente (ahora es la primera sección)
                Section(header: Text("Punto a mantener").foregroundColor(.primary).fontWeight(.bold)) {
                    Button(action: {
                        // Cargar proyectos antes de mostrar el selector
                        showingPointSelector = true
                    }) {
                        HStack {
                            if let point = selectedPoint, let project = selectedProject {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.name)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    
                                    Text("\(project.name) • \(point.type.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(point.city)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Seleccionar punto de proyecto")
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if selectedPoint != nil {
                        Button(action: {
                            selectedProject = nil
                            selectedPoint = nil
                            // Limpiar campos asociados
                            location = ""
                            siteName = ""
                        }) {
                            Text("Eliminar selección")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Sección 2: Información básica (campos obligatorios)
                Section(header: Text("Información básica (obligatorio)").foregroundColor(.primary).fontWeight(.bold)) {                    
                    Picker("Tipo de tarea", selection: $taskType) {
                        ForEach(taskTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Picker("Tipo de mantenimiento", selection: $maintenanceType) {
                        ForEach(maintenanceTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Picker("Prioridad", selection: $priority) {
                        ForEach(priorities, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    DatePicker("Fecha programada", selection: $scheduledDate, displayedComponents: .date)
                }
                
                // Sección 3: Información de ubicación (ahora es de solo lectura si hay un punto seleccionado)
                if isPointSelected {
                    Section(header: Text("Ubicación")) {
                        HStack {
                            Text("Localidad")
                            Spacer()
                            Text(location)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Nombre del sitio")
                            Spacer()
                            Text(siteName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Nueva tarea")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveTask()
                    }
                    .disabled(!isPointSelected)
                }
            }
            .sheet(isPresented: $showingPointSelector) {
                ProjectPointSelectorView(
                    isPresented: $showingPointSelector,
                    selectedProject: $selectedProject,
                    selectedPoint: $selectedPoint
                )
            }
            // Aquí se agregaría el ImagePicker en una implementación real
        }
        .onAppear {
            // Si hay un punto seleccionado, rellenar automáticamente algunos campos
            if let point = selectedPoint {
                location = point.city
                siteName = point.location.address ?? "Sitio \(point.name)"
            }
            Task {
                // Verificar si los proyectos ya están cargados
                if projectManager.projects.isEmpty {
                    await projectViewModel.refreshProjects()
                    // Sincronizar los proyectos al ProjectManager
                    projectManager.projects = projectViewModel.projects
                }
            }
        }
        .onChange(of: selectedPoint) { _, newPoint in
            if let point = newPoint {
                location = point.city
                siteName = point.location.address ?? "Sitio \(point.name)"
            }
        }
    }
    
    private func saveTask() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        var additionalData: [String: Any] = [:]
        
        // Agregar información del punto y proyecto seleccionado si existe
        if let project = selectedProject, let point = selectedPoint {
            additionalData["projectId"] = project.id
            additionalData["projectName"] = project.name
            additionalData["pointId"] = point.id
            additionalData["pointType"] = point.type.rawValue
            additionalData["pointCoordinates"] = [point.location.latitude, point.location.longitude]
        }
        
        // Usar el nombre del punto como nombre del dispositivo
        let deviceName = selectedPoint?.name ?? ""
        
        // Crear la tarea con solo los campos obligatorios
        let newTask = MaintenanceTask(
            id: UUID().uuidString,
            deviceName: deviceName,
            taskType: taskType,
            maintenanceType: maintenanceType,
            description: "", // Campo vacío que completará el técnico
            status: "Pendiente",
            scheduledDate: dateFormatter.string(from: scheduledDate),
            completedDate: nil,
            assignedTo: "", // Campo vacío que completará el técnico
            priority: priority,
            location: location,
            siteName: siteName,
            additionalData: additionalData
        )
        
        onSave(newTask)
        isPresented = false
    }
}

// Vista para seleccionar proyectos y puntos
struct ProjectPointSelectorView: View {
    @Binding var isPresented: Bool
    @Binding var selectedProject: Project?
    @Binding var selectedPoint: ProjectPoint?
    
    @ObservedObject private var projectManager = ProjectManager.shared
    @ObservedObject private var projectViewModel = ProjectViewModel()
    @State private var searchText = ""
    @State private var selectedProjectId: String? = nil
    @State private var isLoading = true // Estado para control de carga
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projectManager.projects
        } else {
            return projectManager.projects.filter { project in
                project.name.lowercased().contains(searchText.lowercased()) ||
                project.client.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var pointsForSelectedProject: [ProjectPoint] {
        guard let projectId = selectedProjectId else { return [] }
        return projectManager.getProjectPoints(projectId: projectId)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Barra de búsqueda para proyectos
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Buscar proyecto", text: $searchText)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                if isLoading {
                    // Mostrar indicador de carga
                    Spacer()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.bottom, 10)
                        
                        Text("Cargando proyectos...")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Por favor espere mientras se obtienen los datos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal, 20)
                    Spacer()
                } else if projectManager.projects.isEmpty {
                    // Mostrar mensaje cuando no hay proyectos
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No se encontraron proyectos")
                            .font(.headline)
                        Button(action: {
                            loadProjects()
                        }) {
                            Text("Reintentar")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 10)
                    }
                    Spacer()
                } else {
                    // Lista de proyectos y puntos
                    if selectedProjectId == nil {
                        // Lista de proyectos
                        List {
                            Text("Seleccione un proyecto:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .listRowBackground(Color.clear)
                                .padding(.bottom, 5)
                            
                            ForEach(filteredProjects) { project in
                                Button(action: {
                                    selectedProjectId = project.id
                                    print("🔍 Seleccionado proyecto: \(project.name) (ID: \(project.id))")
                                    // Indicar que estamos cargando puntos
                                    isLoading = true
                                    
                                    // Cargar puntos del proyecto
                                    Task {
                                        print("📍 Cargando puntos para el proyecto \(project.id)")
                                        projectManager.loadProjectPoints(projectId: project.id)
                                        
                                        // Esperar un breve momento para que los puntos se carguen
                                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
                                        
                                        DispatchQueue.main.async {
                                            // Verificar si los puntos se cargaron
                                            let points = projectManager.getProjectPoints(projectId: project.id)
                                            print("📊 Puntos cargados: \(points.count)")
                                            isLoading = false
                                        }
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(project.name)
                                                .font(.headline)
                                            
                                            Text(project.client)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.vertical, 5)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .listStyle(PlainListStyle())
                    } else {
                        // Lista de puntos del proyecto seleccionado
                        VStack {
                            // Cabecera con nombre del proyecto
                            if let projectId = selectedProjectId, let project = projectManager.projects.first(where: { $0.id == projectId }) {
                                HStack {
                                    Button(action: {
                                        selectedProjectId = nil
                                    }) {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Text("Proyectos")
                                        }
                                        .foregroundColor(.blue)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                Text(project.name)
                                    .font(.headline)
                                    .padding(.vertical, 8)
                            }
                            
                            if pointsForSelectedProject.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "mappin.slash")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    
                                    Text("No hay puntos en este proyecto")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                            } else {
                                List {
                                    Text("Seleccione un punto:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .listRowBackground(Color.clear)
                                        .padding(.bottom, 5)
                                    
                                    ForEach(pointsForSelectedProject) { point in
                                        Button(action: {
                                            if let projectId = selectedProjectId, let project = projectManager.projects.first(where: { $0.id == projectId }) {
                                                selectedProject = project
                                                selectedPoint = point
                                                isPresented = false
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: point.type.icon)
                                                    .foregroundColor(point.type.color)
                                                    .frame(width: 30)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(point.name)
                                                        .font(.headline)
                                                    
                                                    HStack {
                                                        Text(point.type.rawValue)
                                                            .font(.caption)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(point.type.color.opacity(0.2))
                                                            .cornerRadius(4)
                                                        
                                                        Text(point.city)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                // Si este punto está seleccionado, mostrar un checkmark
                                                if selectedPoint?.id == point.id {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .contentShape(Rectangle())
                                            .padding(.vertical, 5)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .listStyle(PlainListStyle())
                            }
                        }
                    }
                }
            }
            .navigationTitle(selectedProjectId == nil ? "Seleccionar Proyecto" : "Seleccionar Punto")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Recargar") {
                        loadProjects()
                    }
                }
            }
            .onAppear {
                print("👋 Vista ProjectPointSelectorView apareció")
                // Forzar una carga de proyectos cada vez que aparece la vista
                loadProjects()
            }
        }
    }
    
    private func loadProjects() {
        isLoading = true
        print("🔄 Iniciando carga de proyectos en ProjectPointSelectorView")
        
        Task {
            print("⏳ Ejecutando refreshProjects...")
            await projectViewModel.refreshProjects()
            
            DispatchQueue.main.async {
                print("📋 Proyectos obtenidos: \(self.projectViewModel.projects.count)")
                
                // Verificamos que se hayan cargado proyectos
                if !self.projectViewModel.projects.isEmpty {
                    // Sincronizar los proyectos al ProjectManager
                    self.projectManager.projects = self.projectViewModel.projects
                    print("✅ Proyectos sincronizados con ProjectManager: \(self.projectManager.projects.count)")
                } else {
                    print("⚠️ No se obtuvieron proyectos del servidor")
                }
                
                // Desactivar el estado de carga
                self.isLoading = false
                print("🏁 Carga de proyectos finalizada")
            }
        }
    }
}

// Vista para filtros avanzados
struct AdvancedFilterView: View {
    @Binding var selectedEquipmentFilter: String
    let equipmentTypes: [String]
    @Binding var dateRangeStart: Date?
    @Binding var dateRangeEnd: Date?
    @Binding var isPresented: Bool
    
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()
    @State private var useStartDate = false
    @State private var useEndDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tipo de Equipo")) {
                    Picker("Tipo de Equipo", selection: $selectedEquipmentFilter) {
                        ForEach(equipmentTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                Section(header: Text("Rango de Fechas")) {
                    Toggle("Filtrar por fecha inicial", isOn: $useStartDate)
                    
                    if useStartDate {
                        DatePicker("Desde", selection: $tempStartDate, displayedComponents: .date)
                    }
                    
                    Toggle("Filtrar por fecha final", isOn: $useEndDate)
                    
                    if useEndDate {
                        DatePicker("Hasta", selection: $tempEndDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filtros Avanzados")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    isPresented = false
                },
                trailing: Button("Aplicar") {
                    // Aplicar los filtros
                    dateRangeStart = useStartDate ? tempStartDate : nil
                    dateRangeEnd = useEndDate ? tempEndDate : nil
                    isPresented = false
                }
            )
            .onAppear {
                // Inicializar fechas temporales
                if let start = dateRangeStart {
                    tempStartDate = start
                    useStartDate = true
                }
                
                if let end = dateRangeEnd {
                    tempEndDate = end
                    useEndDate = true
                }
            }
        }
    }
}

struct MaintenanceFormView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceFormView(isPresented: .constant(true), onSave: { _ in })
    }
} 