import SwiftUI
import Combine

struct ClientsManagementView: View {
    @StateObject private var clientManager = ClientManager.shared
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var showingAddClientSheet = false
    @State private var selectedClient: Client? = nil
    @State private var showingDeleteConfirmation = false
    @State private var selectedStatusFilter: StatusFilter = .all
    
    // Estado para el debounce de la búsqueda
    @State private var debouncedSearchText = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    // Enum para filtrado por estado
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "Todos"
        case active = "Activos"
        case inactive = "Inactivos"
        
        var id: String { self.rawValue }
        
        var value: Bool? {
            switch self {
            case .all: return nil
            case .active: return true
            case .inactive: return false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Encabezado personalizado
            headerView
            
            // Contenido principal
            clientsContentView
                .navigationTitle("Gestión de Clientes")
        }
        .sheet(isPresented: $showingAddClientSheet) {
            ClientFormView(
                isPresented: $showingAddClientSheet,
                clientToEdit: nil,
                onSave: { addClient($0) }
            )
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
            .presentationCornerRadius(20)
            .presentationSizing(.form)
        }
        .sheet(item: $selectedClient) { client in
            ClientFormView(
                isPresented: .constant(true),
                clientToEdit: client,
                onSave: { updateClient($0); selectedClient = nil },
                onCancel: { selectedClient = nil }
            )
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
            .presentationCornerRadius(20)
            .presentationSizing(.form)
        }
        .alert("¿Eliminar cliente?", isPresented: $showingDeleteConfirmation, presenting: selectedClient) { client in
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                deleteClient(client.id)
            }
        } message: { client in
            Text("Esta acción eliminará permanentemente al cliente '\(client.name)' y no se puede deshacer.")
        }
        .onAppear {
            // Limpiar búsqueda y filtros al aparecer
            searchText = ""
            selectedStatusFilter = .all
            refreshClients()
        }
    }
    
    // Encabezado personalizado
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cerrar") {
                    isPresented = false
                }
                
                Spacer()
                
                Text("Gestión de Clientes")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingAddClientSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            // Barra de búsqueda y filtros
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Buscar cliente", text: $searchText)
                        .onChange(of: searchText) { _, newValue in
                            performDebouncedSearch(newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            applyFilters()
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
                    ForEach(StatusFilter.allCases) { filter in
                        Button(action: {
                            selectedStatusFilter = filter
                            applyFilters()
                        }) {
                            Label(filter.rawValue, systemImage: filter == selectedStatusFilter ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                }
                
                Button(action: {
                    refreshClients()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var clientsContentView: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if clientManager.isLoading && clientManager.clients.isEmpty {
                ProgressView("Cargando clientes...")
            } else if let error = clientManager.errorMessage, clientManager.clients.isEmpty {
                errorView(message: error)
            } else {
                clientsList
            }
        }
    }
    
    // Implementar el debounce de búsqueda utilizando Timer
    private func performDebouncedSearch(_ searchText: String) {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        Just(searchText)
            .delay(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { text in
                if self.debouncedSearchText != text {
                    self.debouncedSearchText = text
                    self.applyFilters()
                }
            }
            .store(in: &cancellables)
    }
    
    // Aplicar todos los filtros activos
    private func applyFilters() {
        clientManager.loadClients(
            page: 1,
            search: searchText.isEmpty ? nil : searchText,
            active: selectedStatusFilter.value
        )
    }
    
    // Vista de la lista de clientes
    private var clientsList: some View {
        VStack(spacing: 0) {
            List {
                if clientManager.clients.isEmpty {
                    Text("No se encontraron clientes")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowBackground(Color.clear)
                } else {
                    clientsSection
                    paginationSection
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .refreshable {
                refreshClients()
            }
            
            if let pagination = clientManager.pagination, !clientManager.clients.isEmpty {
                paginationInfoFooter(pagination: pagination)
            }
        }
    }
    
    private var clientsSection: some View {
        ForEach(clientManager.clients) { client in
            ClientRow(client: client)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedClient = client
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        selectedClient = client
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
        }
    }
    
    @ViewBuilder
    private var paginationSection: some View {
        if clientManager.hasMorePages {
            HStack {
                Spacer()
                if clientManager.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Button("Cargar más...") {
                        clientManager.loadNextPage()
                    }
                    .padding()
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
            .onAppear {
                if !clientManager.isLoading {
                    clientManager.loadNextPage()
                }
            }
        }
    }
    
    private func paginationInfoFooter(pagination: ClientPaginationData) -> some View {
        HStack {
            Text("Mostrando \(clientManager.clients.count) de \(pagination.total) clientes")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if pagination.totalPages > 1 {
                Text("Página \(pagination.page) de \(pagination.totalPages)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // Vista para mostrar errores
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title)
                .bold()
            
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                refreshClients()
            }) {
                Text("Reintentar")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // Refrescar clientes
    private func refreshClients() {
        clientManager.refreshClients()
    }
    
    // Agregar un nuevo cliente
    private func addClient(_ client: Client) {
        clientManager.addClient(client)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in refreshClients() }
            )
            .store(in: &cancellables)
    }
    
    // Actualizar un cliente existente
    private func updateClient(_ client: Client) {
        clientManager.updateClient(client)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in refreshClients() }
            )
            .store(in: &cancellables)
    }
    
    // Eliminar un cliente
    private func deleteClient(_ id: String) {
        clientManager.deleteClient(id: id)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in refreshClients() }
            )
            .store(in: &cancellables)
    }
}

// Vista para una fila de cliente en la lista
struct ClientRow: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(client.name)
                    .font(.headline)
                
                Spacer()
                
                // Indicador de estado activo/inactivo
                Circle()
                    .fill(client.active ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
            }
            
            if !client.contactPerson.isEmpty {
                Label(client.contactPerson, systemImage: "person")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !client.email.isEmpty {
                Label(client.email, systemImage: "envelope")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !client.phone.isEmpty {
                Label(client.phone, systemImage: "phone")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Vista para agregar o editar clientes
struct ClientFormView: View {
    @Binding var isPresented: Bool
    let clientToEdit: Client?
    let onSave: (Client) -> Void
    var onCancel: (() -> Void)? = nil
    
    @State private var name = ""
    @State private var legalName = ""
    @State private var rfc = ""
    @State private var contactPerson = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var active = true
    
    private var isEditing: Bool {
        clientToEdit != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información Principal")) {
                    TextField("Nombre del cliente", text: $name)
                    TextField("Razón social", text: $legalName)
                    TextField("RFC", text: $rfc)
                        .textInputAutocapitalization(.characters)
                }
                
                Section(header: Text("Contacto")) {
                    TextField("Persona de contacto", text: $contactPerson)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Teléfono", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Ubicación")) {
                    TextField("Dirección", text: $address)
                }
                
                Section(header: Text("Notas")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle("Cliente activo", isOn: $active)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(isEditing ? "Editar Cliente" : "Nuevo Cliente")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        if let onCancel = onCancel {
                            onCancel()
                        } else {
                            isPresented = false
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveClient()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let client = clientToEdit {
                    // Llenar el formulario con la información del cliente existente
                    name = client.name
                    legalName = client.legalName
                    rfc = client.rfc
                    contactPerson = client.contactPerson
                    email = client.email
                    phone = client.phone
                    address = client.address
                    notes = client.notes
                    active = client.active
                }
            }
        }
    }
    
    private func saveClient() {
        // Crear o actualizar cliente
        let client = Client(
            id: clientToEdit?.id ?? UUID().uuidString,
            name: name,
            legalName: legalName,
            rfc: rfc,
            contactPerson: contactPerson,
            email: email,
            phone: phone,
            address: address,
            notes: notes,
            active: active
        )
        
        onSave(client)
        isPresented = false
    }
}

#Preview {
    ClientsManagementView(isPresented: .constant(true))
} 