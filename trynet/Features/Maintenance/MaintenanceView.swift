import SwiftUI

struct MaintenanceView: View {
    @ObservedObject var maintenanceManager: MaintenanceManager
    @Environment(\.isLandscape) private var isLandscape
    
    @State private var searchText = ""
    @State private var showingAddForm = false
    @State private var showWelcome = true
    @State private var showingCalendarFilter = false
    @State private var dateRangeStart: Date? = nil
    @State private var dateRangeEnd: Date? = nil
    
    // Opciones para los filtros
    let statusOptions = ["Todos", "Pendiente", "En desarrollo", "Finalizado"]
    let typeOptions = ["Todos", "Preventivo", "Correctivo"]
    
    // Tareas filtradas
    var filteredTasks: [MaintenanceTask] {
        let tasksFilteredByStatusAndType = maintenanceManager.filteredTasks
        
        let filteredBySearch = searchText.isEmpty ? tasksFilteredByStatusAndType : tasksFilteredByStatusAndType.filter { task in
            task.deviceName.localizedCaseInsensitiveContains(searchText) ||
            task.description.localizedCaseInsensitiveContains(searchText) ||
            task.siteName.localizedCaseInsensitiveContains(searchText) ||
            task.location.localizedCaseInsensitiveContains(searchText)
        }
        
        // Filtrar por fechas si están configuradas
        return filteredBySearch.filter { task in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            
            var passesDateFilter = true
            
            if let startDate = dateRangeStart, let taskDate = dateFormatter.date(from: task.scheduledDate) {
                // Comparar solo fecha, no hora
                let calendar = Calendar.current
                let taskDateOnly = calendar.startOfDay(for: taskDate)
                let startDateOnly = calendar.startOfDay(for: startDate)
                
                if taskDateOnly < startDateOnly {
                    passesDateFilter = false
                }
            }
            
            if let endDate = dateRangeEnd, let taskDate = dateFormatter.date(from: task.scheduledDate) {
                // Comparar solo fecha, no hora
                let calendar = Calendar.current
                let taskDateOnly = calendar.startOfDay(for: taskDate)
                let endDateOnly = calendar.startOfDay(for: endDate)
                
                if taskDateOnly > endDateOnly {
                    passesDateFilter = false
                }
            }
            
            return passesDateFilter
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
                                
                                Picker("Estado", selection: $maintenanceManager.currentStatusFilter) {
                                    ForEach(statusOptions, id: \.self) { status in
                                        Text(status).tag(status)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .onChange(of: maintenanceManager.currentStatusFilter) { _, _ in
                                    maintenanceManager.filterTasks()
                                }
                            }
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            HStack {
                                Text("Tipo:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("Tipo", selection: $maintenanceManager.currentTypeFilter) {
                                    ForEach(typeOptions, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .onChange(of: maintenanceManager.currentTypeFilter) { _, _ in
                                    maintenanceManager.filterTasks()
                                }
                            }
                            .padding(6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            
                            Button(action: {
                                showingCalendarFilter = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                    
                                    Text("Filtrar por Fecha")
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    if dateRangeStart != nil || dateRangeEnd != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(6)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                            
                            if dateRangeStart != nil || dateRangeEnd != nil {
                                HStack {
                                    Text("Fechas activas")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        dateRangeStart = nil
                                        dateRangeEnd = nil
                                    }) {
                                        Text("Limpiar")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.top, 4)
                            }
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
                            .refreshable {
                                // En lugar de simulación, ahora realmente recargamos datos
                                maintenanceManager.refreshTasks()
                            }
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
                            
                            Picker("Estado", selection: $maintenanceManager.currentStatusFilter) {
                                ForEach(statusOptions, id: \.self) { status in
                                    Text(status).tag(status)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            .onChange(of: maintenanceManager.currentStatusFilter) { _, _ in
                                maintenanceManager.filterTasks()
                            }
                            
                            Picker("Tipo", selection: $maintenanceManager.currentTypeFilter) {
                                ForEach(typeOptions, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .onChange(of: maintenanceManager.currentTypeFilter) { _, _ in
                                maintenanceManager.filterTasks()
                            }
                        }
                        .font(.subheadline)
                        
                        // Botón de filtro por fecha
                        Button(action: {
                            showingCalendarFilter = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.purple)
                                
                                Text("Filtrar por Fecha")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if dateRangeStart != nil || dateRangeEnd != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                        
                                        Button(action: {
                                            dateRangeStart = nil
                                            dateRangeEnd = nil
                                        }) {
                                            Text("Limpiar")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                        }
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
                        .refreshable {
                            // En lugar de simulación, ahora realmente recargamos datos
                            maintenanceManager.refreshTasks()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .sheet(isPresented: $showingAddForm) {
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
        .sheet(isPresented: $showingCalendarFilter) {
            DateFilterView(
                startDate: $dateRangeStart,
                endDate: $dateRangeEnd,
                isPresented: $showingCalendarFilter
            )
        }
        .onAppear {
            // Mostrar panel de bienvenida solo si no hay tareas
            showWelcome = maintenanceManager.tasks.isEmpty
        }
        .adaptToDeviceOrientation()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Refrescar datos manualmente
                    maintenanceManager.refreshTasks()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(maintenanceManager.isLoading)
            }
        }
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
                Image(systemName: "wrench.and.screwdriver.fill")
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
            if maintenanceManager.isLoading && maintenanceManager.tasks.isEmpty {
                // Vista de carga
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Cargando tareas de mantenimiento...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowInsets(EdgeInsets())
                .background(Color(.systemBackground))
            } else if let errorMessage = maintenanceManager.errorMessage, maintenanceManager.tasks.isEmpty {
                // Vista de error
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Error al cargar tareas")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    Button(action: {
                        maintenanceManager.refreshTasks()
                    }) {
                        Text("Reintentar")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowInsets(EdgeInsets())
                .background(Color(.systemBackground))
            } else if filteredTasks.isEmpty {
                if maintenanceManager.tasks.isEmpty && !showWelcome {
                    VStack(spacing: 20) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.bottom, 5)
                        
                        Text("No hay tareas creadas")
                            .font(.headline)
                        
                        Text("Pulsa el botón + para crear una nueva tarea de mantenimiento.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingAddForm = true
                        }) {
                            Label("Crear nueva tarea", systemImage: "plus")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else if !maintenanceManager.tasks.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No hay resultados")
                            .font(.headline)
                        
                        Text("No se encontraron tareas con los filtros actuales.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        // Botón para limpiar filtros
                        Button(action: {
                            maintenanceManager.currentStatusFilter = "Todos"
                            maintenanceManager.currentTypeFilter = "Todos"
                            searchText = ""
                            dateRangeStart = nil
                            dateRangeEnd = nil
                        }) {
                            Text("Limpiar filtros")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            } else {
                if maintenanceManager.isLoading {
                    // Indicador de recarga cuando ya tenemos datos
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                    .background(Color(.systemBackground))
                }
                
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

// Vista para filtrar por fechas
struct DateFilterView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var isPresented: Bool
    
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()
    @State private var useStartDate = false
    @State private var useEndDate = false
    
    var body: some View {
        NavigationStack {
            Form {
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
                
                Section {
                    Button("Limpiar filtros") {
                        useStartDate = false
                        useEndDate = false
                        startDate = nil
                        endDate = nil
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filtrar por Fecha")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aplicar") {
                        startDate = useStartDate ? tempStartDate : nil
                        endDate = useEndDate ? tempEndDate : nil
                        isPresented = false
                    }
                }
            }
            .onAppear {
                if let start = startDate {
                    tempStartDate = start
                    useStartDate = true
                }
                
                if let end = endDate {
                    tempEndDate = end
                    useEndDate = true
                }
            }
        }
    }
}

// MARK: - Vistas auxiliares

struct CompactStatCard: View {
    var title: String
    var count: Int
    var color: Color
    var icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.headline)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct MaintenanceTaskRow: View {
    let task: MaintenanceTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Encabezado - Nombre del dispositivo y tipo de tarea
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.deviceName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("\(task.location) - \(task.siteName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                MaintenanceStatusBadge(status: task.status)
                    .padding(.trailing, 4)
                
                Text(task.maintenanceType)
                    .font(.caption)
                    .padding(4)
                    .background(task.typeColor.opacity(0.1))
                    .foregroundColor(task.typeColor)
                    .cornerRadius(4)
            }
            
            // Progreso de la tarea
            if task.status != "Finalizado" {
                VStack(spacing: 4) {
                    ProgressView(value: task.progress, total: 1.0)
                    
                    HStack {
                        Text("Progreso: \(Int(task.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(task.scheduledDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    Text("Completado: \(task.completedDate ?? "Sin fecha")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if task.hasGeneratedReport {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct MaintenanceStatusBadge: View {
    let status: String
    
    var color: Color {
        switch status {
        case "Pendiente":
            return .yellow
        case "En desarrollo":
            return .blue
        case "Finalizado":
            return .green
        default:
            return .gray
        }
    }
    
    var icon: String {
        switch status {
        case "Pendiente":
            return "clock.fill"
        case "En desarrollo":
            return "gearshape.fill"
        case "Finalizado":
            return "checkmark.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(status)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

// MARK: - Vista previa
struct MaintenanceView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceView(maintenanceManager: MaintenanceManager())
    }
} 