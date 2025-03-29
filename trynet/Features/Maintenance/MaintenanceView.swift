import SwiftUI

struct MaintenanceView: View {
    @ObservedObject var maintenanceManager: MaintenanceManager
    @Environment(\.isLandscape) private var isLandscape
    
    @State private var statusFilter = "Todos"
    @State private var typeFilter = "Todos"
    @State private var searchText = ""
    @State private var showingAddForm = false
    @State private var showWelcome = true
    
    // Opciones para los filtros
    let statusOptions = ["Todos", "Pendiente", "En desarrollo", "Finalizado"]
    let typeOptions = ["Todos", "Preventivo", "Correctivo"]
    
    // Tareas filtradas
    var filteredTasks: [MaintenanceTask] {
        let tasksFilteredByStatus = maintenanceManager.getFilteredTasks(statusFilter: statusFilter, typeFilter: typeFilter)
        
        if searchText.isEmpty {
            return tasksFilteredByStatus
        } else {
            return tasksFilteredByStatus.filter { task in
                task.deviceName.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText) ||
                task.siteName.localizedCaseInsensitiveContains(searchText) ||
                task.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Estadísticas
    var statistics: (pending: Int, inProgress: Int, completed: Int) {
        var pending = 0
        var inProgress = 0
        var completed = 0
        
        for task in maintenanceManager.tasks {
            switch task.status {
            case "Pendiente": pending += 1
            case "En desarrollo": inProgress += 1
            case "Finalizado": completed += 1
            default: break
            }
        }
        
        return (pending, inProgress, completed)
    }
    
    var body: some View {
        NavigationView {
            if isLandscape {
                // Diseño optimizado para modo horizontal
                HStack(alignment: .top, spacing: 0) {
                    // Panel izquierdo con controles y estadísticas
                    VStack(spacing: 12) {
                        // Barra de búsqueda
                        searchBarView
                        
                        // Panel de bienvenida compacto para landscape
                        if showWelcome {
                            welcomePanel(compact: true)
                                .padding(.vertical, 8)
                        }
                        
                        // Estadísticas en vertical
                        VStack(spacing: 10) {
                            CompactStatCard(
                                title: "Pendientes",
                                count: statistics.pending,
                                color: .orange,
                                icon: "clock.fill"
                            )
                            
                            CompactStatCard(
                                title: "En Desarrollo",
                                count: statistics.inProgress,
                                color: .blue,
                                icon: "gear"
                            )
                            
                            CompactStatCard(
                                title: "Finalizados",
                                count: statistics.completed,
                                color: .green,
                                icon: "checkmark.circle.fill"
                            )
                        }
                        
                        // Filtros
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Filtros:")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("Estado:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("Estado", selection: $statusFilter) {
                                    ForEach(statusOptions, id: \.self) { status in
                                        Text(status).tag(status)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                            }
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            HStack {
                                Text("Tipo:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("Tipo", selection: $typeFilter) {
                                    ForEach(typeOptions, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                            }
                            .padding(6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .font(.subheadline)
                        
                        Spacer()
                    }
                    .padding(12)
                    .frame(width: 250)
                    .background(Color(.systemBackground))
                    
                    // Panel derecho con la lista de tareas
                    VStack(spacing: 0) {
                        // Lista de tareas
                        taskListView
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Diseño para modo vertical
                VStack(spacing: 0) {
                    // Barra de búsqueda y filtros en una tarjeta compacta
                    VStack(spacing: 12) {
                        // Barra de búsqueda
                        searchBarView
                        
                        // Panel de bienvenida (solo visible inicialmente)
                        if showWelcome {
                            welcomePanel(compact: false)
                                .padding(.vertical, 8)
                        }
                        
                        // Estadísticas compactas horizontales con mejor espaciado
                        HStack(spacing: 12) {
                            CompactStatCard(
                                title: "Pendientes",
                                count: statistics.pending,
                                color: .orange,
                                icon: "clock.fill"
                            )
                            
                            CompactStatCard(
                                title: "En Desarrollo",
                                count: statistics.inProgress,
                                color: .blue,
                                icon: "gear"
                            )
                            
                            CompactStatCard(
                                title: "Finalizados",
                                count: statistics.completed,
                                color: .green,
                                icon: "checkmark.circle.fill"
                            )
                        }
                        
                        // Filtros
                        HStack {
                            Text("Filtros:")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Picker("Estado", selection: $statusFilter) {
                                ForEach(statusOptions, id: \.self) { status in
                                    Text(status).tag(status)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            Picker("Tipo", selection: $typeFilter) {
                                ForEach(typeOptions, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .font(.subheadline)
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // Lista de tareas (ahora ocupa todo el espacio disponible)
                    taskListView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .sheet(isPresented: $showingAddForm) {
            NavigationView {
                MaintenanceFormView(
                    isPresented: $showingAddForm, 
                    onSave: { task in
                        maintenanceManager.addTask(task)
                        // Ocultar el panel de bienvenida cuando se cree una tarea
                        if !maintenanceManager.tasks.isEmpty {
                            showWelcome = false
                        }
                    }
                )
                .navigationTitle("Nueva Tarea")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            // Mostrar panel de bienvenida solo si no hay tareas
            showWelcome = maintenanceManager.tasks.isEmpty
        }
        .adaptToDeviceOrientation()
    }
    
    // MARK: - Componentes de la UI
    
    // Barra de búsqueda con botón de añadir
    private var searchBarView: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Buscar tareas...", text: $searchText)
                    .textFieldStyle(DefaultTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            Button(action: {
                showingAddForm = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
    }
    
    // Panel de bienvenida
    private func welcomePanel(compact: Bool) -> some View {
        VStack(spacing: 10) {
            if !compact {
                Image(systemName: "hand.wave.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .padding(.bottom, 5)
            }
            
            Text("¡Bienvenido al Mantenimiento!")
                .font(compact ? .headline : .title3)
                .fontWeight(.bold)
            
            Text("Aquí puedes crear y gestionar tareas de mantenimiento para tus equipos.")
                .font(compact ? .caption : .subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingAddForm = true
            }) {
                Label("Crear primera tarea", systemImage: "plus.circle")
                    .font(compact ? .caption : .subheadline)
                    .padding(.horizontal, compact ? 12 : 16)
                    .padding(.vertical, compact ? 6 : 8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // Lista de tareas
    private var taskListView: some View {
        List {
            if filteredTasks.isEmpty {
                if maintenanceManager.tasks.isEmpty && !showWelcome {
                    Text("No hay tareas creadas. Pulsa el botón + para crear una nueva tarea.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Text("No hay tareas que coincidan con los filtros")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            } else {
                ForEach(filteredTasks) { task in
                    NavigationLink(destination: MaintenanceTaskDetailView(maintenanceManager: maintenanceManager, task: task)) {
                        MaintenanceTaskRow(task: task)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        maintenanceManager.deleteTask(id: filteredTasks[index].id)
                    }
                    
                    // Mostrar panel de bienvenida si todas las tareas son eliminadas
                    if maintenanceManager.tasks.isEmpty {
                        showWelcome = true
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Vistas auxiliares

struct CompactStatCard: View {
    var title: String
    var count: Int
    var color: Color
    var icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundColor(color)
                
                Text("\(count)")
                    .font(.callout)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct MaintenanceTaskRow: View {
    let task: MaintenanceTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.deviceName)
                    .font(.headline)
                
                Spacer()
                
                // Indicador de progreso circular pequeño
                if task.status != "Finalizado" && task.progress > 0 {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(task.progress))
                            .stroke(Color.blue, lineWidth: 4)
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(task.progress * 100))%")
                            .font(.system(size: 8))
                            .fontWeight(.bold)
                    }
                }
            }
            
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(task.siteName), \(task.location)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(task.scheduledDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(task.taskType)
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Text(task.maintenanceType)
                    .font(.caption)
                    .padding(4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 6)
    }
}

struct MaintenanceStatusBadge: View {
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

// MARK: - Vista previa
struct MaintenanceView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceView(maintenanceManager: MaintenanceManager())
    }
} 