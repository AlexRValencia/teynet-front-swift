import SwiftUI
import Charts

struct MaintenanceDashboardView: View {
    @ObservedObject var maintenanceManager: MaintenanceManager
    @Environment(\.isLandscape) private var isLandscape
    
    // Estados para filtros de tiempo
    @State private var timeFilter = "Este mes"
    private let timeFilterOptions = ["Esta semana", "Este mes", "Este año", "Todo"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filtro de tiempo en la parte superior
                timeFilterSegment
                
                // Tarjetas de KPI en la parte superior
                if isLandscape {
                    HStack(spacing: 16) {
                        ForEach(kpiData, id: \.title) { kpi in
                            KPICardView(data: kpi)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(kpiData, id: \.title) { kpi in
                                KPICardView(data: kpi)
                                    .frame(width: 160)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Gráfico de tareas por estado
                MaintenanceStatusChartView(data: statusData)
                    .frame(height: 250)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                
                // Gráfico de tareas por tipo de mantenimiento
                MaintenanceTypeChartView(data: typeData)
                    .frame(height: 250)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                
                // Últimas tareas de mantenimiento
                recentTasksSection
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                
                // Sección de solicitudes de apoyo
                if !maintenanceManager.supportRequests.isEmpty {
                    supportRequestsSection
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationTitle("Dashboard")
    }
    
    // Segmento para filtrar por tiempo
    private var timeFilterSegment: some View {
        Picker("Período", selection: $timeFilter) {
            ForEach(timeFilterOptions, id: \.self) { option in
                Text(option).tag(option)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    // Sección de tareas recientes
    private var recentTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tareas Recientes")
                .font(.headline)
            
            if maintenanceManager.tasks.isEmpty {
                Text("No hay tareas de mantenimiento registradas")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                VStack(spacing: 16) {
                    ForEach(maintenanceManager.tasks.prefix(3)) { task in
                        RecentTaskRowView(task: task)
                    }
                }
            }
            
            NavigationLink(destination: MaintenanceView(maintenanceManager: maintenanceManager)) {
                Text("Ver todas las tareas")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }
        }
    }
    
    // Sección de solicitudes de apoyo
    private var supportRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Solicitudes de Apoyo")
                .font(.headline)
            
            VStack(spacing: 16) {
                ForEach(maintenanceManager.supportRequests.prefix(3)) { request in
                    SupportRequestRowView(request: request)
                }
            }
            
            NavigationLink(destination: SupportRequestsListView(maintenanceManager: maintenanceManager)) {
                Text("Ver todas las solicitudes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }
        }
    }
    
    // Datos para los KPIs (en una implementación real, se calcularían a partir de maintenanceManager)
    private var kpiData: [KPIData] {
        let totalTasks = maintenanceManager.tasks.count
        let pendingTasks = maintenanceManager.tasks.filter { $0.status == "Pendiente" }.count
        let inProgressTasks = maintenanceManager.tasks.filter { $0.status == "En desarrollo" }.count
        let completedTasks = maintenanceManager.tasks.filter { $0.status == "Finalizado" }.count
        
        return [
            KPIData(title: "Total", value: totalTasks, icon: "wrench.and.screwdriver", color: .blue),
            KPIData(title: "Pendientes", value: pendingTasks, icon: "clock", color: .orange),
            KPIData(title: "En Progreso", value: inProgressTasks, icon: "gear", color: .purple),
            KPIData(title: "Completadas", value: completedTasks, icon: "checkmark.circle", color: .green)
        ]
    }
    
    // Datos para el gráfico de estado (en una implementación real, se calcularían a partir de maintenanceManager)
    private var statusData: [ChartData] {
        let pendingTasks = maintenanceManager.tasks.filter { $0.status == "Pendiente" }.count
        let inProgressTasks = maintenanceManager.tasks.filter { $0.status == "En desarrollo" }.count
        let completedTasks = maintenanceManager.tasks.filter { $0.status == "Finalizado" }.count
        
        return [
            ChartData(label: "Pendientes", value: pendingTasks, color: .orange),
            ChartData(label: "En Desarrollo", value: inProgressTasks, color: .blue),
            ChartData(label: "Finalizadas", value: completedTasks, color: .green)
        ]
    }
    
    // Datos para el gráfico de tipo (en una implementación real, se calcularían a partir de maintenanceManager)
    private var typeData: [ChartData] {
        let preventiveTasks = maintenanceManager.tasks.filter { $0.maintenanceType == "Preventivo" }.count
        let correctiveTasks = maintenanceManager.tasks.filter { $0.maintenanceType == "Correctivo" }.count
        
        return [
            ChartData(label: "Preventivo", value: preventiveTasks, color: .blue),
            ChartData(label: "Correctivo", value: correctiveTasks, color: .red)
        ]
    }
}

// Datos para las tarjetas de KPI
struct KPIData {
    let title: String
    let value: Int
    let icon: String
    let color: Color
}

// Tarjeta de KPI
struct KPICardView: View {
    let data: KPIData
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: data.icon)
                    .font(.title2)
                    .foregroundColor(data.color)
                
                Spacer()
                
                Text("\(data.value)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(data.color)
            }
            
            HStack {
                Text(data.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Fila para tareas recientes
struct RecentTaskRowView: View {
    let task: MaintenanceTask
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.deviceName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(task.location) - \(task.scheduledDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(task.status)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(8)
        }
    }
    
    private var statusColor: Color {
        switch task.status {
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

// Fila para solicitudes de apoyo
struct SupportRequestRowView: View {
    let request: SupportRequest
    
    var body: some View {
        HStack {
            Image(systemName: "person.fill.questionmark")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.deviceName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(request.siteName) - \(request.formattedRequestDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(request.status)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(8)
        }
    }
    
    private var statusColor: Color {
        switch request.status {
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

// Vista para lista completa de solicitudes de apoyo
struct SupportRequestsListView: View {
    @ObservedObject var maintenanceManager: MaintenanceManager
    
    var body: some View {
        List {
            ForEach(maintenanceManager.supportRequests) { request in
                SupportRequestRowView(request: request)
                    .padding(.vertical, 4)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Solicitudes de Apoyo")
    }
}

// Datos para gráficos
struct ChartData {
    let label: String
    let value: Int
    let color: Color
}

// Gráfico para estado de tareas
struct MaintenanceStatusChartView: View {
    let data: [ChartData]
    
    private var total: Int {
        data.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tareas por Estado")
                .font(.headline)
            
            if total == 0 {
                Text("No hay datos disponibles")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                HStack(alignment: .bottom, spacing: 20) {
                    // Gráfico de barras
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(data, id: \.label) { item in
                            VStack {
                                ZStack(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 150)
                                    
                                    Rectangle()
                                        .fill(item.color)
                                        .frame(width: 40, height: item.value > 0 ? 150 * CGFloat(item.value) / CGFloat(total) : 0)
                                }
                                
                                Text(item.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                            }
                        }
                    }
                    
                    // Leyenda y percentages
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data, id: \.label) { item in
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(item.label)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("\(item.value)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                
                                Text("(\(String(format: "%.1f", total > 0 ? Double(item.value) / Double(total) * 100 : 0))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// Gráfico para tipo de mantenimiento
struct MaintenanceTypeChartView: View {
    let data: [ChartData]
    
    private var total: Int {
        data.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tareas por Tipo")
                .font(.headline)
            
            if total == 0 {
                Text("No hay datos disponibles")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                HStack(spacing: 20) {
                    // Gráfico de pastel simplificado
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: data[0].value > 0 ? CGFloat(data[0].value) / CGFloat(total) : 0)
                            .stroke(data[0].color, lineWidth: 20)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        Circle()
                            .trim(from: data[0].value > 0 ? CGFloat(data[0].value) / CGFloat(total) : 0, to: 1)
                            .stroke(data[1].color, lineWidth: 20)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(total)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Leyenda y percentages
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(data, id: \.label) { item in
                            HStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(item.label)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(item.value)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Text("(\(String(format: "%.1f", total > 0 ? Double(item.value) / Double(total) * 100 : 0))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// Vista previa
struct MaintenanceDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceDashboardView(maintenanceManager: MaintenanceManager())
    }
} 