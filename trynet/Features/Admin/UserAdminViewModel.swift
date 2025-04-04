import Foundation
import Combine
import SwiftUI

class UserAdminViewModel: ObservableObject {
    // Instancia compartida para acceso global
    static let shared = UserAdminViewModel()
    
    // Estado de la lista de usuarios
    @Published var users: [AdminUser] = []
    @Published var filteredUsers: [AdminUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var searchText = ""
    @Published var hasLoadedUsers = false
    @Published var listId = UUID() // ID único para forzar la reconstrucción de la lista
    @Published var currentUser: AdminUser? = nil
    
    // Estado para la creación/edición de usuarios
    @Published var isShowingUserForm = false
    @Published var isEditMode = false
    @Published var selectedUser: AdminUser? = nil
    
    // Campos del formulario
    @Published var formUsername = ""
    @Published var formFullName = ""
    @Published var formRole = UserRole.viewer.rawValue
    @Published var formPassword = ""
    @Published var formConfirmPassword = ""
    @Published var formStatus = true
    
    // Estado para confirmaciones
    @Published var showingDeleteConfirmation = false
    @Published var userToDelete: AdminUser? = nil
    
    // Estado para mensajes de éxito/error
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // Estado para historial de usuarios
    @Published var selectedUserHistory: [UserHistory] = []
    @Published var isLoadingHistory = false
    @Published var historyError: APIError? = nil
    @Published var historyPage = 1
    @Published var historyTotalPages = 1
    @Published var historyLimit = 20
    
    // Servicios
    private let userService = UserAdminService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Configurar el filtrado de usuarios cuando cambia el texto de búsqueda
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterUsers(searchText: searchText)
            }
            .store(in: &cancellables)
        
