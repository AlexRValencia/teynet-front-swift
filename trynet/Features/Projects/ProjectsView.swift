import SwiftUI
import MapKit
import CoreLocation
import Combine

// Importación de modelos personalizados
import Foundation

// Modelos
struct ProjectPoint: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var type: PointType
    var location: Location
    var city: String
    var materialName: String?
    var material: Material?
    var operationalStatus: OperationalStatus = .operational
    
    struct Location {
        var latitude: Double
        var longitude: Double
        var address: String?
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    enum OperationalStatus: String, CaseIterable {
        case operational = "Operativo"
        case issues = "Con problemas"
        case offline = "Fuera de servicio"
        
        var color: Color {
            switch self {
            case .operational: return .green
            case .issues: return .orange
            case .offline: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .operational: return "checkmark.circle.fill"
            case .issues: return "exclamationmark.triangle.fill"
            case .offline: return "xmark.circle.fill"
            }
        }
    }
    
    enum PointType: String, CaseIterable, Identifiable {
        case LPR = "LPR"
        case CCTV = "CCTV"
        case ALARM = "ALARM"
        case RADIO_BASE = "RADIO_BASE"
        case RELAY = "RELAY"
        case UNKNOWN = "Desconocido"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .LPR: return "camera.metering.center.weighted"
            case .CCTV: return "camera.fill"
            case .ALARM: return "bell.fill"
            case .RADIO_BASE: return "antenna.radiowaves.left.and.right"
            case .RELAY: return "poweroutlet.type.b.fill"
            case .UNKNOWN: return "questionmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .LPR: return .blue
            case .CCTV: return .purple
            case .ALARM: return .red
            case .RADIO_BASE: return .orange
            case .RELAY: return .green
            case .UNKNOWN: return .gray
            }
        }
    }
}

// Extensiones para conformar a protocolos
extension ProjectPoint: Equatable {
    static func == (lhs: ProjectPoint, rhs: ProjectPoint) -> Bool {
        lhs.id == rhs.id
    }
}

extension ProjectPoint: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Para Material
struct Material: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var category: String
    var quantity: Int
    var description: String?
    var location: String?
    var serialNumber: String?
    var available: Int { quantity }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Material, rhs: Material) -> Bool {
        lhs.id == rhs.id
    }
}

// Componente para mostrar la ubicación del usuario en el mapa
struct UserLocationAnnotation: MapContent {
    var body: some MapContent {
        UserAnnotation()
    }
}

// Componente para visualizar la ubicación del usuario
struct UserLocationMarker: MapContent {
    var body: some MapContent {
        // En lugar de MapUserLocationButton, usamos un control que muestre la ubicación del usuario
        UserLocationAnnotation()
    }
}

struct ProjectsView: View {
    @StateObject private var viewModel = ProjectViewModel()
    
    @State private var showingNewProjectSheet = false
    @State private var showingClientsSheet = false
    @State private var selectedTab = 0
    @State private var showWelcome = false
    @Environment(\.isLandscape) private var isLandscape
    
    let statusOptions = ["Todos", "Diseño", "En desarrollo", "Finalizado", "Suspendido"]
    
