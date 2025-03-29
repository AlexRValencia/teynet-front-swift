import SwiftUI

struct UserAdminView: View {
    @ObservedObject var viewModel = UserAdminViewModel()
    @State private var showingRoleFilter = false
    @State private var selectedRole: String? = nil
    @State private var isRefreshing = false
    @State private var selectedUserForDetail: AdminUser? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Barra de búsqueda y filtro
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Buscar por nombre o rol", text: $viewModel.searchText)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
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
                        viewModel.showCreateUserForm()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Filtro de roles
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        RoleFilterChip(
                            label: "Todos",
                            isSelected: selectedRole == nil,
                            action: { selectedRole = nil }
                        )
                        
                        ForEach(UserRole.allCases) { role in
                            RoleFilterChip(
                                label: role.displayName,
                                isSelected: selectedRole == role.rawValue,
                                action: {
                                    selectedRole = role.rawValue
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Group {
                    if viewModel.isLoading && viewModel.filteredUsers.isEmpty {
                        // Vista de carga cuando aún no hay datos
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                        // Vista de error
                        errorView
                    } else if filteredUsers().isEmpty {
                        // Vista de estado vacío
                        emptyStateView
                    } else {
                        // Lista de usuarios
                        userListView
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Usar el método de refresco normal para el botón
                        viewModel.refreshUsersList()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .overlay {
                // Indicador de carga superpuesto cuando se están actualizando datos existentes
                if viewModel.isLoading && !viewModel.filteredUsers.isEmpty {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                        .padding()
                        .background(Color.gray.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            .toolbar(removing: .title)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.isShowingUserForm) {
                UserFormView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedUserForDetail) { user in
                UserDetailView(user: user)
                    .presentationDetents([.medium])
            }
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("Aceptar")) {
                        // Refrescar la lista después de mostrar la alerta de éxito
                        if viewModel.alertTitle.contains("actualizado") || 
                           viewModel.alertTitle.contains("creado") || 
                           viewModel.alertTitle.contains("eliminado") {
                            // Generar un nuevo ID de lista para forzar la actualización
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.refreshUsersList()
                            }
                        }
                    }
                )
            }
            .confirmationDialog(
                "¿Estás seguro de que deseas eliminar este usuario?",
                isPresented: $viewModel.showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive, action: viewModel.deleteUser)
                Button("Cancelar", role: .cancel) { }
            } message: {
                if let user = viewModel.userToDelete {
                    Text("Esta acción eliminará permanentemente al usuario '\(user.fullName)'.")
                }
            }
        }
        .onAppear {
            // Cargamos los usuarios solo si aún no se han cargado
            if !viewModel.hasLoadedUsers {
                viewModel.loadUsers()
            }
        }
    }
    
