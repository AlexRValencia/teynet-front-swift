import SwiftUI

struct MaterialDetailView: View {
    let material: ProjectMaterial
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var materialManager = ProjectMaterialManager.shared
    
    @State private var showingUseSheet = false
    @State private var showingReturnSheet = false
    @State private var showingReportSheet = false
    @State private var movements: [MaterialMovement] = []
    
    private var materialStatus: MaterialStatus {
        return MaterialStatus.fromUsage(assigned: material.assignedQuantity, used: material.usedQuantity)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Tarjeta de resumen
                    materialSummaryCard
                    
                    // Acciones disponibles
                    actionsSection
                    
                    // Historial de movimientos
                    movementsHistorySection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Detalle de Material")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cerrar") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingUseSheet) {
                UseMaterialView(material: material)
            }
            .sheet(isPresented: $showingReturnSheet) {
                ReturnMaterialView(material: material)
            }
            .sheet(isPresented: $showingReportSheet) {
                ReportMaterialIssueView(material: material)
            }
            .onAppear {
                loadMovements()
            }
        }
    }
    
    private var materialSummaryCard: some View {
        VStack(spacing: 16) {
            // Encabezado
            HStack {
                Text(material.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                MaterialStatusBadge(status: materialStatus)
            }
            
            Divider()
            
            // Detalles principales
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    DetailItem(icon: "tag", label: "Categoría", value: material.category)
                    DetailItem(icon: "number", label: "Cantidad Asignada", value: "\(material.assignedQuantity)")
                    DetailItem(icon: "hammer", label: "Cantidad Utilizada", value: "\(material.usedQuantity)")
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    DetailItem(icon: "calendar", label: "Fecha Asignación", value: dateFormatter.string(from: material.dateAssigned))
                    DetailItem(icon: "location", label: "Ubicación", value: material.location)
                    
                    if material.remainingQuantity > 0 {
                        DetailItem(icon: "shippingbox", label: "Disponible", value: "\(material.remainingQuantity)")
                    }
                }
            }
            
            // Barra de progreso
            VStack(alignment: .leading, spacing: 4) {
                Text("Progreso de uso")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                MaterialProgressBar(value: material.usagePercentage)
                    .frame(height: 8)
                
                HStack {
                    Text("0%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("100%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
            
            // Notas si existen
            if let notes = material.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notas:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acciones")
                .font(.headline)
            
            // Botones de acción
            HStack(spacing: 12) {
                ActionButton(
                    title: "Utilizar",
                    icon: "hammer",
                    color: .blue,
                    isEnabled: material.remainingQuantity > 0
                ) {
                    showingUseSheet = true
                }
                
                ActionButton(
                    title: "Devolver",
                    icon: "arrow.left.circle",
                    color: .green,
                    isEnabled: material.assignedQuantity > 0
                ) {
                    showingReturnSheet = true
                }
                
                ActionButton(
                    title: "Reportar",
                    icon: "exclamationmark.triangle",
                    color: .orange,
                    isEnabled: material.remainingQuantity > 0
                ) {
                    showingReportSheet = true
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var movementsHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historial de Movimientos")
                .font(.headline)
            
            if movements.isEmpty {
                Text("No hay movimientos registrados para este material")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(movements) { movement in
                    MovementHistoryRow(movement: movement)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func loadMovements() {
        movements = materialManager.getMovementsForMaterial(materialId: material.id)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

// Componente para mostrar un elemento de detalle
struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

// Componente para mostrar un badge de estado
struct MaterialStatusBadge: View {
    let status: MaterialStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.caption)
            
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(status.color).opacity(0.2))
        .foregroundColor(Color(status.color))
        .cornerRadius(8)
    }
}

// Componente para un botón de acción
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isEnabled ? color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isEnabled ? color : Color.gray)
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

// Componente para una fila en el historial de movimientos
struct MovementHistoryRow: View {
    let movement: MaterialMovement
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono del tipo de movimiento
            ZStack {
                Circle()
                    .fill(movementColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: movement.movementType.systemImage)
                    .foregroundColor(movementColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movement.movementType.rawValue)
                    .font(.headline)
                
                Text(dateTimeFormatter.string(from: movement.date))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("Cantidad: \(movement.quantity)")
                        .font(.subheadline)
                    
                    if let location = movement.location {
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                if let notes = movement.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var movementColor: Color {
        switch movement.movementType {
        case .assigned:
            return .blue
        case .used:
            return .green
        case .returned:
            return .purple
        case .damaged:
            return .orange
        case .lost:
            return .red
        case .transferred:
            return .gray
        }
    }
    
    private var dateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// Vista para registrar uso de material
struct UseMaterialView: View {
    let material: ProjectMaterial
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var materialManager = ProjectMaterialManager.shared
    
    @State private var quantity: String = "1"
    @State private var location: String = "Sitio de Obra"
    @State private var notes: String = ""
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Material")) {
                    Text(material.name)
                        .font(.headline)
                    
                    Text("Disponible: \(material.remainingQuantity)")
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("Detalles de Uso")) {
                    TextField("Cantidad a utilizar", text: $quantity)
                        .keyboardType(.numberPad)
                    
                    TextField("Ubicación", text: $location)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Registrar Uso")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Guardar") {
                    useTheMaterial()
                }
                .disabled(!isValidForm)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var isValidForm: Bool {
        guard let quantityValue = Int(quantity), 
              quantityValue > 0,
              !location.isEmpty else {
            return false
        }
        
        return quantityValue <= material.remainingQuantity
    }
    
    private func useTheMaterial() {
        guard let quantityValue = Int(quantity), quantityValue > 0 else {
            showAlert(title: "Error", message: "Por favor ingresa una cantidad válida")
            return
        }
        
        if quantityValue > material.remainingQuantity {
            showAlert(title: "Error", message: "No hay suficiente material disponible")
            return
        }
        
        let success = materialManager.useMaterial(
            materialId: material.id,
            quantity: quantityValue,
            location: location,
            notes: notes.isEmpty ? nil : notes
        )
        
        if success {
            presentationMode.wrappedValue.dismiss()
        } else {
            showAlert(title: "Error", message: materialManager.errorMessage ?? "No se pudo registrar el uso del material")
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// Vista para devoler material
struct ReturnMaterialView: View {
    let material: ProjectMaterial
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var materialManager = ProjectMaterialManager.shared
    
    @State private var quantity: String = "1"
    @State private var notes: String = ""
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Material")) {
                    Text(material.name)
                        .font(.headline)
                    
                    Text("Asignado: \(material.assignedQuantity)")
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("Detalles de Devolución")) {
                    TextField("Cantidad a devolver", text: $quantity)
                        .keyboardType(.numberPad)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Devolver Material")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Devolver") {
                    returnTheMaterial()
                }
                .disabled(!isValidForm)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var isValidForm: Bool {
        guard let quantityValue = Int(quantity), 
              quantityValue > 0 else {
            return false
        }
        
        return quantityValue <= material.assignedQuantity
    }
    
    private func returnTheMaterial() {
        guard let quantityValue = Int(quantity), quantityValue > 0 else {
            showAlert(title: "Error", message: "Por favor ingresa una cantidad válida")
            return
        }
        
        if quantityValue > material.assignedQuantity {
            showAlert(title: "Error", message: "No puedes devolver más de lo asignado")
            return
        }
        
        let success = materialManager.returnMaterial(
            materialId: material.id,
            quantity: quantityValue,
            notes: notes.isEmpty ? nil : notes
        )
        
        if success {
            presentationMode.wrappedValue.dismiss()
        } else {
            showAlert(title: "Error", message: materialManager.errorMessage ?? "No se pudo registrar la devolución del material")
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// Vista para reportar problemas con el material
struct ReportMaterialIssueView: View {
    let material: ProjectMaterial
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var materialManager = ProjectMaterialManager.shared
    
    @State private var quantity: String = "1"
    @State private var movementType: MaterialMovement.MovementType = .damaged
    @State private var location: String = "Sitio de Obra"
    @State private var notes: String = ""
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Material")) {
                    Text(material.name)
                        .font(.headline)
                    
                    Text("Disponible: \(material.remainingQuantity)")
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("Tipo de Problema")) {
                    Picker("Tipo", selection: $movementType) {
                        Text("Dañado").tag(MaterialMovement.MovementType.damaged)
                        Text("Perdido").tag(MaterialMovement.MovementType.lost)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Detalles del Reporte")) {
                    TextField("Cantidad afectada", text: $quantity)
                        .keyboardType(.numberPad)
                    
                    TextField("Ubicación", text: $location)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Reportar Problema")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Reportar") {
                    reportIssue()
                }
                .disabled(!isValidForm)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var isValidForm: Bool {
        guard let quantityValue = Int(quantity), 
              quantityValue > 0,
              !location.isEmpty,
              !notes.isEmpty else {
            return false
        }
        
        return quantityValue <= material.remainingQuantity
    }
    
    private func reportIssue() {
        guard let quantityValue = Int(quantity), quantityValue > 0 else {
            showAlert(title: "Error", message: "Por favor ingresa una cantidad válida")
            return
        }
        
        if quantityValue > material.remainingQuantity {
            showAlert(title: "Error", message: "No hay suficiente material disponible")
            return
        }
        
        if notes.isEmpty {
            showAlert(title: "Error", message: "Por favor proporciona detalles del problema")
            return
        }
        
        let success = materialManager.reportDamagedOrLost(
            materialId: material.id,
            quantity: quantityValue,
            movementType: movementType,
            location: location,
            notes: notes
        )
        
        if success {
            presentationMode.wrappedValue.dismiss()
        } else {
            showAlert(title: "Error", message: materialManager.errorMessage ?? "No se pudo registrar el problema")
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
} 