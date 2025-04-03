import SwiftUI
import PhotosUI
import MapKit

struct MaintenanceTaskDetailView: View {
    @ObservedObject var maintenanceManager: MaintenanceManager
    let task: MaintenanceTask
    
    @State private var isShowingPhotosPicker = false
    @State private var selectedStage: MaintenanceStage?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedUIImage: UIImage?
    @State private var showSupportSheet = false
    @State private var supportRequestDetails = ""
    @State private var isGeneratingPDF = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
    // Para la vista de fotos ampliadas
    @State private var selectedImageForZoom: UIImage?
    @State private var isImageZoomed = false
    
    @State private var showingDeleteConfirmation = false
    @State private var showingSupportRequestSheet = false
    @State private var supportDetails = ""
    @State private var showingCompleteTaskConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    
    // Verificar si la tarea tiene un punto de proyecto asignado
    var hasProjectPoint: Bool {
        return task.pointId != nil && task.pointCoordinates != nil
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cabecera
                headerSection
                
                Divider()
                
                // Información detallada
                detailSection
                
                Divider()
                
                // Barra de progreso
                progressSection
                
                Divider()
                
                // Etapas de mantenimiento
                stagesSection
                
                // Equipos dañados y cables instalados
                if !task.additionalData.isEmpty {
                    Divider()
                    
                    equipmentAndCablesSection(task.additionalData)
                }
                
                Divider()
                
                // Botones de acción
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle("Detalle de Tarea")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showSupportSheet = true
                    }) {
                        Label("Solicitar Apoyo", systemImage: "person.fill.questionmark")
                    }
                    .disabled(task.supportRequested)
                    
                    Button(action: {
                        generatePDF()
                    }) {
                        Label("Generar PDF", systemImage: "doc.text")
                    }
                    .disabled(isGeneratingPDF)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
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
    }
    
    // MARK: - Secciones de la UI
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.deviceName)
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                Text(task.taskType)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                
                Text(task.maintenanceType)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
                
                TaskStatusBadge(status: task.status)
            }
            
            if task.supportRequested {
                HStack {
                    Image(systemName: "person.fill.questionmark")
                        .foregroundColor(.orange)
                    Text("Soporte solicitado")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var detailSection: some View {
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
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fotografías")
                .font(.headline)
            
            // Mostrar fotos por etapas
            let completedStages = task.stages.filter { $0.isCompleted && !$0.photos.isEmpty }
            
            if completedStages.isEmpty {
                Text("No hay fotografías disponibles")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 5)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(completedStages, id: \.id) { stage in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Etapa: \(stage.name)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(stage.photos, id: \.id) { photo in
                                        if let photoData = photo.imageData, let image = UIImage(data: photoData) {
                                            Button(action: {
                                                selectedImageForZoom = image
                                                isImageZoomed = true
                                            }) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func equipmentAndCablesSection(_ data: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let damagedEquipment = data["damagedEquipment"] as? [String], !damagedEquipment.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Equipo dañado")
                        .font(.headline)
                    
                    ForEach(damagedEquipment, id: \.self) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                            Text(item)
                                .font(.body)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.vertical, 8)
            }
            
            if let cableInstalled = data["cableInstalled"] as? [String: String], !cableInstalled.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cable instalado")
                        .font(.headline)
                    
                    ForEach(Array(cableInstalled.keys.sorted()), id: \.self) { key in
                        if let value = cableInstalled[key], !value.isEmpty {
                            HStack {
                                Text(key)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("\(value) metros")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            // Botón para solicitar apoyo
            if !task.supportRequested {
                Button(action: {
                    showSupportSheet = true
                }) {
                    Label("Solicitar Apoyo", systemImage: "person.fill.questionmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                HStack {
                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.orange)
                    Text("Apoyo solicitado")
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Text("Pendiente")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Botón para generar PDF
            Button(action: {
                generatePDF()
            }) {
                Label("Generar Reporte PDF", systemImage: "doc.text")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isGeneratingPDF)
            
            if task.hasGeneratedReport, let reportURL = task.reportURL {
                Button(action: {
                    pdfURL = reportURL
                    showShareSheet = true
                }) {
                    Label("Compartir Reporte PDF", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var supportRequestView: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles de la solicitud")) {
                    TextEditor(text: $supportRequestDetails)
                        .frame(minHeight: 150)
                }
                
                Section {
                    Button(action: {
                        if !supportRequestDetails.isEmpty {
                            // Enviar solicitud de apoyo
                            maintenanceManager.requestSupport(taskId: task.id, details: supportRequestDetails)
                            showSupportSheet = false
                        }
                    }) {
                        Text("Enviar Solicitud")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding()
                            .background(supportRequestDetails.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(supportRequestDetails.isEmpty)
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
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        isShowing = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: .constant(MapCameraPosition.region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ))) {
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