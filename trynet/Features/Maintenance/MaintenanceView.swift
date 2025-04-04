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
    @State private var showError = false
    @State private var errorMessage = ""
    
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
            task.location.localizedCaseInsensitiveContains(searchText) ||
            (task.projectName ?? "").localizedCaseInsensitiveContains(searchText)
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
            VStack(spacing: 0) {
            if isLandscape {
                // Diseño optimizado para modo horizontal
                    HStack(alignment: .top, spacing: 16) {
                    // Panel izquierdo con controles y estadísticas
                        VStack(spacing: 16) {
                        // Barra de búsqueda
                        searchBarView
                        
                        // Panel de bienvenida compacto para landscape
                        if showWelcome {
                            welcomePanel(compact: true)
                                .padding(.vertical, 8)
                        }
                        
                            // Estadísticas en modo vertical para landscape
                            VStack(spacing: 12) {
                                MaintenanceStatCard(
                                title: "Pendientes",
                                count: statistics.pending,
                                    icon: "clock.fill",
                                    color: .orange
                            )
                            
                                MaintenanceStatCard(
                                title: "En Desarrollo",
                                count: statistics.inProgress,
                                    icon: "gear",
                                    color: .blue
                            )
                            
                                MaintenanceStatCard(
                                title: "Finalizados",
                                count: statistics.completed,
                                    icon: "checkmark.circle.fill",
                                    color: .green
                            )
                        }
                        
                        // Filtros
                            filtersSection
                        }
                        .frame(width: 220)
                        .padding(.vertical)
                    
                    // Panel derecho con la lista de tareas
                        taskListView
                            .frame(maxWidth: .infinity)
                            .refreshable {
                                maintenanceManager.refreshTasks()
                            }
                    }
                    .padding(.horizontal)
            } else {
                // Diseño para modo vertical
                        // Barra de búsqueda
                        searchBarView
                        .padding(.horizontal)
                        
                        // Panel de bienvenida (solo visible inicialmente)
                        if showWelcome {
                            welcomePanel(compact: false)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        
                    // Estadísticas rápidas en horizontal para portrait
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            MaintenanceStatCard(
                                title: "Pendientes",
                                count: statistics.pending,
                                icon: "clock.fill",
                                color: .orange
                            )
                            
                            MaintenanceStatCard(
                                title: "En Desarrollo",
                                count: statistics.inProgress,
                                icon: "gear",
                                color: .blue
                            )
                            
                            MaintenanceStatCard(
                                title: "Finalizados",
                                count: statistics.completed,
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Filtros compactos en modo horizontal
                    filtersCompactSection
                    .padding(.horizontal)
                    
                    // Lista de tareas
                    taskListView
                        .refreshable {
                            maintenanceManager.refreshTasks()
                        }
                }
            }
            .navigationTitle("Mantenimiento")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddForm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        maintenanceManager.refreshTasks()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
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
            
            // Carga inicial de tareas
            maintenanceManager.loadTasks()
            
            // Registrar observador para errores
            NotificationCenter.default.addObserver(
                forName: Notification.Name("MaintenanceErrorNotification"),
                object: nil,
                queue: .main
            ) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    self.errorMessage = message
                    self.showError = true
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Aceptar"))
            )
        }
        .adaptToDeviceOrientation()
    }
    
    // MARK: - Componentes de la UI
    
    // Barra de búsqueda con botón de añadir
    private var searchBarView: some View {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
            TextField("Buscar tareas de mantenimiento", text: $searchText)
                .autocapitalization(.none)
                
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
        .padding(.vertical, 8)
    }
    
    // Panel de bienvenida
    private func welcomePanel(compact: Bool) -> some View {
        VStack(spacing: compact ? 10 : 16) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: compact ? 30 : 40))
                    .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("¡Bienvenido al módulo de Mantenimiento!")
                .font(compact ? .headline : .title3)
                .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            
                Text("Gestiona tus tareas de mantenimiento, registra el progreso y genera informes detallados de cada servicio.")
                    .font(compact ? .caption : .body)
                    .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                    .lineLimit(compact ? 2 : nil)
            }
            
            Button(action: {
                showingAddForm = true
            }) {
                Text("Crear nueva tarea")
                    .font(compact ? .footnote : .subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, compact ? 12 : 20)
                    .padding(.vertical, compact ? 6 : 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, compact ? 8 : 12)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                // Vista de lista vacía o sin resultados de búsqueda
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    if !searchText.isEmpty || maintenanceManager.currentStatusFilter != "Todos" || maintenanceManager.currentTypeFilter != "Todos" {
                        Text("No se encontraron tareas que coincidan con los filtros")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: {
                            searchText = ""
                            maintenanceManager.currentStatusFilter = "Todos"
                            maintenanceManager.currentTypeFilter = "Todos"
                            dateRangeStart = nil
                            dateRangeEnd = nil
                            maintenanceManager.filterTasks()
                        }) {
                            Text("Limpiar filtros")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else {
                        Text("No hay tareas de mantenimiento")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingAddForm = true
                        }) {
                            Text("Crear nueva tarea")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowInsets(EdgeInsets())
                .background(Color(.systemBackground))
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
                        MaintenanceTaskCard(task: task) {
                            // Acción para tomar la tarea
                            takeTask(task)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
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
    
    // Añadir esta función para manejar la acción de tomar una tarea
    func takeTask(_ task: MaintenanceTask) {
        // Abrir el detalle de la tarea con el formulario de edición abierto
        let detailView = MaintenanceTaskDetailView(maintenanceManager: maintenanceManager, task: task, showEditFormOnAppear: true)
        
        // Navegar a esta vista detalle
        // Esto depende de cómo esté implementada la navegación en la aplicación
        // Una opción es usar un valor @State para controlar la navegación programática
        // Otra opción es usar un coordinador de navegación
        
        // Para esta implementación, utilizaremos un enfoque simplificado
        // que abre la vista detalle y automáticamente muestra el formulario de edición
    }
    
    // MARK: - Filtros
    
    // Sección de filtros para formato vertical con botones compactos
    private var filtersCompactSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text("Filtros:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    showingCalendarFilter = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text("Fechas")
                        
                        if dateRangeStart != nil || dateRangeEnd != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(20)
                }
                
                if dateRangeStart != nil || dateRangeEnd != nil {
                    Button(action: {
                        dateRangeStart = nil
                        dateRangeEnd = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            HStack(spacing: 8) {
                Text("Estado:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(statusOptions, id: \.self) { status in
                            FilterButton(
                                title: status,
                                isSelected: maintenanceManager.currentStatusFilter == status,
                                color: statusColor(for: status)
                            ) {
                                maintenanceManager.currentStatusFilter = status
                                maintenanceManager.filterTasks()
                            }
                        }
                    }
                }
            }
            
            HStack(spacing: 8) {
                Text("Tipo:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(typeOptions, id: \.self) { type in
                            FilterButton(
                                title: type,
                                isSelected: maintenanceManager.currentTypeFilter == type,
                                color: .green
                            ) {
                                maintenanceManager.currentTypeFilter = type
                                maintenanceManager.filterTasks()
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Sección de filtros para formato horizontal
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filtros")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Estado:")
                    .font(.subheadline)
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
                .padding(6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo:")
                    .font(.subheadline)
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
                .padding(6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Fechas:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingCalendarFilter = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                        
                        Text("Seleccionar período")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if dateRangeStart != nil || dateRangeEnd != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
                .padding(8)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
                
                if dateRangeStart != nil || dateRangeEnd != nil {
                    HStack {
                        if let startDate = dateRangeStart {
                            Text("De: \(formattedDate(startDate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let endDate = dateRangeEnd {
                            Text("A: \(formattedDate(endDate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
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
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // Formateador de fechas para mejor legibilidad
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
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

// Nueva tarjeta de estadísticas basada en el estilo de ProjectStatCard
struct MaintenanceStatCard: View {
    var title: String
    var count: Int
    var icon: String
    var color: Color
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        if isLandscape {
            // Diseño compacto para orientación landscape
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
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
            .padding(12)
            .frame(width: 180)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        } else {
            // Diseño para orientación portrait
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(color)
            }
            
            Text(title)
                    .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 130, height: 90)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        }
    }
}

// MARK: - Vistas auxiliares

struct MaintenanceTaskCard: View {
    let task: MaintenanceTask
    var onTakeTask: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Encabezado con nombre, proyecto y prioridad
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                Text(task.deviceName)
                    .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let projectName = task.projectName {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Text(projectName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Estado y prioridad
                VStack(alignment: .trailing, spacing: 6) {
                    // Indicador de prioridad
                    PriorityBadge(priority: task.priority)
                    
                    // Tipo de mantenimiento
                    Text(task.maintenanceType)
                        .font(.caption)
                        .padding(4)
                        .background(task.typeColor.opacity(0.1))
                        .foregroundColor(task.typeColor)
                        .cornerRadius(4)
                }
            }
            
            // Información de ubicación
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("\(task.location) - \(task.siteName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Barra de progreso
            VStack(spacing: 5) {
                ProgressView(value: task.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor(task.progress)))
            
            HStack {
                    Text("Progreso: \(Int(task.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                Image(systemName: "calendar")
                            .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(task.scheduledDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    }
                }
            }
            
            // Estado actual y botón de tomar tarea
            HStack {
                // Indicador de estado
                Text(task.status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: task.status).opacity(0.1))
                    .foregroundColor(statusColor(for: task.status))
                    .cornerRadius(8)
                
                Spacer()
                
                // Sólo mostrar botón de tomar tarea si está pendiente
                if task.status == "Pendiente" {
                    Button(action: onTakeTask) {
                        Text("Tomar tarea")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private func progressColor(_ value: Double) -> Color {
        if value < 0.3 {
            return .red
        } else if value < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Pendiente": return .orange
        case "En desarrollo": return .blue
        case "Finalizado": return .green
        default: return .gray
        }
    }
}

struct MaintenanceTaskRow: View {
    let task: MaintenanceTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Encabezado - Nombre del punto y tipo de tarea
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
                    
                    if let projectName = task.projectName {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(projectName)
                    .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    MaintenanceStatusBadge(status: task.status)
                        .padding(.trailing, 4)
                
                Text(task.maintenanceType)
                    .font(.caption)
                    .padding(4)
                        .background(task.typeColor.opacity(0.1))
                        .foregroundColor(task.typeColor)
                    .cornerRadius(4)
                }
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

// Componente para mostrar la prioridad de una tarea
struct PriorityBadge: View {
    let priority: String
    
    var color: Color {
        switch priority {
        case "Alta":
            return .red
        case "Media":
            return .orange
        case "Baja":
            return .green
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(priority)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// Función auxiliar para el color del estado
private func statusColor(for status: String) -> Color {
    switch status {
    case "Pendiente": return .orange
    case "En desarrollo": return .blue
    case "Finalizado": return .green
    default: return .gray
    }
}

// MARK: - Vista previa
struct MaintenanceView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceView(maintenanceManager: MaintenanceManager())
    }
} 