        // Se elimina la carga automática de usuarios
        // loadUsers() - Ya no se llama aquí para evitar peticiones innecesarias
    }
    
    // MARK: - Métodos para cargar datos
    
    func loadUsers() {
        // Si ya se cargaron usuarios, no volvemos a cargar a menos que sea una solicitud explícita de actualización
        if isLoading { return }
        
        isLoading = true
        errorMessage = nil
        
        userService.getUsers()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = "Error al cargar usuarios: \(error.message)"
                        print("❌ Error cargando usuarios: \(error.message)")
                    }
                },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }
                    self.users = users.sorted { $0.fullName < $1.fullName }
                    self.filterUsers(searchText: self.searchText)
                    self.hasLoadedUsers = true
                    
                    // Establecer el usuario actual
                    if let currentUser = self.authService.getCurrentUser() {
                        self.currentUser = self.users.first { $0.id == currentUser.id }
                    }
                    
                    print("✅ \(users.count) usuarios cargados correctamente")
                }
            )
            .store(in: &cancellables)
    }
    
    private func filterUsers(searchText: String) {
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { user in
                user.fullName.localizedCaseInsensitiveContains(searchText) ||
                user.username.localizedCaseInsensitiveContains(searchText) ||
                user.role.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Métodos para gestionar el formulario
    
    func showCreateUserForm() {
        resetForm()
        isEditMode = false
        selectedUser = nil
        isShowingUserForm = true
    }
    
    func showEditUserForm(user: AdminUser) {
        resetForm()
        
        // Rellenar el formulario con los datos del usuario
        formUsername = user.username
        formFullName = user.fullName
        formRole = user.role
        formStatus = user.status
        formPassword = ""
        formConfirmPassword = ""
        
        isEditMode = true
        selectedUser = user
        isShowingUserForm = true
    }
    
    func resetForm() {
        formUsername = ""
        formFullName = ""
        formRole = UserRole.viewer.rawValue
        formPassword = ""
        formConfirmPassword = ""
        formStatus = true
        errorMessage = nil
    }
    
    func closeForm() {
        isShowingUserForm = false
        resetForm()
    }
    
    // MARK: - Validación del formulario
    
    func validateForm() -> Bool {
        // Validar campos obligatorios
        guard !formUsername.isEmpty else {
            errorMessage = "El nombre de usuario es obligatorio"
            return false
        }
        
        guard !formFullName.isEmpty else {
            errorMessage = "El nombre completo es obligatorio"
            return false
        }
        
        // Validar contraseña solo si es un nuevo usuario o si se está cambiando
        if !isEditMode || !formPassword.isEmpty {
            guard formPassword.count >= 8 else {
                errorMessage = "La contraseña debe tener al menos 8 caracteres"
                return false
            }
            
            guard formPassword == formConfirmPassword else {
                errorMessage = "Las contraseñas no coinciden"
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Operaciones CRUD
    
    func saveUser() {
        guard validateForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        let userRequest = UserCreateUpdateRequest(
            username: formUsername,
            fullName: formFullName,
            role: formRole,
            password: formPassword.isEmpty && isEditMode ? nil : formPassword,
            status: formStatus
        )
        
        let publisher: AnyPublisher<AdminUser, APIError>
        
        if isEditMode, let selectedUser = selectedUser {
            // Crear un nuevo objeto AdminUser con los datos actualizados, incluido el rol
            let updatedUser = AdminUser(
                id: selectedUser.id,
                username: formUsername,
                fullName: formFullName,
                role: formRole, // Usar el rol seleccionado en el formulario
                status: formStatus,
                lastLogin: selectedUser.lastLogin,
                createdAt: selectedUser.createdAt,
                updatedAt: Date(),
                createdBy: selectedUser.createdBy,
                modifiedBy: selectedUser.modifiedBy
            )
            
            // Mostrar información de depuración
            print("🔍 Actualizando usuario con los siguientes datos:")
            print("   - ID: \(updatedUser.id)")
            print("   - Username: \(updatedUser.username)")
            print("   - FullName: \(updatedUser.fullName)")
            print("   - Rol: \(updatedUser.role)")
            print("   - Status: \(updatedUser.status)")
            
            // Usar el objeto actualizado para la llamada al servicio
            publisher = userService.updateUser(updatedUser, password: formPassword.isEmpty ? nil : formPassword)
        } else {
            // Crear nuevo usuario
            publisher = userService.createUser(user: userRequest)
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = "Error al guardar usuario: \(error.message)"
                        print("❌ Error guardando usuario: \(error.message)")
                    }
                },
                receiveValue: { [weak self] user in
                    guard let self = self else { return }
                    
                    // Actualizar la lista de usuarios
                    if self.isEditMode {
                        print("✅ Usuario actualizado con éxito: \(user.id) - \(user.fullName) - Rol: \(user.role)")
                        
                        // Actualización más robusta - actualizar en lugar de eliminar y añadir
                        if let index = self.users.firstIndex(where: { $0.id == user.id }) {
                            print("🔄 Actualizando usuario en índice \(index) con nuevos datos")
                            self.users[index] = user
                        } else {
                            // Si no existe, lo añadimos (caso poco probable)
                            print("➕ Usuario no encontrado en la lista existente, añadiendo")
                            self.users.append(user)
                        }
                        
                        // Verificar si se está editando el usuario actual
                        self.updateCurrentUserIfNeeded(updatedUser: user)
                        
                        self.alertTitle = "Usuario actualizado"
                        self.alertMessage = "El usuario \(user.fullName) ha sido actualizado correctamente"
                    } else {
                        print("✅ Usuario creado con éxito: \(user.id) - \(user.fullName) - Rol: \(user.role)")
                        self.users.append(user)
                        self.alertTitle = "Usuario creado"
                        self.alertMessage = "El usuario \(user.fullName) ha sido creado correctamente"
                    }
                    
                    // Ordenar y filtrar usuarios
                    self.users.sort { $0.fullName < $1.fullName }
                    self.filterUsers(searchText: self.searchText)
                    
                    // Forzar una actualización completa de la UI
                    DispatchQueue.main.async {
                        // Crear una copia temporal de los usuarios para forzar una actualización completa
                        let tempUsers = self.users
                        self.users = []
                        // Pequeño retraso para asegurar que SwiftUI detecte el cambio
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            print("🔄 Forzando actualización completa de la lista de usuarios: \(tempUsers.count) usuarios")
                            self.users = tempUsers
                            self.filterUsers(searchText: self.searchText)
                        }
                    }
                    
                    // Cerrar formulario y mostrar alerta de éxito
                    self.closeForm()
                    self.showingAlert = true
                }
            )
            .store(in: &cancellables)
    }
    
    // Método para actualizar los datos del usuario actual si es el que se está editando
    private func updateCurrentUserIfNeeded(updatedUser: AdminUser) {
        // Obtener el usuario actual
        guard let currentUser = authService.getCurrentUser() else {
            return
        }
        
        // Verificar si el usuario actualizado es el usuario actual
        if currentUser.id == updatedUser.id {
            print("🔄 El usuario actualizado es el usuario actual - actualizando datos de sesión")
            
            // Actualizar datos en UserDefaults
            UserDefaults.standard.set(updatedUser.fullName, forKey: "userName")
            UserDefaults.standard.set(updatedUser.username, forKey: "username")
            UserDefaults.standard.set(updatedUser.role, forKey: "userRole")
            
            // Mostrar información en consola
            print("✅ Datos de sesión actualizados:")
            print("   - Nombre: \(updatedUser.fullName)")
            print("   - Username: \(updatedUser.username)")
            print("   - Rol: \(updatedUser.role)")
        }
    }
    
    func confirmDeleteUser(user: AdminUser) {
        userToDelete = user
        showingDeleteConfirmation = true
    }
    
    func deleteUser() {
        guard let user = userToDelete, let userId = userToDelete?.id else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        userService.deleteUser(id: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = "Error al eliminar usuario: \(error.message)"
                        print("❌ Error eliminando usuario: \(error.message)")
                    }
                },
                receiveValue: { [weak self] success in
                    guard let self = self, success else { return }
                    
                    // Eliminar usuario de la lista
                    self.users.removeAll { $0.id == userId }
                    self.filterUsers(searchText: self.searchText)
                    
                    // Mostrar alerta de éxito
                    self.alertTitle = "Usuario eliminado"
                    self.alertMessage = "El usuario \(user.fullName) ha sido eliminado correctamente"
                    self.showingAlert = true
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleUserStatus(user: AdminUser) {
        isLoading = true
        errorMessage = nil
        
        // Cambiamos la llamada para usar directamente el ID y el nuevo estado
        userService.toggleUserStatus(id: user.id, active: !user.status)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = "Error al cambiar estado del usuario: \(error.message)"
                        print("❌ Error cambiando estado: \(error.message)")
                    }
                },
                receiveValue: { [weak self] updatedUser in
                    guard let self = self else { return }
                    
                    print("✅ Estado de usuario cambiado con éxito: \(updatedUser.id) - \(updatedUser.status ? "activo" : "inactivo")")
                    
                    // Actualizar usuario en la lista
                    if let index = self.users.firstIndex(where: { $0.id == updatedUser.id }) {
                        print("🔄 Actualizando estado de usuario en índice \(index)")
                        self.users[index] = updatedUser
                        
                        // Aplicar filtrado para refrescar la lista
                        self.filterUsers(searchText: self.searchText)
                        
                        // Verificar si se está editando el usuario actual
                        self.updateCurrentUserIfNeeded(updatedUser: updatedUser)
                    } else {
                        print("⚠️ No se encontró el usuario en la lista actual, recargando todos los usuarios")
                        // Si por alguna razón no encontramos el usuario, recargamos toda la lista
                        self.refreshUsersList()
                    }
                    
                    self.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    // Verificar si un usuario es el usuario actual
    private func isCurrentUser(_ user: AdminUser) -> Bool {
        guard let currentUser = authService.getCurrentUser() else {
            return false
        }
        return currentUser.id == user.id
    }
    
    // Cargar historial de un usuario
    func loadUserHistory(userId: String, page: Int = 1) {
        isLoadingHistory = true
        historyError = nil
        historyPage = page
        
        userService.getUserHistory(id: userId, page: page, limit: historyLimit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingHistory = false
                    if case .failure(let error) = completion {
                        self?.historyError = error
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    self.selectedUserHistory = response.data.history.map { UserHistory(from: $0) }
                    self.historyTotalPages = response.data.pagination.pages
                    self.historyPage = response.data.pagination.page
                }
            )
            .store(in: &cancellables)
    }
    
    // Ir a la página siguiente del historial
    func nextHistoryPage() {
        if historyPage < historyTotalPages, let userId = selectedUser?.id {
            loadUserHistory(userId: userId, page: historyPage + 1)
        }
    }
    
    // Ir a la página anterior del historial
    func previousHistoryPage() {
        if historyPage > 1, let userId = selectedUser?.id {
            loadUserHistory(userId: userId, page: historyPage - 1)
        }
    }
    
    // Método seguro para actualizar la lista de usuarios desde un refreshable control
    @MainActor
    func safeRefreshUsersList() async {
        print("🔄 Actualizando lista de usuarios de forma segura (refreshable)...")
        
        if isLoading {
            print("⚠️ Ya hay una carga en progreso, se omite esta solicitud")
            return
        }
        
        // Indicamos que estamos cargando
        isLoading = true
        errorMessage = nil
        
        // Operación asíncrona, pero evitando conflictos con otros controles de actualización
        do {
            let users = try await userService.getUsersAsync()
            await MainActor.run {
                print("✅ Lista de usuarios recargada: \(users.count) usuarios")
                
                // Actualizar datos de forma segura
                let sortedUsers = users.sorted { $0.fullName < $1.fullName }
                self.users = sortedUsers
                self.filterUsers(searchText: self.searchText)
                self.hasLoadedUsers = true
                self.isLoading = false
                
                // Si la lista está vacía después de la recarga, mostramos un mensaje informativo
                if sortedUsers.isEmpty {
                    print("ℹ️ No se encontraron usuarios en el servidor")
                    self.errorMessage = "No hay usuarios disponibles en el sistema"
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                print("❌ Error al recargar usuarios: \(error.message)")
                self.errorMessage = "No se pudieron cargar los usuarios: \(error.message)"
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                print("❌ Error desconocido al recargar usuarios")
                self.errorMessage = "Error desconocido al cargar los usuarios"
                self.isLoading = false
            }
        }
    }
    
    // Método para recargar la lista de usuarios (versión tradicional)
    func refreshUsersList() {
        print("🔄 Recargando lista de usuarios desde el servidor...")
        
        // Evitamos múltiples cargas simultáneas
        if isLoading {
            print("⚠️ Ya hay una carga en progreso, se omite esta solicitud")
            return
        }
        
        // Indicamos que estamos cargando
        isLoading = true
        errorMessage = nil
        
        userService.getUsers()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        print("❌ Error al recargar usuarios: \(error.message)")
                        self.errorMessage = "No se pudieron cargar los usuarios: \(error.message)"
                    }
                },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }
                    
                    print("✅ Lista de usuarios recargada: \(users.count) usuarios")
                    
                    // Actualizar la lista ordenada
                    let sortedUsers = users.sorted { $0.fullName < $1.fullName }
                    self.users = sortedUsers
                    
                    // Aplicar filtro actual
                    self.filterUsers(searchText: self.searchText)
                    
                    // Limpiar cualquier mensaje de error previo
                    self.errorMessage = nil
                    
                    // Indicar que ya cargamos los datos
                    self.hasLoadedUsers = true
                    
                    // Notificación de éxito en consola
                    print("✅ UI actualizada con \(sortedUsers.count) usuarios")
                    
                    // Si la lista está vacía después de la recarga, mostramos un mensaje informativo
                    if sortedUsers.isEmpty {
                        print("ℹ️ No se encontraron usuarios en el servidor")
                        self.errorMessage = "No hay usuarios disponibles en el sistema"
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// Extensión para añadir métodos async/await al servicio de usuarios
extension UserAdminService {
    func getUsersAsync() async throws -> [AdminUser] {
        try await withCheckedThrowingContinuation { continuation in
            getUsers()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { users in
                        continuation.resume(returning: users)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
} 