    var filteredProjects: [Project] {
        viewModel.filteredProjects
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if isLandscape {
                    // Diseño optimizado para modo horizontal
                    HStack(alignment: .top, spacing: 16) {
                        // Panel izquierdo con controles
            VStack(spacing: 16) {
                // Barra de búsqueda y filtro
                            searchAndFilterBar
                            
                            // Panel de bienvenida si está activado
                            if showWelcome {
                                welcomePanel(compact: true)
                                    .padding(.vertical, 8)
                            }
                            
                            // Estadísticas en modo vertical para landscape
                            VStack(spacing: 12) {
                                ProjectStatCard(title: "Total", count: viewModel.projects.count, icon: "folder", color: .blue)
                                ProjectStatCard(title: "En desarrollo", count: viewModel.projects.filter { $0.status == "En desarrollo" }.count, icon: "gearshape", color: .orange)
                                ProjectStatCard(title: "Finalizados", count: viewModel.projects.filter { $0.status == "Finalizado" }.count, icon: "checkmark.circle", color: .green)
                            }
                        }
                        .frame(width: 200)
                        .padding(.vertical)
                        
                        // Panel derecho con proyectos
                        projectListView
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                } else {
                    // Diseño original para modo vertical
                    // Barra de búsqueda y filtro
                    searchAndFilterBar
                        .padding(.horizontal)
                    
                    // Panel de bienvenida si está activado
                    if showWelcome {
                        welcomePanel(compact: false)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    
                    // Estadísticas rápidas en horizontal para portrait
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ProjectStatCard(title: "Total", count: viewModel.projects.count, icon: "folder", color: .blue)
                            ProjectStatCard(title: "En desarrollo", count: viewModel.projects.filter { $0.status == "En desarrollo" }.count, icon: "gearshape", color: .orange)
                            ProjectStatCard(title: "Finalizados", count: viewModel.projects.filter { $0.status == "Finalizado" }.count, icon: "checkmark.circle", color: .green)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Lista de proyectos
                    projectListView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingClientsSheet = true
                    }) {
                        Image(systemName: "person.crop.square")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await viewModel.refreshProjects()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectView(isPresented: $showingNewProjectSheet, onSave: { newProject in
                    // Usar el método createProject para guardar el proyecto en la base de datos
                    viewModel.createProject(project: newProject)
                        .sink(receiveValue: { _ in
                            // Cuando se completa la creación, recargamos los proyectos
                            Task {
                                await viewModel.refreshProjects()
                            }
                            
                    // Ocultar panel de bienvenida después de crear un proyecto
                    showWelcome = false
                        })
                        .store(in: &viewModel.cancellables)
                })
            }
            .sheet(isPresented: $showingClientsSheet) {
                ClientsManagementView(isPresented: $showingClientsSheet)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(removing: .title)
            .onAppear {
                // Mostrar panel de bienvenida inicialmente
                showWelcome = true
                
                // Verificamos si hay proyectos después de que se carguen los datos
                // Usamos un pequeño retraso para permitir que los datos se carguen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Si hay proyectos, ocultamos la bienvenida después de 3 segundos
                    if !viewModel.projects.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showWelcome = false
                            }
                        }
                    }
                    // Si no hay proyectos, el panel de bienvenida permanece visible
                }
            }
            .refreshable {
                await viewModel.refreshProjects()
            }
            .onChange(of: viewModel.projects) { _, newProjects in
                // Si hay proyectos, ocultamos el panel de bienvenida después de 3 segundos
                if !newProjects.isEmpty && showWelcome {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showWelcome = false
                        }
                    }
                } else if newProjects.isEmpty {
                    // Si no hay proyectos, mostramos el panel de bienvenida
                    withAnimation {
                        showWelcome = true
                    }
                }
            }
        }
        .adaptToDeviceOrientation()
    }
    
    // MARK: - Vista de componentes
    
    // Panel de bienvenida
    private func welcomePanel(compact: Bool) -> some View {
        VStack(spacing: 10) {
            if !compact {
                Image(systemName: "hands.sparkles.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .padding(.bottom, 5)
            }
            
            Text("¡Bienvenido a Gestión de Proyectos!")
                .font(compact ? .headline : .title3)
                .fontWeight(.bold)
            
            Text("Visualiza y gestiona tus proyectos desde una única ubicación.")
                .font(compact ? .caption : .subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingNewProjectSheet = true
            }) {
                Label("Crear nuevo proyecto", systemImage: "plus.circle")
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
    
    // Barra de búsqueda y filtros
    var searchAndFilterBar: some View {
        HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                TextField("Buscar proyecto", text: $viewModel.searchText)
                            .disableAutocorrection(true)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Menu {
                        ForEach(statusOptions, id: \.self) { status in
                            Button(action: {
                        viewModel.applyStatusFilter(status == "Todos" ? nil : status)
                            }) {
                                HStack {
                                    Text(status)
                            if status == "Todos" && viewModel.selectedStatusFilter == nil {
                                Image(systemName: "checkmark")
                            } else if status == viewModel.selectedStatusFilter {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                HStack {
                    Text(viewModel.selectedStatusFilter ?? "Todos")
                    Image(systemName: "chevron.down")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                    }
            
            Button(action: {
                showingNewProjectSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
        }
                }
                
                // Lista de proyectos
    var projectListView: some View {
        Group {
            if viewModel.isLoading && viewModel.projects.isEmpty {
                // Vista de carga
                    VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Cargando proyectos...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else if let errorMessage = viewModel.errorMessage {
                // Vista de error
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Error al cargar proyectos")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        Button(action: {
                        Task {
                            await viewModel.refreshProjects()
                        }
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
                .background(Color(.systemBackground))
            } else if filteredProjects.isEmpty {
                // Vista de estado vacío
                VStack(spacing: 20) {
                    Image(systemName: "folder")
                        .font(.system(size: 50))
                        .foregroundColor(.blue.opacity(0.8))
                    Text("No hay proyectos")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Crea un nuevo proyecto para comenzar")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(action: {
                        showingNewProjectSheet = true
                    }) {
                        Text("Crear proyecto")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(filteredProjects) { project in
                            NavigationLink(destination: ProjectDetailView(project: project)) {
                            // Tarjeta adaptada según la orientación
                            if isLandscape {
                                LandscapeProjectCard(project: project)
                            } else {
                                ProjectCard(project: project)
                            }
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
    }
}

// MARK: - Componentes

struct ProjectStatCard: View {
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
            // Diseño original para orientación portrait
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

struct ProjectCard: View {
    var project: Project
    
    var statusColor: Color {
        switch project.status {
        case "En desarrollo":
            return .blue
        case "Finalizado":
            return .green
        case "Diseño":
            return .orange
        case "Suspendido":
            return .red
        default:
            return .gray
        }
    }
    
    func healthColor(health: Double) -> Color {
        if health >= 0.8 {
            return .green
        } else if health >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(project.client)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Medidor de salud
                HStack(spacing: 4) {
                    Image(systemName: healthStatusIcon(health: project.health))
                        .foregroundColor(healthColor(health: project.health))
                    
                    Text("\(Int(project.health * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(healthColor(health: project.health))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(healthColor(health: project.health).opacity(0.2))
                .cornerRadius(20)
            }
            
            // Barra de salud del sistema
            VStack(spacing: 5) {
                ProgressView(value: project.health, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: healthColor(health: project.health)))
                
                HStack {
                    Text("Salud del sistema")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(project.startDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    func healthStatusIcon(health: Double) -> String {
        if health >= 0.8 {
            return "checkmark.circle.fill"
        } else if health >= 0.5 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
}

// Tarjeta optimizada para modo landscape
struct LandscapeProjectCard: View {
    var project: Project
    
    var statusColor: Color {
        switch project.status {
        case "En desarrollo":
            return .blue
        case "Finalizado":
            return .green
        case "Diseño":
            return .orange
        case "Suspendido":
            return .red
        default:
            return .gray
        }
    }
    
    func healthColor(health: Double) -> Color {
        if health >= 0.8 {
            return .green
        } else if health >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    func healthStatusIcon(health: Double) -> String {
        if health >= 0.8 {
            return "checkmark.circle.fill"
        } else if health >= 0.5 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Información principal
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: healthStatusIcon(health: project.health))
                            .foregroundColor(healthColor(health: project.health))
                        
                        Text("\(Int(project.health * 100))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(healthColor(health: project.health))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(healthColor(health: project.health).opacity(0.2))
                    .cornerRadius(20)
                }
                
                Text(project.client)
                    .font(.subheadline)
                        .foregroundColor(.secondary)
            }
            
            // Barra de salud del sistema vertical
            VStack(spacing: 5) {
                Text("Salud del sistema")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: project.health, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: healthColor(health: project.health)))
                    .frame(width: 120)
            }
            
            // Fechas
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Límite: \(project.deadline)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Inicio: \(project.startDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct NewProjectView: View {
    @Binding var isPresented: Bool
    var onSave: (Project) -> Void
    
    @StateObject private var clientManager = ClientManager.shared
    @StateObject private var userAdminViewModel = UserAdminViewModel()
    @State private var projectName = ""
    @State private var clientName = ""
    @State private var selectedClient: Client?
    @State private var description = ""
    @State private var status = "Diseño"
    @State private var startDate = Date()
    @State private var deadlineDate = Date(timeIntervalSinceNow: 60 * 60 * 24 * 30) // Un mes desde ahora
    @State private var teamMembers: [String] = []
    @State private var showingTeamSelector = false
    @State private var showingClientSelector = false
    @State private var showingNewClientSheet = false
    @State private var searchTeamMember = ""
    @State private var searchClient = ""
    
    let statusOptions = ["Diseño", "En desarrollo", "Finalizado", "Suspendido"]
    
    var filteredClients: [Client] {
        if searchClient.isEmpty {
            return clientManager.getActiveClients()
        } else {
            return clientManager.getActiveClients().filter { client in
                client.name.lowercased().contains(searchClient.lowercased()) ||
                client.contactPerson.lowercased().contains(searchClient.lowercased())
            }
        }
    }
    
    var filteredUsers: [AdminUser] {
        if searchTeamMember.isEmpty {
            return userAdminViewModel.users.filter { !teamMembers.contains($0.fullName) }
        } else {
            return userAdminViewModel.users.filter { user in
                !teamMembers.contains(user.fullName) &&
                user.fullName.lowercased().contains(searchTeamMember.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información básica")) {
                    TextField("Nombre del proyecto", text: $projectName)
                    
                    // Cliente
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Cliente")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let client = selectedClient {
                                Text(client.name)
                                    .foregroundColor(.primary)
                            } else if !clientName.isEmpty {
                                Text(clientName)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Seleccione un cliente")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingClientSelector = true
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Estado del proyecto
                    Picker("Estado", selection: $status) {
                        ForEach(statusOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                Section(header: Text("Descripción")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Fechas")) {
                    DatePicker("Fecha de inicio", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("Fecha límite", selection: $deadlineDate, in: startDate..., displayedComponents: .date)
                }
                
                Section(header: Text("Equipo")) {
                    ForEach(teamMembers, id: \.self) { member in
                        HStack {
                            Text(member)
                            Spacer()
                            Button(action: {
                                teamMembers.removeAll { $0 == member }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                        Button(action: {
                        showingTeamSelector = true
                        userAdminViewModel.loadUsers()
                        }) {
                            HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)
                                Text("Añadir miembro")
                        }
                    }
                }
            }
            .navigationTitle("Nuevo Proyecto")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    isPresented = false
                },
                trailing: Button("Guardar") {
                    // Configurar el formateador de fechas para un formato más legible
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d 'de' MMMM, yyyy"
                    dateFormatter.locale = Locale(identifier: "es_ES")
                    
                    // Obtener correctamente el ID del cliente
                    let clientId = selectedClient?.id ?? ""
                    let clientName = selectedClient?.name ?? ""
                    
                    // Obtener los IDs y nombres de los miembros del equipo
                    let teamMemberIds = userAdminViewModel.users
                        .filter { user in teamMembers.contains(user.fullName) }
                        .map { $0.id }
                    
                    let newProject = Project(
                        id: UUID().uuidString,
                        name: projectName,
                        status: status,
                        health: status == "Finalizado" ? 1.0 : 0.0,
                        deadline: dateFormatter.string(from: deadlineDate),
                        description: description,
                        client: clientName, // Usar el nombre del cliente
                        clientId: clientId, // Guardar también el ID
                        startDate: dateFormatter.string(from: startDate),
                        team: teamMembers, // Nombres de los miembros
                        teamIds: teamMemberIds, // IDs de los miembros
                        tasks: []
                    )
                    
                    onSave(newProject)
                    isPresented = false
                }
                .disabled(projectName.isEmpty || selectedClient == nil)
            )
            .sheet(isPresented: $showingClientSelector) {
                ClientSelectorView(
                    selectedClient: $selectedClient,
                    clientName: $clientName,
                    showingNewClientSheet: $showingNewClientSheet
                )
            }
            .sheet(isPresented: $showingNewClientSheet) {
                NewClientView(
                    isPresented: $showingNewClientSheet,
                    onSave: { newClient in
                        selectedClient = newClient
                        clientName = newClient.name
                    }
                )
            }
            .sheet(isPresented: $showingTeamSelector) {
                TeamMemberSelectorView(
                    isPresented: $showingTeamSelector,
                    teamMembers: $teamMembers,
                    availableUsers: userAdminViewModel.users
                )
            }
            .onAppear {
                // Cargar usuarios al aparecer la vista
                userAdminViewModel.loadUsers()
            }
        }
    }
}

struct TeamMemberSelectorView: View {
    @Binding var isPresented: Bool
    @Binding var teamMembers: [String]
    let availableUsers: [AdminUser]
    @State private var searchText = ""
    @State private var selectedUsers: Set<String> = []
    
    var filteredUsers: [AdminUser] {
        if searchText.isEmpty {
            return availableUsers.filter { !teamMembers.contains($0.fullName) }
        } else {
            return availableUsers.filter { user in
                !teamMembers.contains(user.fullName) &&
                user.fullName.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Barra de búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Buscar usuario", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Botón de seleccionar todos
                if !filteredUsers.isEmpty {
                    Button(action: {
                        if selectedUsers.count == filteredUsers.count {
                            selectedUsers.removeAll()
                        } else {
                            selectedUsers = Set(filteredUsers.map { $0.fullName })
                        }
                    }) {
                        HStack {
                            Image(systemName: selectedUsers.count == filteredUsers.count ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedUsers.count == filteredUsers.count ? .blue : .gray)
                            
                            Text(selectedUsers.count == filteredUsers.count ? "Deseleccionar todos" : "Seleccionar todos")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Lista de usuarios disponibles
                List {
                    ForEach(filteredUsers, id: \.id) { user in
                        Button(action: {
                            if selectedUsers.contains(user.fullName) {
                                selectedUsers.remove(user.fullName)
                            } else {
                                selectedUsers.insert(user.fullName)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedUsers.contains(user.fullName) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedUsers.contains(user.fullName) ? .blue : .gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.fullName)
                                        .foregroundColor(.primary)
                                    
                                    Text(user.role)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    
                    if filteredUsers.isEmpty {
                        Text("No hay usuarios disponibles")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // Barra de acciones
                if !selectedUsers.isEmpty {
                    HStack {
                        Button(action: {
                            selectedUsers.removeAll()
                        }) {
                            Text("Limpiar selección")
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            teamMembers.append(contentsOf: selectedUsers)
                            isPresented = false
                        }) {
                            Text("Añadir \(selectedUsers.count) miembros")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, y: -2)
                }
            }
            .navigationTitle("Seleccionar Miembros")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    isPresented = false
                }
            )
        }
    }
}

struct ClientSelectorView: View {
    @Binding var selectedClient: Client?
    @Binding var clientName: String
    @Binding var showingNewClientSheet: Bool
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var clientManager = ClientManager.shared
    @State private var searchText = ""
    @State private var showingManualEntry = false
    @State private var manualClientName = ""
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clientManager.getActiveClients()
        } else {
            return clientManager.getActiveClients().filter { client in
                client.name.lowercased().contains(searchText.lowercased()) ||
                client.contactPerson.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Buscar cliente", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Lista de clientes
                List {
                    Section(header: Text("Clientes existentes")) {
                        ForEach(filteredClients) { client in
                            Button(action: {
                                selectedClient = client
                                clientName = client.name
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(client.name)
                                            .font(.headline)
                                        
                                        if !client.contactPerson.isEmpty {
                                            Text(client.contactPerson)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if client.id == selectedClient?.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                        
                        if filteredClients.isEmpty {
                            Text("No se encontraron resultados")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    Section {
                        if showingManualEntry {
                            HStack {
                                TextField("Nombre del cliente", text: $manualClientName)
                                
                                Button(action: {
                                    if !manualClientName.isEmpty {
                                        clientName = manualClientName
                                        selectedClient = nil
                                        dismiss()
                                    }
                                }) {
                                    Text("Usar")
                                        .foregroundColor(.blue)
                                }
                            }
                        } else {
                            Button(action: {
                                showingManualEntry = true
                            }) {
                                HStack {
                                    Image(systemName: "keyboard")
                                    Text("Ingresar cliente manualmente")
                                }
                            }
                        }
                        
                        Button(action: {
                            showingNewClientSheet = true
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("Crear nuevo cliente")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Seleccionar Cliente")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    dismiss()
                }
            )
        }
    }
}

// Componentes separados para ProjectDetailView
struct ProjectHeaderView: View {
    let project: Project
    
    func healthColor(health: Double) -> Color {
        if health >= 0.7 {
            return .green
        } else if health >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    func healthStatusIcon(health: Double) -> String {
        if health >= 0.7 {
            return "checkmark.circle.fill"
        } else if health >= 0.4 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
                VStack(spacing: 8) {
                    Text(project.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(project.client)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        HStack(spacing: 4) {
                            Image(systemName: healthStatusIcon(health: project.health))
                                .foregroundColor(healthColor(health: project.health))
                            
                            Text("\(Int(project.health * 100))%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(healthColor(health: project.health))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(healthColor(health: project.health).opacity(0.2))
                        .cornerRadius(20)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ProjectHealthView: View {
    let project: Project
    
    func healthColor(health: Double) -> Color {
        if health >= 0.7 {
            return .green
        } else if health >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    func healthStatusIcon(health: Double) -> String {
        if health >= 0.7 {
            return "checkmark.circle.fill"
        } else if health >= 0.4 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    func healthStatusDescription(health: Double) -> String {
        if health >= 0.7 {
            return "El sistema está funcionando correctamente."
        } else if health >= 0.4 {
            return "El sistema tiene algunos problemas que requieren atención."
        } else {
            return "El sistema está en estado crítico. Muchos equipos están fuera de servicio."
        }
    }
    
    var body: some View {
                VStack(spacing: 12) {
                    HStack {
                        Text("Salud del Sistema")
                            .font(.headline)
                            .bold()
                        
                        Spacer()
                        
                        Text("\(Int(project.health * 100))%")
                            .font(.headline)
                            .bold()
                            .foregroundColor(healthColor(health: project.health))
                    }
                    
                    // Barra de salud del sistema vertical
                    VStack(spacing: 5) {
                        Text("Salud del sistema")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: project.health, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: healthColor(health: project.health)))
                        .frame(height: 8)
                        
                        // Añadir una explicación del estado
                        HStack(spacing: 10) {
                            Image(systemName: healthStatusIcon(health: project.health))
                                .foregroundColor(healthColor(health: project.health))
                            
                            Text(healthStatusDescription(health: project.health))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
                }
                
struct ProjectInfoView: View {
    let project: Project
    
    var body: some View {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Información")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(alignment: .top) {
                            Image(systemName: "calendar")
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fechas")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                        Text("Inicio: \(project.startDate)")
                            .font(.body)
                        
                        Text("Fin: \(project.deadline)")
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
                
struct ProjectDescriptionView: View {
    let project: Project
    
    var body: some View {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Descripción")
                        .font(.headline)
                    
                    Text(project.description)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ProjectPointsListView: View {
    let project: Project
    @Binding var showingPointsSheet: Bool
    @Binding var isAddingPoint: Bool
    @Binding var isLoadingPoints: Bool
    
    var body: some View {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Puntos")
                            .font(.headline)
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            Button(action: {
                                showingPointsSheet = true
                            }) {
                                Label("Ver todos", systemImage: "list.bullet")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                isAddingPoint = true
                            }) {
                                Label("Añadir", systemImage: "plus.circle")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
            if isLoadingPoints {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else {
                let projectPoints = ProjectManager.shared.getProjectPoints(projectId: project.id)
                if projectPoints.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No hay puntos para este proyecto")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        // Contador y estadísticas rápidas
                        HStack(spacing: 12) {
                        let totalPoints = projectPoints.count
                        let pointsByType = Dictionary(grouping: projectPoints, by: { $0.type })
                                .mapValues { $0.count }
                            
                            Text("\(totalPoints) puntos en total")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let mostCommonType = pointsByType.max(by: { $0.value < $1.value })?.key {
                                HStack(spacing: 4) {
                                    Image(systemName: mostCommonType.icon)
                                        .foregroundColor(mostCommonType.color)
                                    
                                    Text("\(pointsByType[mostCommonType] ?? 0) \(mostCommonType.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Vista de tabla optimizada
                        VStack(spacing: 2) {
                            // Cabecera de la tabla
                            HStack {
                                Text("Nombre")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 120, alignment: .leading)
                                
                                Text("Tipo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                
                                Text("Ciudad")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 100, alignment: .leading)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            // Lista de puntos (limitada a 5)
                        ForEach(projectPoints.prefix(5), id: \.id) { point in
                                NavigationLink(destination: PointDetailView(point: point, projectId: project.id)) {
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: point.type.icon)
                                                .foregroundColor(point.type.color)
                                                .frame(width: 20)
                                            
                                            Text(point.name)
                                                .lineLimit(1)
                                                .font(.subheadline)
                                        }
                                        .frame(width: 120, alignment: .leading)
                                        
                                        Text(point.type.rawValue)
                                            .font(.caption)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        Text(point.city)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 100, alignment: .leading)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Botón para ver más si hay más de 5 puntos
                        if projectPoints.count > 5 {
                                Button(action: {
                                    showingPointsSheet = true
                                }) {
                                    HStack {
                                        Spacer()
                                        
                                    Text("Ver \(projectPoints.count - 5) más...")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6).opacity(0.5))
                                    .cornerRadius(8)
                            }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ProjectTeamView: View {
    let project: Project
    @Binding var showingTeamSheet: Bool
    
    var body: some View {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Equipo")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingTeamSheet = true
                        }) {
                            Text("Ver todos")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if project.team.isEmpty {
                        Text("No hay miembros asignados a este proyecto")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(project.team.prefix(5), id: \.self) { member in
                                    VStack {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.blue)
                                        
                                        Text(member)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 70)
                                }
                                
                                if project.team.count > 5 {
                                    VStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 40, height: 40)
                                            
                                            Text("+\(project.team.count - 5)")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text("Más")
                                            .font(.caption)
                                    }
                                    .frame(width: 70)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ProjectTasksView: View {
    let project: Project
    @Binding var isAddingTask: Bool
    
    var body: some View {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Tareas")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            isAddingTask = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if project.tasks.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "checklist")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No hay tareas para este proyecto")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                isAddingTask = true
                            }) {
                                Text("Añadir tarea")
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(project.tasks) { task in
                            TaskRow(task: task)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ProjectMaterialsSectionView: View {
    let project: Project
    @Binding var showingMaterialsSheet: Bool
    
    var body: some View {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Materiales")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingMaterialsSheet = true
                        }) {
                            Label("Gestionar", systemImage: "shippingbox")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack(spacing: 15) {
                        // Resumen de materiales
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "cube.box")
                                    .foregroundColor(.blue)
                                
                                Text("Gestiona los materiales asignados a este proyecto")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Puedes asignar nuevos materiales, registrar su uso o devolución, y llevar un registro detallado de todos los movimientos.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Ahora actualizo ProjectDetailView para usar estos componentes
struct ProjectDetailView: View {
    var project: Project
    
    @State private var isAddingTask = false
    @State private var isAddingPoint = false
    @State private var showingTeamSheet = false
    @State private var showingPointsSheet = false
    @State private var showingMaterialsSheet = false
    @State private var isLoadingPoints = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cabecera
                ProjectHeaderView(project: project)
                
                // Salud del proyecto
                ProjectHealthView(project: project)
                
                // Información del proyecto
                ProjectInfoView(project: project)
                
                // Descripción
                ProjectDescriptionView(project: project)
                
                // Puntos
                ProjectPointsListView(
                    project: project,
                    showingPointsSheet: $showingPointsSheet,
                    isAddingPoint: $isAddingPoint,
                    isLoadingPoints: $isLoadingPoints
                )
                
                // Equipo
                ProjectTeamView(
                    project: project,
                    showingTeamSheet: $showingTeamSheet
                )
                
                // Tareas
                ProjectTasksView(
                    project: project,
                    isAddingTask: $isAddingTask
                )
                
                // Materiales
                ProjectMaterialsSectionView(
                    project: project,
                    showingMaterialsSheet: $showingMaterialsSheet
                )
            }
            .padding()
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationTitle("Detalle del proyecto")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingTask) {
            Text("Vista para añadir tarea")
        }
        .sheet(isPresented: $isAddingPoint) {
            AddPointView(isPresented: $isAddingPoint, project: project)
        }
        .sheet(isPresented: $showingTeamSheet) {
            TeamSheetView(team: project.team)
        }
        .sheet(isPresented: $showingPointsSheet) {
            ProjectPointsView(points: ProjectManager.shared.getProjectPoints(projectId: project.id), project: project)
        }
        .sheet(isPresented: $showingMaterialsSheet) {
            ProjectMaterialsView(projectId: project.id, projectName: project.name)
        }
        .onAppear {
            loadProjectPoints()
        }
    }
    
    private func loadProjectPoints() {
        isLoadingPoints = true
        ProjectManager.shared.loadProjectPoints(projectId: project.id)
        // La carga es asíncrona, así que desactivamos el indicador después de un tiempo razonable
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoadingPoints = false
        }
    }
}

struct TaskRow: View {
    var task: ProjectTask
    
    var statusColor: Color {
        switch task.status {
        case "Completada":
            return .green
        case "En desarrollo":
            return .blue
        case "Pendiente":
            return .orange
        default:
            return .gray
        }
    }
    
    var priorityColor: Color {
        switch task.priority {
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
        HStack(alignment: .top, spacing: 15) {
            // Indicador de estado
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                // Título y prioridad
                HStack {
                    Text(task.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(task.priority)
                        .font(.caption)
                        .foregroundColor(priorityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // Descripción
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Detalles
                HStack {
                    if let assignedTo = task.assignedTo {
                        HStack(spacing: 4) {
                            Image(systemName: "person")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(assignedTo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(dueDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TeamSheetView: View {
    var team: [String]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(team, id: \.self) { member in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text(member)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Equipo del proyecto")
            .navigationBarItems(trailing: Button("Cerrar") {
                dismiss()
            })
        }
    }
}
struct ProjectPointsView: View {
    var points: [ProjectPoint]
    var project: Project
    @State private var searchText = ""
    @State private var selectedFilter: ProjectPoint.PointType? = nil
    
    @ObservedObject private var projectManager = ProjectManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                // Barra de filtros
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filtrar por tipo:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                label: "Todos",
                                isSelected: selectedFilter == nil,
                                action: { selectedFilter = nil }
                            )
                            
                            ForEach(ProjectPoint.PointType.allCases) { type in
                                FilterChip(
                                    label: type.rawValue, 
                                    icon: type.icon, 
                                    color: type.color,
                                    isSelected: selectedFilter == type,
                                    action: { selectedFilter = type }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                    .scrollIndicators(.hidden)
                    .background(Color(.systemBackground))
                    .frame(height: 52)
                }
                .padding(.vertical, 4)
                
                // Lista de puntos filtrada
                let filteredPoints = projectManager.getProjectPoints(projectId: project.id)
                    .filter { point in
                        (searchText.isEmpty || point.name.localizedCaseInsensitiveContains(searchText) || point.city.localizedCaseInsensitiveContains(searchText)) &&
                        (selectedFilter == nil || point.type == selectedFilter)
                    }
                
                if filteredPoints.isEmpty {
                    ContentUnavailableView(
                        label: {
                            Label(
                                "No hay puntos",
                                systemImage: "mappin.slash"
                            )
                        },
                        description: {
                            Text(searchText.isEmpty ? "No hay puntos que coincidan con el filtro seleccionado." : "No hay resultados para '\(searchText)'")
                        }
                    )
                    .padding()
                } else {
                    List {
                            ForEach(filteredPoints) { point in
                                NavigationLink(destination: PointDetailView(point: point, projectId: project.id)) {
                                PointRowView(point: point)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Puntos del proyecto")
            .searchable(text: $searchText, prompt: "Buscar punto por nombre o ciudad")
            .refreshable {
                // Recargar los puntos del proyecto
                projectManager.loadProjectPoints(projectId: project.id)
            }
        }
    }
}

struct FilterChip: View {
    let label: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    init(label: String, icon: String? = nil, color: Color = .blue, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .frame(width: 16, height: 16)
                }
                
                Text(label)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

// Componentes para dividir la vista PointDetailView
struct PointMapView: View {
    let point: ProjectPoint
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
                ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition) {
                Marker("Ubicación", coordinate: point.location.coordinate)
                    .tint(.red)
            }
            .onAppear {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: point.location.coordinate,
                    distance: 000, // 6km de distancia
                    heading: 0,
                    pitch: 0
                ))
            }
                        .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack {
                        HStack {
                            Text("Coordenadas:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "%.4f, %.4f", point.location.latitude, point.location.longitude))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(8)
                        .padding(8)
            }
        }
    }
}

struct PointOperationalStatusView: View {
    let point: ProjectPoint
    let projectId: String
    @Binding var selectedStatus: ProjectPoint.OperationalStatus
    @ObservedObject var projectManager: ProjectManager
    
    func stateDescription(for status: ProjectPoint.OperationalStatus) -> String {
        switch status {
        case .operational:
            return "El dispositivo está funcionando correctamente y todos los sistemas están en línea."
        case .issues:
            return "El dispositivo presenta algunos problemas pero sigue funcionando parcialmente. Se recomienda revisión."
        case .offline:
            return "El dispositivo está fuera de servicio. Se requiere reparación o reemplazo inmediato."
        }
    }
    
    var body: some View {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Estado operativo")
                        .font(.headline)
                    
                    Picker("Estado", selection: $selectedStatus) {
                ForEach(ProjectPoint.OperationalStatus.allCases, id: \.self) { status in
                            HStack {
                                Image(systemName: status.icon)
                                Text(status.rawValue)
                            }
                            .foregroundColor(status.color)
                            .tag(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedStatus) { _, newValue in
                        // Actualizar el estado del punto en el proyecto
                        projectManager.updatePointStatus(projectId: projectId, pointId: point.id, status: newValue)
                    }
                    
                    // Información del estado
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: selectedStatus.icon)
                                .foregroundColor(selectedStatus.color)
                            
                            Text(selectedStatus.rawValue)
                                .foregroundColor(selectedStatus.color)
                                .fontWeight(.semibold)
                        }
                        
                        Text(stateDescription(for: selectedStatus))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedStatus.color.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}
                
struct PointInfoView: View {
    let point: ProjectPoint
    
    var body: some View {
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
                            
                            Text(point.type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(point.type.color)
                        }
                    }
                    
                    Divider()
                    
                    // Detalles
                    Group {
                        ProjectDetailRow(icon: "building.2", title: "Ciudad", value: point.city)
                        
                        ProjectDetailRow(icon: "mappin.circle", title: "Dirección", value: point.location.address ?? "Sin dirección")
                        
                        ProjectDetailRow(icon: "shippingbox", title: "Material", value: point.materialName ?? "Sin material")
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct PointDetailView: View {
    let point: ProjectPoint
    let projectId: String
    @StateObject private var projectManager = ProjectManager.shared
    @State private var selectedStatus: ProjectPoint.OperationalStatus
    
    init(point: ProjectPoint, projectId: String) {
        self.point = point
        self.projectId = projectId
        _selectedStatus = State(initialValue: point.operationalStatus)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mapa
                PointMapView(point: point)
                
                // Estado operativo
                PointOperationalStatusView(
                    point: point,
                    projectId: projectId, 
                    selectedStatus: $selectedStatus,
                    projectManager: projectManager
                )
                
                // Información del punto
                PointInfoView(point: point)
            }
            .padding()
        }
        .navigationTitle("Detalle del Punto")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}

struct ProjectDetailRow: View {
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

struct AddPointView: View {
    @Binding var isPresented: Bool
    var project: Project
    
    @State private var pointName = ""
    @State private var selectedType = ProjectPoint.PointType.CCTV
    @State private var city = ""
    @State private var selectedCoordinates: (Double, Double)? = nil
    @State private var address = ""
    @State private var materialName: String? = nil
    @State private var showingMapSelection = false
    @State private var showingMaterialSelection = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    
    private var isFormValid: Bool {
        !pointName.isEmpty && !city.isEmpty && selectedCoordinates != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información básica")) {
                    TextField("Nombre del punto", text: $pointName)
                        .autocapitalization(.words)
                    
                    Picker("Tipo de punto", selection: $selectedType) {
                        ForEach(ProjectPoint.PointType.allCases) { type in
                            Label {
                                Text(type.rawValue)
                            } icon: {
                                Image(systemName: type.icon)
                                .foregroundColor(type.color)
                            }
                                .tag(type)
                        }
                    }
                    
                    TextField("Ciudad", text: $city)
                        .autocapitalization(.words)
                }
                
                Section(header: Text("Ubicación")) {
                    if let coordinates = selectedCoordinates {
                    Button(action: {
                            showingMapSelection = true
                    }) {
                        HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(address.isEmpty ? "Ubicación seleccionada" : address)
                                        .foregroundColor(address.isEmpty ? .secondary : .primary)
                                        .lineLimit(1)
                                    
                                    Text(String(format: "Lat: %.4f, Long: %.4f", coordinates.0, coordinates.1))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    }
                                }
                            } else {
                        Button("Seleccionar ubicación") {
                            showingMapSelection = true
                        }
                    }
                }
                
                Section(header: Text("Material")) {
                    if let material = materialName {
                    Button(action: {
                            showingMaterialSelection = true
                    }) {
                        HStack {
                                VStack(alignment: .leading) {
                                    Text(material)
                            }
                            
                            Spacer()
                    
                    Button(action: {
                                    materialName = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    } else {
                        Button("Seleccionar material") {
                            showingMaterialSelection = true
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Nuevo punto")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    isPresented = false
                },
                trailing: Button("Guardar") {
                    savePoint()
                }
                .disabled(!isFormValid || isSaving)
            )
            .sheet(isPresented: $showingMapSelection) {
                MapSelectionView(selectedCoordinates: $selectedCoordinates, address: $address)
            }
            .sheet(isPresented: $showingMaterialSelection) {
                MaterialSelectionView(selectedMaterial: $materialName, onMaterialSelected: { material in
                    materialName = material
                    showingMaterialSelection = false
                })
            }
            .overlay(
                Group {
                    if isSaving {
                        VStack {
                            ProgressView("Guardando...")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            )
        }
    }
    
    private func savePoint() {
        guard let coordinates = selectedCoordinates else {
            errorMessage = "Por favor selecciona una ubicación"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        // Crear un nuevo punto con los datos del formulario
                        let newPoint = ProjectPoint(
            name: pointName,
                            type: selectedType,
                            location: ProjectPoint.Location(
                latitude: coordinates.0,
                longitude: coordinates.1,
                address: address.isEmpty ? nil : address
            ),
            city: city,
                            materialName: materialName
                        )
                        
        // Guardar el punto utilizando el ProjectManager
        ProjectManager.shared.addPointToProject(projectId: project.id, point: newPoint)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isSaving = false
                    
                    switch completion {
                    case .finished:
                        // Cerrar la vista después de guardar exitosamente
                    isPresented = false
                    case .failure(let error):
                        // Mostrar error al usuario
                        errorMessage = "Error al guardar: \(error.localizedDescription)"
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &ProjectManager.shared.cancellables)
    }
}

// Vista simplificada para seleccionar material (demo)
struct MaterialSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedMaterial: String?
    var onMaterialSelected: ((String) -> Void)? = nil
    @State private var searchText = ""
    
    let demoMaterials = [
        "Cámara Hikvision DS-2CD2143G0-I",
        "Cámara Dahua IPC-HDW5442TM-AS",
        "Radio Ubiquiti NBE-5AC-Gen2",
        "Switch PoE TP-Link TL-SG1016PE",
        "Cable UTP CAT6 Exterior",
        "Fuente de alimentación 48V",
        "Gabinete exterior IP65"
    ]
    
    var filteredMaterials: [String] {
        if searchText.isEmpty {
            return demoMaterials
        } else {
            return demoMaterials.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredMaterials, id: \.self) { material in
                    Button(action: {
                        selectedMaterial = material
                        if let onSelected = onMaterialSelected {
                            onSelected(material)
                        } else {
                        dismiss()
                        }
                    }) {
                        Text(material)
                    }
                }
            }
            .navigationTitle("Seleccionar Material")
            .searchable(text: $searchText, prompt: "Buscar material")
            .navigationBarItems(trailing: Button("Cancelar") {
                dismiss()
            })
        }
    }
}

// Vista simplificada para crear nuevo material (demo)
struct NewMaterialView: View {
    @Binding var isPresented: Bool
    var onSave: (String) -> Void
    
    @State private var materialName = ""
    @State private var quantity = 1
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Material")) {
                    TextField("Nombre del material", text: $materialName)
                    Stepper("Cantidad: \(quantity)", value: $quantity, in: 1...100)
                    TextField("Descripción", text: $description)
                }
            }
            .navigationTitle("Nuevo Material")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    isPresented = false
                },
                trailing: Button("Guardar") {
                    onSave(materialName)
                    isPresented = false
                }
                .disabled(materialName.isEmpty)
            )
        }
    }
}

// Estructura para la respuesta del API al crear un punto
struct PointResponse: Codable {
    var ok: Bool
    var data: PointData
}

// Respuesta para una lista de puntos
struct PointsResponse: Codable {
    var ok: Bool
    var data: [PointData]
}

// Estructura para representar un punto recuperado de la API
struct PointData: Codable {
    var id: String
    var name: String
    var type: String
    var location: LocationData
    var city: String
    var material: [String]
    var operational: Bool
    var project: String
    var createdBy: CreatedByData?
    var createdAt: String?
    var updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case type
        case location
        case city
        case material
        case operational
        case project
        case createdBy
        case createdAt
        case updatedAt
    }
    
    // Propiedades computadas para facilitar acceso a latitud y longitud
    var latitude: Double {
        return location.latitude
    }
    
    var longitude: Double {
        return location.longitude
    }
}

// Estructura para manejar el creador del punto
struct CreatedByData: Codable {
    var id: String
    var fullName: String
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fullName
        case name
    }
}

// Estructura para manejar la localización en formato GeoJSON
struct LocationData: Codable {
    let type: String
    let coordinates: [Double]
    
    var longitude: Double {
        return coordinates[0]
    }
    
    var latitude: Double {
        return coordinates[1]
    }
}

// Servicio para operaciones con puntos
class PointService {
    static let shared = PointService()
    private let apiClient = APIClient.shared
    private init() {}
    
    func createPoint(projectId: String, point: ProjectPoint) -> AnyPublisher<PointData, APIError> {
        print("📍 Enviando punto al servidor: \(point.name)")
        
        // Crear el diccionario con los datos a enviar
        let pointDict: [String: Any] = [
            "name": point.name,
            "type": point.type.rawValue,
            "latitude": point.location.latitude,
            "longitude": point.location.longitude,
            "city": point.city,
            "material": point.materialName != nil ? [point.materialName!] : [],
            "operational": true
        ]
        
        // Realizar la petición POST - Se corrige la ruta para usar la correcta en el backend
        return apiClient.request(
            .post, 
            path: "/points/project/\(projectId)",
            body: pointDict
        )
        .map { (response: PointResponse) -> PointData in
            print("✅ Punto creado exitosamente en el servidor: \(response.data.id)")
            return response.data
        }
        .eraseToAnyPublisher()
    }
    
    func loadProjectPoints(projectId: String) -> AnyPublisher<[PointData], APIError> {
        print("🔍 Cargando puntos para el proyecto: \(projectId)")
        
        return apiClient.request(
            .get,
            path: "/points/project/\(projectId)"
        )
        .map { (response: PointsResponse) -> [PointData] in
            print("✅ Puntos cargados correctamente: \(response.data.count) puntos")
            return response.data
        }
        .eraseToAnyPublisher()
    }
}

// Clase para gestionar los proyectos y sus puntos
class ProjectManager: ObservableObject {
    static let shared = ProjectManager()
    
    @Published var projects: [Project] = []
    @Published var projectPoints: [String: [ProjectPoint]] = [:] // Mapa de puntos por ID de proyecto
    private let pointService = PointService.shared
    var cancellables = Set<AnyCancellable>() // Cambiado de private a public para poder usarlo en savePoint
    
    private init() {
        // Inicializar con los proyectos actuales en un escenario real
        // Esto sería cargado desde una base de datos o API
    }
    
    func addPointToProject(projectId: String, point: ProjectPoint) -> AnyPublisher<PointData, APIError> {
        // En una aplicación real, esto actualizaría el modelo y la base de datos
        print("Añadiendo punto '\(point.name)' al proyecto '\(projectId)'")
        
        // Enviar al backend
        return pointService.createPoint(projectId: projectId, point: point)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] pointData in
                guard let self = self else { return }
                print("✅ Punto guardado en el servidor: \(pointData.id)")
                
                // Crear el nuevo punto con el ID recibido del servidor
                let serverPoint = ProjectPoint(
                    id: pointData.id,
                    name: pointData.name,
                    type: ProjectPoint.PointType(rawValue: pointData.type) ?? .UNKNOWN,
                    location: ProjectPoint.Location(
                        latitude: pointData.latitude,
                        longitude: pointData.longitude,
                        address: nil // No tenemos dirección del servidor
                    ),
                    city: pointData.city,
                    materialName: pointData.material.first
                )
                
                // Añadir punto a la colección local con el ID del servidor
                var currentPoints = self.projectPoints[projectId] ?? []
                currentPoints.append(serverPoint)
                self.projectPoints[projectId] = currentPoints
        
        // Actualizar la salud del proyecto
                self.updateProjectHealth(projectId: projectId)
            })
            .eraseToAnyPublisher()
    }
    
    func updatePointStatus(projectId: String, pointId: String, status: ProjectPoint.OperationalStatus) {
        // Actualizar el estado operativo de un punto específico
        guard var points = projectPoints[projectId] else { return }
        
        if let index = points.firstIndex(where: { $0.id == pointId }) {
            points[index].operationalStatus = status
            projectPoints[projectId] = points
            
            // Actualizar la salud del proyecto
            updateProjectHealth(projectId: projectId)
        }
    }
    
    func updateProjectHealth(projectId: String) {
        // Calcular la salud del proyecto basada en el estado operativo de los puntos
        guard let points = projectPoints[projectId], !points.isEmpty else { return }
        
        // Contar puntos por estado
        var operationalCount = 0
        var issuesCount = 0
        var offlineCount = 0
        
        for point in points {
            switch point.operationalStatus {
            case .operational:
                operationalCount += 1
            case .issues:
                issuesCount += 1
            case .offline:
                offlineCount += 1
            }
        }
        
        // Calcular health - simple: operativos / total
        let totalPoints = points.count
        let healthValue = Double(operationalCount) / Double(totalPoints)
        
        // Encontrar y actualizar el proyecto
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            projects[index].health = healthValue
        }
    }
    
    func getProjectPoints(projectId: String) -> [ProjectPoint] {
        return projectPoints[projectId] ?? []
    }
    
    func loadProjectPoints(projectId: String) {
        print("Cargando puntos para el proyecto: \(projectId)")
        
        pointService.loadProjectPoints(projectId: projectId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Carga de puntos completada")
                    case .failure(let error):
                        print("❌ Error al cargar puntos: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] pointsData in
                    guard let self = self else { return }
                    
                    let points = pointsData.map { pointData -> ProjectPoint in
                        return ProjectPoint(
                            id: pointData.id,
                            name: pointData.name,
                            type: ProjectPoint.PointType(rawValue: pointData.type) ?? .UNKNOWN,
                            location: ProjectPoint.Location(
                                latitude: pointData.location.latitude,
                                longitude: pointData.location.longitude,
                                address: nil
                            ),
                            city: pointData.city,
                            materialName: pointData.material.first,
                            material: nil,
                            operationalStatus: pointData.operational ? .operational : .offline
                        )
                    }
                    
                    self.projectPoints[projectId] = points
                    
                    // Actualizar la salud del proyecto según el estado de los puntos
                    self.updateProjectHealth(projectId: projectId)
                    
                    // Actualizar la lista de puntos en el proyecto si existe
                    if let index = self.projects.firstIndex(where: { $0.id == projectId }) {
                        self.projects[index].points = points
                    }
                }
            )
            .store(in: &cancellables)
    }
}

struct MapSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCoordinates: (Double, Double)?
    @Binding var address: String
    
    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var position: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 25.5428, longitude: -103.4068),
        distance: 6000, // 6 km de distancia
        heading: 0,
        pitch: 0
    ))
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedMapItem: MKMapItem?
    @State private var userSelectedLocation: CLLocationCoordinate2D?
    @State private var showPinLocationButton = true
    
    // Extrayendo la vista del mapa a una función separada para simplificar
    private var mapView: some View {
                        Map(position: $position, selection: $selectedMapItem) {
                            // Marcador para la ubicación de Torreón (punto de referencia)
                            Marker("Torreón", coordinate: CLLocationCoordinate2D(latitude: 25.5428, longitude: -103.4068))
                                .tint(.blue)
                            
                            // Marcadores para los resultados de búsqueda
                            ForEach(searchResults, id: \.self) { result in
                                Marker(item: result)
                                    .tint(.red)
                            }
                            
                            // Marcador para la ubicación seleccionada por el usuario
                            if let location = userSelectedLocation, selectedMapItem == nil {
                                Marker("Ubicación seleccionada", coordinate: location)
                                    .tint(.green)
                            }
                        }
                        .mapStyle(.standard)
                        .onAppear {
                            // Configurar el zoom inicial a 6 km
                            position = .camera(MapCamera(
                                centerCoordinate: CLLocationCoordinate2D(latitude: 25.5428, longitude: -103.4068),
                                distance: 6000, // 6 km de distancia
                                heading: 0,
                                pitch: 0
                            ))
                        }
                        .onMapCameraChange { context in
                            self.visibleRegion = context.region
                        }
                        .onChange(of: selectedMapItem) { _, newSelection in
                            if let mapItem = newSelection {
                                // Borrar la ubicación seleccionada manualmente al seleccionar un resultado de búsqueda
                                userSelectedLocation = nil
                                
                                let location = mapItem.placemark.coordinate
                                selectedCoordinates = (location.latitude, location.longitude)
                                
                                let addressParts = [
                                    mapItem.placemark.thoroughfare,
                                    mapItem.placemark.locality,
                                    mapItem.placemark.administrativeArea,
                                    mapItem.placemark.country
                                ].compactMap { $0 }
                                
                                address = addressParts.joined(separator: ", ")
                            }
                        }
    }
    
    // Extrayendo el panel de acciones a una función separada
    private var actionsPanel: some View {
                    VStack(spacing: 12) {
                        if let coordinates = selectedCoordinates {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ubicación seleccionada")
                                    .font(.headline)
                                
                                if !address.isEmpty {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(String(format: "Lat: %.4f, Long: %.4f", coordinates.0, coordinates.1))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Usar esta ubicación")
                                    .fontWeight(.medium)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        } else {
                            Text("Busca una ubicación o utiliza el botón 'Ubicar aquí'")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        
                        Button("Cancelar") {
                            dismiss()
                        }
                        .padding(.vertical, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
                
    // Extrayendo el botón de ubicación a una función separada
    private var locationButton: some View {
                Button(action: {
                    if let region = visibleRegion {
                        setLocationFromCenter(region: region)
                    }
                }) {
                    Text("Ubicar aquí")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 2)
                }
                .padding()
    }
    
    // Función para establecer la ubicación desde el centro del mapa
    private func setLocationFromCenter(region: MKCoordinateRegion) {
        let center = region.center
        userSelectedLocation = center
        selectedCoordinates = (center.latitude, center.longitude)
        
        // En una aplicación real, aquí realizaríamos una geocodificación inversa
        // para obtener la dirección a partir de las coordenadas
        // Por ahora, establecemos una dirección genérica
        address = "Dirección aproximada en \(String(format: "%.4f, %.4f", center.latitude, center.longitude))"
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    ZStack {
                        mapView
                        
                        // Indicador del centro del mapa (crosshair)
                        if showPinLocationButton {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 40, height: 40)
                                )
                        }
                    }
                    
                    // Panel de acciones
                    actionsPanel
                }
                
                // Botón para fijar la ubicación en el centro del mapa
                locationButton
            }
            .navigationTitle("Seleccionar ubicación")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    dismiss()
                },
                trailing: Button("Limpiar") {
                    selectedCoordinates = nil
                    userSelectedLocation = nil
                    selectedMapItem = nil
                    address = ""
                }
                .disabled(selectedCoordinates == nil)
            )
            .searchable(text: $searchQuery, prompt: "Buscar ubicación")
            // Aquí iría la lógica de búsqueda en una aplicación real
        }
    }
}

// También vamos a actualizar esta vista para hacerla funcional
struct SearchLocationView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var searchText: String
    @Binding var searchResults: [MKMapItem]
    var onSelect: (MKMapItem) -> Void
    
    var body: some View {
        List {
            ForEach(searchResults, id: \.self) { item in
                Button(action: {
                    onSelect(item)
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name ?? "Ubicación sin nombre")
                            .font(.headline)
                        
                        if let placemark = item.placemark.title {
                            Text(placemark)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if searchResults.isEmpty {
                Text("No se encontraron resultados")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .searchable(text: $searchText, prompt: "Buscar ubicación")
        .navigationTitle("Buscar ubicación")
    }
}

struct PointRowView: View {
    var point: ProjectPoint
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: point.type.icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(point.type.color)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(point.name)
                    .font(.headline)
                
                Text(point.city)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(point.type.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(point.type.color.opacity(0.2))
                .foregroundColor(point.type.color)
                .cornerRadius(4)
        }
    }
}