    // MARK: - Componentes de la UI
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Cargando usuarios...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.headline)
            
            Text(viewModel.errorMessage ?? "Se ha producido un error desconocido")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                withAnimation {
                    // Usar el método normal para el botón de reintentar
                    viewModel.refreshUsersList()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reintentar")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 20)
            .disabled(viewModel.isLoading)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            if viewModel.searchText.isEmpty && selectedRole == nil {
                Text("No hay usuarios disponibles")
                    .font(.headline)
                Text("Crea un nuevo usuario pulsando el botón '+' en la parte superior")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No se encontraron resultados")
                    .font(.headline)
                Text("Intenta con otros términos de búsqueda o filtros")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Botón de actualización
            Button(action: {
                withAnimation {
                    viewModel.searchText = ""
                    selectedRole = nil
                    viewModel.refreshUsersList()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Limpiar filtros y actualizar")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 20)
            .disabled(viewModel.isLoading)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var userListView: some View {
        List {
            ForEach(filteredUsers()) { user in
                UserRowView(user: user, viewModel: viewModel)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedUserForDetail = user
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.confirmDeleteUser(user: user)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        
                        Button {
                            viewModel.showEditUserForm(user: user)
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.toggleUserStatus(user: user)
                        } label: {
                            if user.status {
                                Label("Desactivar", systemImage: "slash.circle")
                            } else {
                                Label("Activar", systemImage: "checkmark.circle")
                            }
                        }
                        .tint(user.status ? .orange : .green)
                    }
            }
        }
        .refreshable {
            // Método seguro para actualizar los datos
            await viewModel.safeRefreshUsersList()
        }
    }
    
    // Función para filtrar usuarios según los criterios seleccionados
    private func filteredUsers() -> [AdminUser] {
        var users = viewModel.filteredUsers
        
        // Aplicar filtro por rol si está seleccionado
        if let role = selectedRole {
            users = users.filter { $0.role == role }
        }
        
        return users
    }
}

// MARK: - Vista de detalle de usuario
struct UserDetailView: View {
    let user: AdminUser
    @Environment(\.dismiss) private var dismiss
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Información básica")) {
                    UserDetailRow(title: "ID", value: user.id)
                    UserDetailRow(title: "Nombre de usuario", value: user.username)
                    UserDetailRow(title: "Nombre completo", value: user.fullName)
                    UserDetailRow(title: "Rol", value: getRoleName(role: user.role))
                    UserDetailRow(title: "Estado", value: user.status ? "Activo" : "Inactivo")
                }
                
                Section(header: Text("Fechas y auditoría")) {
                    if let lastLogin = user.lastLogin {
                        UserDetailRow(title: "Último acceso", value: dateFormatter.string(from: lastLogin))
                    } else {
                        UserDetailRow(title: "Último acceso", value: "No disponible")
                    }
                    
                    UserDetailRow(title: "Creado el", value: dateFormatter.string(from: user.createdAt))
                    
                    if let createdBy = user.createdBy {
                        UserDetailRow(title: "Creado por", value: createdBy)
                    } else {
                        UserDetailRow(title: "Creado por", value: "Sistema")
                    }
                    
                    UserDetailRow(title: "Actualizado el", value: dateFormatter.string(from: user.updatedAt))
                    
                    if let modifiedBy = user.modifiedBy {
                        UserDetailRow(title: "Modificado por", value: modifiedBy)
                    } else {
                        UserDetailRow(title: "Modificado por", value: "No disponible")
                    }
                }
            }
            .navigationTitle("Detalle de Usuario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getRoleName(role: String) -> String {
        if let userRole = UserRole(rawValue: role) {
            return userRole.displayName
        }
        return role.capitalized
    }
}

struct UserDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Componente de chip para filtros de rol
struct RoleFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Vistas auxiliares

struct UserRowView: View {
    let user: AdminUser
    let viewModel: UserAdminViewModel
    @State private var isShowingHistoryView = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar o iniciales
            ZStack {
                Circle()
                    .fill(user.status ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(user.status ? .blue : .gray)
            }
            
            // Información del usuario
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.headline)
                    .foregroundColor(user.status ? .primary : .gray)
                
                Text(user.username)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    // Badge de rol
                    Text(roleName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(roleColor.opacity(0.2))
                        .foregroundColor(roleColor)
                        .cornerRadius(4)
                    
                    // Badge de estado
                    if !user.status {
                        Text("Inactivo")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Botón de acciones
            Menu {
                Button {
                    viewModel.showEditUserForm(user: user)
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                
                Button {
                    viewModel.toggleUserStatus(user: user)
                } label: {
                    if user.status {
                        Label("Desactivar", systemImage: "slash.circle")
                    } else {
                        Label("Activar", systemImage: "checkmark.circle")
                    }
                }
                
                Button {
                    isShowingHistoryView = true
                } label: {
                    Label("Ver historial", systemImage: "clock.arrow.circlepath")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    viewModel.confirmDeleteUser(user: user)
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $isShowingHistoryView) {
            UserHistoryView(viewModel: viewModel, userId: user.id, userName: user.fullName)
                .presentationDetents([.medium, .large])
        }
    }
    
    // Obtener iniciales del nombre
    var initials: String {
        let components = user.fullName.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        } else if let first = components.first?.first {
            return "\(first)"
        }
        return "?"
    }
    
    // Obtener nombre del rol
    var roleName: String {
        switch user.role {
        case "admin": return "Administrador"
        case "technician": return "Técnico"
        case "supervisor": return "Supervisor"
        case "viewer": return "Visualizador"
        default: return user.role.capitalized
        }
    }
    
    // Obtener color según el rol
    var roleColor: Color {
        switch user.role {
        case "admin": return .purple
        case "technician": return .blue
        case "supervisor": return .green
        case "viewer": return .orange
        default: return .gray
        }
    }
}

// Vista previa para SwiftUI
#Preview {
    UserAdminView()
}

// Vista previa para UserRowView
struct UserRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            UserRowView(
                user: AdminUser(
                    id: "1",
                    username: "test_user",
                    fullName: "Usuario de Prueba",
                    role: "admin",
                    status: true,
                    createdAt: Date(),
                    updatedAt: Date(),
                    createdBy: nil,
                    modifiedBy: nil
                ),
                viewModel: UserAdminViewModel()
            )
        }
    }
} 