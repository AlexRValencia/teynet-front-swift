import SwiftUI
import PhotosUI

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
                .onChange(of: selectedPhoto) {
                    if let newItem = selectedPhoto {
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
            MaintenanceDetailRow(label: "Ubicación", value: "\(task.location) - \(task.siteName)")
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
        VStack(alignment: .leading, spacing: 15) {
            Text("Etapas del mantenimiento")
                .font(.headline)
            
            ForEach(task.stages, id: \.id) { stage in
                StageRow(stage: stage, task: task) {
                    if stage.isCompleted {
                        // Si ya hay una foto, mostrarla en grande
                        if let stageIndex = task.stages.firstIndex(where: { $0.id == stage.id }),
                           let photo = task.stagePhotos[stageIndex] {
                            selectedImageForZoom = photo
                            isImageZoomed = true
                        }
                    } else {
                        // Si no tiene foto, permitir agregar una
                        selectedStage = stage
                        isShowingPhotosPicker = true
                    }
                }
            }
        }
    }
    
    private func equipmentAndCablesSection(_ additionalData: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            if let damagedEquipment = additionalData["damagedEquipment"] as? [String] {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Equipos dañados")
                        .font(.headline)
                    
                    ForEach(damagedEquipment, id: \.self) { equipment in
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(equipment)
                                .font(.body)
                        }
                    }
                }
                .padding(.bottom, 10)
            }
            
            if let cableInstalled = additionalData["cableInstalled"] as? [String: String] {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cables instalados")
                        .font(.headline)
                    
                    ForEach(cableInstalled.sorted(by: { $0.key < $1.key }), id: \.key) { cableType, amount in
                        HStack {
                            Image(systemName: "cable.connector")
                                .foregroundColor(.blue)
                            Text("\(cableType): \(amount) metros")
                                .font(.body)
                        }
                    }
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        HStack {
            if task.status != "Finalizado" {
                Button {
                    showSupportSheet = true
                } label: {
                    HStack {
                        Image(systemName: "person.fill.questionmark")
                        Text("Solicitar apoyo")
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(task.supportRequested)
            }
            
            Button {
                generatePDF()
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Generar PDF")
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isGeneratingPDF)
        }
    }
    
    private var supportRequestView: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del problema")) {
                    TextView(text: $supportRequestDetails, placeholder: "Describa el problema o la razón por la que necesita apoyo...")
                        .frame(minHeight: 150)
                }
                
                Section {
                    Button("Enviar solicitud") {
                        if !supportRequestDetails.isEmpty {
                            maintenanceManager.requestSupport(taskId: task.id, details: supportRequestDetails)
                            showSupportSheet = false
                        }
                    }
                    .disabled(supportRequestDetails.isEmpty)
                }
            }
            .navigationTitle("Solicitar Apoyo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showSupportSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Funciones
    
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
    
    private func completeStage(_ stage: MaintenanceStage, with image: UIImage) {
        maintenanceManager.completeStage(taskId: task.id, stageName: stage.name, photo: image)
        self.selectedStage = nil
        self.isShowingPhotosPicker = false
    }
}

// MARK: - Vistas auxiliares

struct MaintenanceDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 140, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct TaskStatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
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

struct StageRow: View {
    let stage: MaintenanceStage
    let task: MaintenanceTask
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(stage.name)
                    .font(.headline)
                
                Text(stage.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(stage.percentageValue * 100))% del proceso")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Si la etapa está completada, mostrar thumbnail de la foto
            if stage.isCompleted, 
               let stageIndex = task.stages.firstIndex(where: { $0.id == stage.id }),
               let photo = task.stagePhotos[stageIndex] {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            } else {
                // Si no está completada, mostrar botón para completar
                Button(action: onTap) {
                    Image(systemName: stage.isCompleted ? "checkmark.circle.fill" : "camera.fill")
                        .font(.title2)
                        .foregroundColor(stage.isCompleted ? .green : .blue)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(stage.isCompleted ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(stage.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.text = placeholder
        textView.textColor = UIColor.placeholderText
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if text.isEmpty && !uiView.isFirstResponder {
            uiView.text = placeholder
            uiView.textColor = UIColor.placeholderText
        } else if uiView.text == placeholder && !text.isEmpty {
            uiView.text = text
            uiView.textColor = UIColor.label
        } else if uiView.text != text && !uiView.isFirstResponder {
            uiView.text = text
            uiView.textColor = UIColor.label
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextView
        
        init(_ parent: TextView) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.text == parent.placeholder {
                textView.text = ""
                textView.textColor = UIColor.label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor.placeholderText
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ZoomedImageView: View {
    let image: UIImage
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
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
                .onTapGesture(count: 2) {
                    if scale > 1.0 {
                        scale = 1.0
                    } else {
                        scale = 2.0
                    }
                }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isShowing = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Vista previa
struct MaintenanceTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = MaintenanceManager()
        let sampleTask = manager.tasks.first!
        
        return NavigationView {
            MaintenanceTaskDetailView(maintenanceManager: manager, task: sampleTask)
        }
    }
} 