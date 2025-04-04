import SwiftUI
import PhotosUI
import MapKit

struct MaintenanceTaskDetailView: View {
    @ObservedObject var maintenanceManager: MaintenanceManager
    var task: MaintenanceTask
    var showEditFormOnAppear: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showingGeneratedPDF = false
    @State private var pdfURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showSupportSheet = false
    @State private var isImageZoomed = false
    @State private var selectedImageForZoom: UIImage? = nil
    @State private var supportRequest = ""
    @State private var selectedStage: MaintenanceStage? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var isShowingPhotosPicker = false
    @State private var isGeneratingPDF = false
    @State private var showingEditForm = false
    
    // Variables para la edición
    @State private var editDescription = ""
    @State private var editAssignedTo = ""
    @State private var editDamagedEquipment: [String] = []
    @State private var editCableInstalled: [String: String] = [:]
    @State private var tempDamagedEquipment = ""
    @State private var tempCableType = "UTP"
    @State private var tempCableLength = ""
    
    // Tipos de cable para el picker
    let cableTypes = ["UTP", "Eléctrico", "Fibra", "Coaxial", "HDMI"]
    
    // MARK: - Body del View
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cabecera con info del punto y proyecto
                projectPointHeader
                
                // Detalles de la tarea
                taskDetailsSection
                
                // Detalles del sitio
                siteDetailsSection
                
                // Progreso de la tarea
                progressSection
                
                // Etapas de mantenimiento
                stagesSection
                
                // Reportes y acciones
                if task.status == "Finalizado" {
                    reportSection
                } else {
                    actionsSection
                }
                
