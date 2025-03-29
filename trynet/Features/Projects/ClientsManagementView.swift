import SwiftUI
import Combine

struct ClientsManagementView: View {
    @StateObject private var clientManager = ClientManager.shared
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var showingAddClientSheet = false
    @State private var selectedClient: Client? = nil
    @State private var showingDeleteConfirmation = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // Añadir una propiedad para almacenar las cancelables
    @State private var cancellables = Set<AnyCancellable>()
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clientManager.clients
        } else {
            return clientManager.clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                client.contactPerson.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView("Cargando clientes...")
                } else if let error = errorMessage {
                    errorView(message: error)
                } else {
                    clientsList
                }
            }
            .navigationTitle("Gestión de Clientes")
            .searchable(text: $searchText, prompt: "Buscar cliente")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddClientSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadClients()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddClientSheet) {
                ClientFormView(isPresented: $showingAddClientSheet, clientToEdit: nil, onSave: { newClient in
                    addClient(newClient)
                })
            }
            .sheet(item: $selectedClient) { client in
                ClientFormView(isPresented: .constant(true), clientToEdit: client, onSave: { updatedClient in
                    updateClient(updatedClient)
                    selectedClient = nil
                })
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
                loadClients()
            }
        }
    }
    
    // Vista de la lista de clientes
    private var clientsList: some View {
        List {
            if filteredClients.isEmpty {
                Text("No se encontraron clientes")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                ForEach(filteredClients) { client in
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
        }
        .listStyle(InsetGroupedListStyle())
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
                loadClients()
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
    
    // Cargar los clientes
    private func loadClients() {
        isLoading = true
        errorMessage = nil
        
        // Simular una carga asíncrona
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            clientManager.loadClients()
            isLoading = false
        }
    }
    
    // Agregar un nuevo cliente
    private func addClient(_ client: Client) {
        clientManager.addClient(client)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        errorMessage = "Error al agregar cliente: \(error.message)"
                    case .finished:
                        // Nada que hacer aquí
                        break
                    }
                },
                receiveValue: { _ in
                    // Cliente agregado con éxito
                }
            )
            .store(in: &cancellables)
    }
    
    // Actualizar un cliente existente
    private func updateClient(_ client: Client) {
        clientManager.updateClient(client)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        errorMessage = "Error al actualizar cliente: \(error.message)"
                    case .finished:
                        // Nada que hacer aquí
                        break
                    }
                },
                receiveValue: { _ in
                    // Cliente actualizado con éxito
                }
            )
            .store(in: &cancellables)
    }
    
    // Eliminar un cliente
    private func deleteClient(_ id: String) {
        clientManager.deleteClient(id: id)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        errorMessage = "Error al eliminar cliente: \(error.message)"
                    case .finished:
                        // Nada que hacer aquí
                        break
                    }
                },
                receiveValue: { _ in
                    // Cliente eliminado con éxito
                }
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
        NavigationView {
            Form {
                Section(header: Text("Información Principal")) {
                    TextField("Nombre del cliente", text: $name)
                    TextField("Razón social", text: $legalName)
                    TextField("RFC", text: $rfc)
                        .autocapitalization(.allCharacters)
                }
                
                Section(header: Text("Contacto")) {
                    TextField("Persona de contacto", text: $contactPerson)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
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
            .navigationTitle(isEditing ? "Editar Cliente" : "Nuevo Cliente")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        isPresented = false
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