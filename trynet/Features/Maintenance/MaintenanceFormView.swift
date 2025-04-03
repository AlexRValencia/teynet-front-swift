import SwiftUI
import PhotosUI
// Importaciones necesarias
import Foundation
// Comentamos la importación problemática
// import trynet.Features.Maintenance.MaintenanceTask

struct MaintenanceFormView: View {
    @Binding var isPresented: Bool
    var onSave: (MaintenanceTask) -> Void
    
    // Datos básicos
    @State private var deviceName = ""
    @State private var taskType = "Revisión"
    @State private var maintenanceType = "Preventivo"
    @State private var description = ""
    @State private var scheduledDate = Date()
    @State private var assignedTo = ""
    @State private var priority = "Media"
    @State private var location = "Torreón"
    @State private var siteName = ""
    
    // Selección de punto existente
    @State private var showingPointSelector = false
    @State private var selectedProject: Project? = nil
    @State private var selectedPoint: ProjectPoint? = nil
    @ObservedObject private var projectViewModel = ProjectViewModel()
    @ObservedObject private var projectManager = ProjectManager.shared
    
    // Datos adicionales de equipamiento
    @State private var showingEquipmentDetailsSheet = false
    @State private var damagedEquipment: [String] = []
    @State private var tempDamagedEquipment = ""
    @State private var cableInstalled: [String: String] = [:]
    @State private var tempCableType = "UTP"
    @State private var tempCableLength = ""
    
    // Colecciones para los pickers
    let taskTypes = ["Revisión", "Actualización", "Limpieza", "Reparación", "Instalación"]
    let maintenanceTypes = ["Preventivo", "Correctivo"]
    let priorities = ["Alta", "Media", "Baja"]
    let locationOptions = ["Acuña", "Piedras Negras", "Monclova", "Torreón", "Saltillo"]
    let cableTypes = ["UTP", "Eléctrico", "Fibra", "Coaxial", "HDMI"]
    
    // Placeholder para imágenes (en la versión real se usaría UIImagePicker)
    @State private var initialPhotos: [UIImage] = []
    @State private var finalPhotos: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var isCapturingInitialPhoto = true
    
    var body: some View {
        NavigationStack {
            Form {
                // Sección 1: Información básica
                Section(header: Text("Información básica")) {
                    TextField("Nombre del dispositivo", text: $deviceName)
                    
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
                }
                
                // Sección 2: Selección de punto existente
                Section(header: Text("Punto de Proyecto")) {
                    Button(action: {
                        // Cargar proyectos antes de mostrar el selector
                        showingPointSelector = true
                    }) {
                        HStack {
                            if let point = selectedPoint, let project = selectedProject {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.name)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(project.name) • \(point.type.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(point.city)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Seleccionar punto existente")
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
                        }) {
                            Text("Eliminar selección")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Sección 3: Ubicación
                Section(header: Text("Ubicación")) {
                    Picker("Localidad", selection: $location) {
                        ForEach(locationOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    TextField("Nombre del sitio", text: $siteName)
                        .autocapitalization(.words)
                }
                
                // Sección 4: Detalles y asignación
                Section(header: Text("Detalles")) {
                    DatePicker("Fecha programada", selection: $scheduledDate, displayedComponents: .date)
                    
                    TextField("Asignado a", text: $assignedTo)
                        .autocapitalization(.words)
                    
                    VStack(alignment: .leading) {
                        Text("Descripción")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Sección 5: Equipo dañado
                Section(header: Text("Equipo dañado")) {
                    ForEach(damagedEquipment, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                            Button(action: {
                                if let index = damagedEquipment.firstIndex(of: item) {
                                    damagedEquipment.remove(at: index)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Agregar equipo dañado", text: $tempDamagedEquipment)
                        
                        Button(action: {
                            if !tempDamagedEquipment.isEmpty {
                                damagedEquipment.append(tempDamagedEquipment)
                                tempDamagedEquipment = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Sección 6: Cables instalados
                Section(header: Text("Cable instalado (metros)")) {
                    ForEach(Array(cableInstalled.keys.sorted()), id: \.self) { key in
                        if let value = cableInstalled[key], !value.isEmpty {
                            HStack {
                                Text(key)
                                Spacer()
                                Text("\(value) MTS")
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    cableInstalled.removeValue(forKey: key)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Picker("Tipo", selection: $tempCableType) {
                            ForEach(cableTypes, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                        
                        TextField("Metros", text: $tempCableLength)
                            .keyboardType(.numberPad)
                        
                        Button(action: {
                            if !tempCableLength.isEmpty {
                                cableInstalled[tempCableType] = tempCableLength
                                tempCableLength = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Sección 7: Fotos (simuladas en esta implementación)
                Section(header: Text("Fotografías")) {
                    Button(action: {
                        isCapturingInitialPhoto = true
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Capturar foto inicial")
                        }
                    }
                    
                    Button(action: {
                        isCapturingInitialPhoto = false
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Capturar foto final")
                        }
                    }
                    
                    // Mostrar miniaturas simuladas
                    if !initialPhotos.isEmpty {
                        Text("Fotos iniciales: \(initialPhotos.count)")
                            .font(.caption)
                    }
                    
                    if !finalPhotos.isEmpty {
                        Text("Fotos finales: \(finalPhotos.count)")
                            .font(.caption)
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
                    .disabled(deviceName.isEmpty || description.isEmpty || assignedTo.isEmpty || siteName.isEmpty)
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
                deviceName = point.name
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
        
        // Agregar equipamiento dañado
        if !damagedEquipment.isEmpty {
            additionalData["damagedEquipment"] = damagedEquipment
        }
        
        // Agregar cables instalados
        if !cableInstalled.isEmpty {
            additionalData["cableInstalled"] = cableInstalled
        }
        
        // Agregar fotos
        if !initialPhotos.isEmpty {
            additionalData["initialPhotos"] = initialPhotos
        }
        
        if !finalPhotos.isEmpty {
            additionalData["finalPhotos"] = finalPhotos
        }
        
        let newTask = MaintenanceTask(
            id: UUID().uuidString,
            deviceName: deviceName,
            taskType: taskType,
            maintenanceType: maintenanceType,
            description: description,
            status: "Pendiente",
            scheduledDate: dateFormatter.string(from: scheduledDate),
            completedDate: nil,
            assignedTo: assignedTo,
            priority: priority,
            location: location,
            siteName: siteName,
            additionalData: additionalData
        )
        
        onSave(newTask)
        isPresented = false
    }
    
    // Método simulado para agregar fotos (en la versión real usaría UIImagePickerController)
    private func didSelectImage(_ image: UIImage) {
        if isCapturingInitialPhoto {
            initialPhotos.append(image)
        } else {
            finalPhotos.append(image)
        }
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
                    ProgressView("Cargando proyectos...")
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
                                    projectManager.loadProjectPoints(projectId: project.id)
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
                loadProjects()
            }
        }
    }
    
    private func loadProjects() {
        isLoading = true
        Task {
            // Verificar si los proyectos ya están cargados
            await projectViewModel.refreshProjects()
            // Sincronizar los proyectos al ProjectManager
            projectManager.projects = projectViewModel.projects
            isLoading = false
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