                // Añadir una sección que muestre un indicador de datos pendientes
                camposPendientesSection
            }
            .padding()
        }
        .navigationTitle(task.pointId != nil ? task.deviceName : "Tarea de mantenimiento")
        .navigationBarItems(trailing: HStack {
            if task.status != "Finalizado" {
                Button("Solicitar apoyo") {
                    showSupportSheet = true
                }
                .disabled(task.supportRequested)
            }
        })
        .sheet(isPresented: $isShowingPhotosPicker) {
            if let selectedStage = selectedStage {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Text("Seleccionar Foto")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .onChange(of: selectedPhoto) { _, newPhoto in
                    if let newItem = newPhoto {
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self.selectedUIImage = image
                                    // Usar la imagen seleccionada para completar la etapa
                                    completeStage(selectedStage, with: image)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSupportSheet) {
            supportRequestView
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingEditForm) {
            NavigationView {
                Form {
                    Section(header: Text("Información de la tarea")) {
                        VStack(alignment: .leading) {
                            Text("Descripción")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $editDescription)
                                .frame(minHeight: 100)
                                .padding(4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        TextField("Técnico asignado", text: $editAssignedTo)
                            .autocapitalization(.words)
                    }
                    
                    Section(header: Text("Equipo dañado")) {
                        ForEach(editDamagedEquipment, id: \.self) { item in
                            HStack {
                                Text(item)
                                Spacer()
                                Button(action: {
                                    if let index = editDamagedEquipment.firstIndex(of: item) {
                                        editDamagedEquipment.remove(at: index)
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
                                    editDamagedEquipment.append(tempDamagedEquipment)
                                    tempDamagedEquipment = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Section(header: Text("Cable instalado (metros)")) {
                        ForEach(Array(editCableInstalled.keys.sorted()), id: \.self) { key in
                            if let value = editCableInstalled[key], !value.isEmpty {
                                HStack {
                                    Text(key)
                                    Spacer()
                                    Text("\(value) MTS")
                                        .foregroundColor(.secondary)
                                    Button(action: {
                                        editCableInstalled.removeValue(forKey: key)
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
                                    editCableInstalled[tempCableType] = tempCableLength
                                    tempCableLength = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .navigationTitle("Editar Tarea")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancelar") {
                            showingEditForm = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Guardar") {
                            saveTaskChanges()
                        }
                    }
                }
            }
            .onAppear {
                // No necesitamos inicializar los campos aquí,
                // ya que ya lo hacemos en el onAppear de la vista principal
            }
        }
        .fullScreenCover(isPresented: $isImageZoomed) {
            if let image = selectedImageForZoom {
                ZoomedImageView(image: image, isShowing: $isImageZoomed)
            }
        }
        .overlay {
            if isGeneratingPDF {
                ProgressView("Generando PDF...")
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .onAppear {
            // Inicializar los campos con los valores actuales
            editDescription = task.description
            editAssignedTo = task.assignedTo
            editDamagedEquipment = task.damagedEquipment
            editCableInstalled = task.cableInstalledFormatted
            
            // Mostrar directamente el formulario de edición si se indica
            if showEditFormOnAppear {
                // Pequeño retraso para asegurar que la vista esté completamente cargada
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingEditForm = true
                }
            }
        }
    }
    
    // MARK: - Secciones de la UI
    
    // Cabecera con información del punto y proyecto
    private var projectPointHeader: some View {
        Group {
            if let projectName = task.projectName, let pointId = task.pointId {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        // Mapa de ubicación si tenemos coordenadas
                        if let coordinates = task.pointCoordinates, coordinates.count == 2 {
                            MapSnapshotView(latitude: coordinates[0], longitude: coordinates[1], title: task.deviceName)
                                .frame(width: 120, height: 120)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.deviceName)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            if let pointType = task.pointType {
                                Text(pointType)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(projectName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text("\(task.location), \(task.siteName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            } else {
                // Visualización alternativa si no hay información de punto
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(task.deviceName)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        MaintenanceStatusBadge(status: task.status)
                    }
                    
                    Text("\(task.location), \(task.siteName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MaintenanceDetailRow(label: "Prioridad", value: task.priority)
            locationSection
            MaintenanceDetailRow(label: "Fecha programada", value: task.scheduledDate)
            
            if let completedDate = task.completedDate {
                MaintenanceDetailRow(label: "Fecha finalizado", value: completedDate)
            }
            
            MaintenanceDetailRow(label: "Asignado a", value: task.assignedTo)
            
            Text("Descripción:")
                .font(.headline)
                .padding(.top, 5)
            
            Text(task.description)
                .font(.body)
                .padding(.top, 2)
        }
    }
    
    private var locationSection: some View {
        Section(header: Text("Ubicación")) {
            MaintenanceLocationDetailRow(icon: "location.fill", title: "Localidad", value: task.location)
            MaintenanceLocationDetailRow(icon: "building.2.fill", title: "Sitio", value: task.siteName)
            
            if let projectName = task.projectName, let pointId = task.pointId {
                NavigationLink(destination: ProjectPointDetailView(projectId: task.projectId ?? "", pointId: pointId)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Punto vinculado")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            
                            VStack(alignment: .leading) {
                                Text(task.deviceName)
                                    .font(.subheadline)
                                
                                Text("Proyecto: \(projectName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if let coordinates = task.pointCoordinates, coordinates.count == 2 {
                MapSnapshotView(
                    latitude: coordinates[0],
                    longitude: coordinates[1],
                    title: task.siteName
                )
                .frame(height: 150)
                .cornerRadius(10)
                .padding(.vertical, 4)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progreso")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(task.progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            ProgressBar(value: task.progress)
                .frame(height: 20)
        }
    }
    
    private var stagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Etapas del mantenimiento")
                .font(.headline)
            
            ForEach(task.stages, id: \.id) { stage in
                StageRowView(
                    stage: stage,
                    isCompleted: stage.isCompleted,
                    onTap: {
                        if !stage.isCompleted {
                            selectedStage = stage
                            isShowingPhotosPicker = true
                        } else if !stage.photos.isEmpty, let photoData = stage.photos.first?.imageData, let image = UIImage(data: photoData) {
                            selectedImageForZoom = image
                            isImageZoomed = true
                        }
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private var reportSection: some View {
        // Implementa la sección de reporte
        Text("Sección de reporte")
    }
    
    private var actionsSection: some View {
        // Implementa la sección de acciones
        Text("Sección de acciones")
    }
    
    private var siteDetailsSection: some View {
        // Implementa la sección de detalles del sitio
        Text("Sección de detalles del sitio")
    }
    
    private var supportRequestView: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles de la solicitud")) {
                    TextEditor(text: $supportRequest)
                        .frame(minHeight: 150)
                }
                
                Section {
                    Button(action: {
                        if !supportRequest.isEmpty {
                            // Enviar solicitud de apoyo
                            maintenanceManager.requestSupport(taskId: task.id, details: supportRequest)
                            showSupportSheet = false
                        }
                    }) {
                        Text("Enviar Solicitud")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding()
                            .background(supportRequest.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(supportRequest.isEmpty)
                    .listRowInsets(EdgeInsets())
                    .padding()
                }
            }
            .navigationTitle("Solicitar Apoyo")
            .navigationBarItems(trailing: Button("Cancelar") {
                showSupportSheet = false
            })
        }
    }
    
    // Añadir una sección que muestre un indicador de datos pendientes
    var camposPendientesSection: some View {
        Section(header: Text("Información pendiente").foregroundColor(.orange)) {
            if task.description.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Descripción pendiente")
                        .foregroundColor(.secondary)
                }
            }
            
            if task.damagedEquipment.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Equipo dañado pendiente")
                        .foregroundColor(.secondary)
                }
            }
            
            if task.cableInstalledFormatted.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Cable instalado pendiente")
                        .foregroundColor(.secondary)
                }
            }
            
            if task.assignedTo.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Técnico asignado pendiente")
                        .foregroundColor(.secondary)
                }
            }
            
            if !camposPendientes.isEmpty {
                Button(action: {
                    showingEditForm = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Completar información pendiente")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    // Propiedad computada para verificar si hay campos pendientes
    var camposPendientes: [String] {
        var pendientes: [String] = []
        
        if task.description.isEmpty {
            pendientes.append("Descripción")
        }
        
        if task.damagedEquipment.isEmpty {
            pendientes.append("Equipo dañado")
        }
        
        if task.cableInstalledFormatted.isEmpty {
            pendientes.append("Cable instalado")
        }
        
        if task.assignedTo.isEmpty {
            pendientes.append("Técnico asignado")
        }
        
        return pendientes
    }
    
    // MARK: - Funciones
    
    private func completeStage(_ stage: MaintenanceStage, with image: UIImage) {
        maintenanceManager.completeStage(taskId: task.id, stageName: stage.name, photo: image)
        selectedStage = nil
        isShowingPhotosPicker = false
    }
    
    private func generatePDF() {
        isGeneratingPDF = true
        
        maintenanceManager.generatePDFReport(for: task) { url in
            isGeneratingPDF = false
            
            if let url = url {
                self.pdfURL = url
                self.showShareSheet = true
            }
        }
    }
    
    // Añadir esta función para guardar los cambios de la tarea
    private func saveTaskChanges() {
        // Crear una tarea actualizada usando el método updatedWithDetails
        let updatedTask = task.updatedWithDetails(
            description: editDescription,
            assignedTo: editAssignedTo,
            damagedEquipment: editDamagedEquipment,
            cableInstalled: editCableInstalled
        )
        
        // Guardar la tarea actualizada
        maintenanceManager.updateTask(updatedTask)
        
        // Cerrar el formulario
        showingEditForm = false
    }
}

// MARK: - Vistas auxiliares

struct MaintenanceDetailRow: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
        }
    }
}

struct TaskStatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(backgroundColor)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case "Finalizado":
            return .green
        case "En desarrollo":
            return .blue
        case "Pendiente":
            return .orange
        default:
            return .gray
        }
    }
}

struct ProgressBar: View {
    var value: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Rectangle()
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(.blue)
                    .animation(.linear, value: value)
            }
            .cornerRadius(10)
        }
    }
}

struct StageRowView: View {
    let stage: MaintenanceStage
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stage.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(stage.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(stage.percentageValue * 100))%")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if isCompleted {
                        if !stage.photos.isEmpty {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    } else {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ZoomedImageView: View {
    let image: UIImage
    @Binding var isShowing: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isShowing = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
            }
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale *= delta
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            if scale > 1.0 {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                            }
                        }
                )
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No es necesario actualizar
    }
}

// MARK: - Vista previa
struct MaintenanceTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceTaskDetailView(
            maintenanceManager: MaintenanceManager(),
            task: MaintenanceTask.sampleTask()
        )
    }
}

// Componente auxiliar para mostrar un mapa estático
struct MapSnapshotView: View {
    let latitude: Double
    let longitude: Double
    let title: String
    @State private var cameraPosition: MapCameraPosition
    
    init(latitude: Double, longitude: Double, title: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        // Inicializar la posición de la cámara con un valor
        self._cameraPosition = State(initialValue: .camera(MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            distance: 6000, // 6km de distancia
            heading: 0,
            pitch: 0
        )))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition) {
                Marker(title, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    .tint(.red)
            }
            
            Text(String(format: "Lat: %.4f, Long: %.4f", latitude, longitude))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(6)
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(6)
                .padding(8)
        }
    }
}

// Vista para ver los detalles del punto vinculado
struct ProjectPointDetailView: View {
    let projectId: String
    let pointId: String
    @ObservedObject private var projectManager = ProjectManager.shared
    @ObservedObject private var projectViewModel = ProjectViewModel()
    @State private var point: ProjectPoint?
    @State private var project: Project?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando información del punto...")
                    .padding()
            } else if let point = point {
                ScrollView {
                    VStack(spacing: 20) {
                        // Mapa con la ubicación
                        MapSnapshotView(
                            latitude: point.location.latitude,
                            longitude: point.location.longitude,
                            title: point.name
                        )
                        .frame(height: 200)
                        .cornerRadius(10)
                        
                        // Información del punto
                        VStack(alignment: .leading, spacing: 15) {
                            // Cabecera
                            HStack {
                                Image(systemName: point.type.icon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(point.type.color)
                                    .cornerRadius(10)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    
                                    if let project = project {
                                        Text("Proyecto: \(project.name)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(point.type.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(point.type.color)
                                }
                            }
                            
                            Divider()
                            
                            // Detalles
                            MaintenanceLocationDetailRow(icon: "building.2", title: "Ciudad", value: point.city)
                            
                            if let address = point.location.address {
                                MaintenanceLocationDetailRow(icon: "mappin.circle", title: "Dirección", value: address)
                            }
                            
                            if let material = point.materialName {
                                MaintenanceLocationDetailRow(icon: "shippingbox", title: "Material", value: material)
                            }
                            
                            // Estado operativo
                            HStack(spacing: 8) {
                                Image(systemName: point.operationalStatus.icon)
                                    .foregroundColor(point.operationalStatus.color)
                                
                                Text("Estado: \(point.operationalStatus.rawValue)")
                                    .font(.subheadline)
                                    .foregroundColor(point.operationalStatus.color)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(point.operationalStatus.color.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    }
                    .padding()
                }
                .background(Color(.systemGray6).ignoresSafeArea())
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("No se pudo encontrar el punto")
                        .font(.headline)
                    
                    Text("El punto seleccionado podría no existir o haber sido eliminado.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .padding()
            }
        }
        .navigationTitle("Detalle del Punto")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPointData()
        }
    }
    
    private func loadPointData() {
        isLoading = true
        
        // Cargar datos del proyecto si es necesario
        if project == nil {
            if let loadedProject = projectManager.projects.first(where: { $0.id == projectId }) {
                project = loadedProject
            } else {
                // Intentar cargar todos los proyectos para encontrar el que buscamos
                Task {
                    await projectViewModel.refreshProjects()
                    // Sincronizar los proyectos al ProjectManager
                    projectManager.projects = projectViewModel.projects
                    if let loadedProject = projectManager.projects.first(where: { $0.id == projectId }) {
                        project = loadedProject
                    }
                }
            }
        }
        
        // Verificar si tenemos los puntos de este proyecto
        let projectPoints = projectManager.getProjectPoints(projectId: projectId)
        if projectPoints.isEmpty {
            // Cargar puntos del proyecto
            projectManager.loadProjectPoints(projectId: projectId)
            
            // Esperar un tiempo para que se carguen los puntos y luego buscar el punto específico
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.point = projectManager.getProjectPoints(projectId: projectId).first(where: { $0.id == pointId })
                self.isLoading = false
            }
        } else {
            // Si ya tenemos los puntos, buscar el punto específico
            point = projectPoints.first(where: { $0.id == pointId })
            isLoading = false
        }
    }
}

// Componente para mostrar una fila de detalle
struct MaintenanceLocationDetailRow: View {
    var icon: String
    var title: String
    var value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
} 