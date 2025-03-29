import SwiftUI
import Charts

struct MaintenanceDashboardView: View {
    @ObservedObject var maintenanceManager: MaintenanceManager
    
    // Estado para filtros
    @State private var timeRange = "Mensual"
    @State private var selectedLocation = "Todas"
    
    // Opciones para los filtros
    let timeRangeOptions = ["Semanal", "Mensual", "Trimestral", "Anual"]
    let locationOptions = ["Todas", "Acuña", "Torreón", "Piedras Negras", "Monclova", "Saltillo"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filtros
                filtersSection
                
                // Tarjetas de estadísticas principales
                mainStatisticsSection
                
                // Gráfico de tareas por estado
                tasksByStatusChart
                
                // Gráfico de tareas por tipo
                tasksByTypeChart
                
                // Solicitudes de soporte pendientes
                pendingSupportRequestsSection
            }
            .padding()
        }
        .navigationTitle("Panel de Control")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Secciones de la UI
    
    private var filtersSection: some View {
        HStack {
            Picker("Período", selection: $timeRange) {
                ForEach(timeRangeOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
            
            Picker("Ubicación", selection: $selectedLocation) {
                ForEach(locationOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var mainStatisticsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Tarjetas de estadísticas
            DashboardCard(
                title: "Tareas Totales",
                value: "\(maintenanceManager.tasks.count)",
                icon: "checklist",
                color: .blue
            )
            
            DashboardCard(
                title: "Completadas",
                value: "\(maintenanceManager.tasks.filter { $0.status == "Finalizado" }.count)",
                icon: "checkmark.circle",
                color: .green
            )
            
            DashboardCard(
                title: "Pendientes",
                value: "\(maintenanceManager.tasks.filter { $0.status == "Pendiente" }.count)",
                icon: "clock",
                color: .orange
            )
            
            DashboardCard(
                title: "Solicitudes de Apoyo",
                value: "\(maintenanceManager.supportRequests.count)",
                icon: "person.fill.questionmark",
                color: .red
            )
        }
    }
    
    private var tasksByStatusChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tareas por Estado")
                .font(.headline)
            
            let pendingCount = maintenanceManager.tasks.filter { $0.status == "Pendiente" }.count
            let inProgressCount = maintenanceManager.tasks.filter { $0.status == "En desarrollo" }.count
            let completedCount = maintenanceManager.tasks.filter { $0.status == "Finalizado" }.count
            
            let data: [(String, Int, Color)] = [
                ("Pendiente", pendingCount, .yellow),
                ("En desarrollo", inProgressCount, .blue),
                ("Finalizado", completedCount, .green)
            ]
            
            Chart {
                ForEach(data, id: \.0) { item in
                    BarMark(
                        x: .value("Estado", item.0),
                        y: .value("Cantidad", item.1)
                    )
                    .foregroundStyle(item.2)
                    .annotation(position: .top) {
                        Text("\(item.1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var tasksByTypeChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tareas por Tipo")
                .font(.headline)
            
            let preventivoCount = maintenanceManager.tasks.filter { $0.maintenanceType == "Preventivo" }.count
            let correctivoCount = maintenanceManager.tasks.filter { $0.maintenanceType == "Correctivo" }.count
            
            let data = [
                ("Preventivo", Double(preventivoCount)),
                ("Correctivo", Double(correctivoCount))
            ]
            
            Chart {
                ForEach(data, id: \.0) { item in
                    SectorMark(
                        angle: .value("Tipo", item.1),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("Tipo", item.0))
                    .annotation(position: .overlay) {
                        Text("\(Int(item.1))")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
            }
            .chartForegroundStyleScale([
                "Preventivo": Color.blue,
                "Correctivo": Color.orange
            ])
            .frame(height: 200)
            
            // Leyenda manual
            HStack(spacing: 20) {
                ForEach(data, id: \.0) { item in
                    HStack {
                        Circle()
                            .fill(item.0 == "Preventivo" ? Color.blue : Color.orange)
                            .frame(width: 12, height: 12)
                        Text(item.0)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("(\(Int(item.1)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var pendingSupportRequestsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Solicitudes de Apoyo Pendientes")
                .font(.headline)
            
            if maintenanceManager.supportRequests.filter({ $0.status == "Pendiente" }).isEmpty {
                HStack {
                    Spacer()
                    Text("No hay solicitudes pendientes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            } else {
                ForEach(maintenanceManager.supportRequests.filter { $0.status == "Pendiente" }) { request in
                    NavigationLink(destination: SupportRequestDetailView(request: request, maintenanceManager: maintenanceManager)) {
                        SupportRequestRow(request: request)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Vistas auxiliares

struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SupportRequestRow: View {
    let request: SupportRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.fill.questionmark")
                    .foregroundColor(.orange)
                    .font(.headline)
                
                Text(request.deviceName)
                    .font(.headline)
                
                Spacer()
                
                Text(request.formattedRequestDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(request.details)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text("\(request.location) - \(request.siteName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(request.status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct SupportRequestDetailView: View {
    let request: SupportRequest
    @ObservedObject var maintenanceManager: MaintenanceManager
    
    @State private var responseDetails = ""
    @State private var showingUpdateSheet = false
    
    var relatedTask: MaintenanceTask? {
        maintenanceManager.tasks.first { $0.id == request.taskId }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Información de la solicitud
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Solicitud de Apoyo")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(request.formattedRequestDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    MaintenanceDashboardDetailRow(label: "Dispositivo", value: request.deviceName)
                    MaintenanceDashboardDetailRow(label: "Ubicación", value: "\(request.location) - \(request.siteName)")
                    MaintenanceDashboardDetailRow(label: "Estado", value: request.status)
                    
                    Text("Detalles del problema:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(request.details)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Detalles de la tarea relacionada
                if let task = relatedTask {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Tarea Relacionada")
                                .font(.headline)
                            
                            Spacer()
                            
                            NavigationLink(destination: MaintenanceTaskDetailView(maintenanceManager: maintenanceManager, task: task)) {
                                Text("Ver tarea")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Divider()
                        
                        MaintenanceDashboardDetailRow(label: "ID de tarea", value: task.id)
                        MaintenanceDashboardDetailRow(label: "Estado", value: task.status)
                        MaintenanceDashboardDetailRow(label: "Progreso", value: "\(Int(task.progress * 100))%")
                        MaintenanceDashboardDetailRow(label: "Asignado a", value: task.assignedTo)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                
                // Botón para actualizar el estado
                if request.status == "Pendiente" {
                    Button(action: {
                        showingUpdateSheet = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Actualizar Estado")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Detalle de Solicitud")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingUpdateSheet) {
            UpdateSupportRequestView(request: request, maintenanceManager: maintenanceManager, isPresented: $showingUpdateSheet)
        }
    }
}

struct UpdateSupportRequestView: View {
    let request: SupportRequest
    @ObservedObject var maintenanceManager: MaintenanceManager
    @Binding var isPresented: Bool
    
    @State private var selectedStatus = "En desarrollo"
    @State private var responseDetails = ""
    
    let statusOptions = ["En desarrollo", "Finalizado"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Actualizar estado")) {
                    Picker("Estado", selection: $selectedStatus) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Detalles de la respuesta")) {
                    TextView(text: $responseDetails, placeholder: "Proporcione detalles de la respuesta...")
                        .frame(minHeight: 150)
                }
                
                Section {
                    Button("Guardar cambios") {
                        // Aquí se actualizaría el estado de la solicitud
                        // En una app real, esto se guardaría en una base de datos
                        isPresented = false
                    }
                    .disabled(responseDetails.isEmpty)
                }
            }
            .navigationTitle("Actualizar Solicitud")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Vista previa
struct MaintenanceDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MaintenanceDashboardView(maintenanceManager: MaintenanceManager())
        }
    }
}

// Vista auxiliar para mostrar detalles en formato clave-valor
struct MaintenanceDashboardDetailRow: View {
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