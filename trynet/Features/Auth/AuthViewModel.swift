import SwiftUI
import Combine
import UIKit

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var username = ""
    @Published var password = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var currentUser: User?
    @Published var isUsingFallback = false
    @Published var detailedErrorInfo: String? = nil
    @Published var isBiometricAvailable = false
    @Published var biometricType: BiometricType = .none
    @Published var isBiometricEnabled = false
    @Published var showBiometricAlert = false
    @Published var showBiometricConfirmation = false
    @Published var biometricConfirmationMessage = ""
    
    private let authService = AuthService.shared
    private let biometricService = BiometricAuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Variables para la reconexión adaptativa
    private var reconnectTimer: Timer?
    private var reconnectInterval: TimeInterval = 30 // Comienza en 30 segundos
    
    init() {
        // Verificar si ya hay una sesión activa al iniciar
        checkAuthStatus()
        
        // Verificar disponibilidad de biometría
        checkBiometricAvailability()
        
        // Verificar si la autenticación biométrica está habilitada
        isBiometricEnabled = UserDefaults.standard.bool(forKey: "isBiometricEnabled")
        
        // Observar cambios en el estado de la aplicación
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                // Cuando la app vuelve a primer plano, intentamos reconectar si estamos en modo fallback
                if self?.isUsingFallback == true {
                    self?.reconnectToBackend()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkAuthStatus() {
        if authService.isAuthenticated() {
            self.isAuthenticated = true
            self.currentUser = authService.getCurrentUser()
        }
    }
    
    private func checkBiometricAvailability() {
        isBiometricAvailable = biometricService.isBiometricAuthAvailable()
        biometricType = biometricService.getBiometricType()
    }
    
    // Método para iniciar sesión con credenciales
    func login() {
        isLoading = true
        errorMessage = ""
        detailedErrorInfo = nil
        
        authService.login(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = error.message
                        self.detailedErrorInfo = error.detailedDescription
                        
                        // Si el error es de conexión, intentamos el fallback
                        if error.isConnectionError {
                            print("🔄 Error de conexión, intentando fallback...")
                            self.loginFallback()
                        }
                    }
                },
                receiveValue: { [weak self] user in
                    guard let self = self else { return }
                    
                    self.currentUser = user
                    withAnimation {
                        self.isAuthenticated = true
                    }
                    
                    // Si el login fue exitoso y el usuario ha habilitado la biometría,
                    // guardamos las credenciales para uso futuro
                    if self.isBiometricEnabled {
                        self.biometricService.saveBiometricCredentials(
                            username: self.username,
                            password: self.password
                        )
                    } else if self.isBiometricAvailable && !self.biometricService.hasBiometricCredentials() {
                        // Si la biometría está disponible pero no habilitada, y no hay credenciales guardadas,
                        // preguntamos al usuario si desea habilitarla
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.showBiometricAlert = true
                        }
                    }
                    
                    // Limpiar campos después del login exitoso
                    self.errorMessage = ""
                    self.detailedErrorInfo = nil
                }
            )
            .store(in: &cancellables)
    }
    
    // Método para iniciar sesión con biometría
    func loginWithBiometrics() async {
        // Verificar si la biometría está disponible y habilitada
        guard isBiometricAvailable && isBiometricEnabled else {
            await MainActor.run {
                errorMessage = "La autenticación biométrica no está disponible o habilitada"
            }
            return
        }
        
        // Verificar si hay credenciales guardadas
        guard let credentials = biometricService.retrieveBiometricCredentials() else {
            await MainActor.run {
                errorMessage = "No hay credenciales guardadas para autenticación biométrica"
            }
            return
        }
        
        // Intentar autenticar con biometría
        await MainActor.run {
            isLoading = true
            errorMessage = ""
            detailedErrorInfo = nil
        }
        
        let result = await biometricService.authenticateUser()
        
        switch result {
        case .success(true):
            // Autenticación biométrica exitosa, usar credenciales guardadas
            await MainActor.run {
                username = credentials.username
                password = credentials.password
                login()
            }
        case .success(false):
            await MainActor.run {
                isLoading = false
                errorMessage = "Autenticación biométrica cancelada"
            }
        case .failure(let error):
            await MainActor.run {
                isLoading = false
                errorMessage = "Error de autenticación biométrica"
                detailedErrorInfo = error.localizedDescription
            }
        }
    }
    
    // Habilitar o deshabilitar la autenticación biométrica
    func toggleBiometricAuth(enabled: Bool) {
        isBiometricEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "isBiometricEnabled")
        
        if enabled {
            // Si se habilita, guardar las credenciales actuales si el usuario está autenticado
            if isAuthenticated && !username.isEmpty && !password.isEmpty {
                biometricService.saveBiometricCredentials(username: username, password: password)
                
                // Mostrar mensaje de confirmación
                biometricConfirmationMessage = "\(biometricType.description) activado correctamente"
                showBiometricConfirmation = true
                
                // Ocultar el mensaje después de 3 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showBiometricConfirmation = false
                }
            }
        } else {
            // Si se deshabilita, eliminar las credenciales guardadas
            biometricService.deleteBiometricCredentials()
            
            // Mostrar mensaje de confirmación
            biometricConfirmationMessage = "\(biometricType.description) desactivado"
            showBiometricConfirmation = true
            
            // Ocultar el mensaje después de 3 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showBiometricConfirmation = false
            }
        }
    }
    
    func loginFallback() {
        isLoading = true
        isUsingFallback = true
        
        print("🔶 Usando modo fallback para autenticación")
        
        // Simulamos un retraso de red
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            
            if self.username == "admin" && self.password == "password" {
                // Usuario demo
                let demoUser = User(
                    id: "1",
                    username: "admin",
                    name: "Administrador",
                    role: "admin"
                )
                
                // Guardamos datos demo en UserDefaults para simular persistencia
                UserDefaults.standard.set(demoUser.id, forKey: "userId")
                UserDefaults.standard.set(demoUser.name, forKey: "userName")
                UserDefaults.standard.set(demoUser.username, forKey: "username")
                UserDefaults.standard.set(demoUser.role, forKey: "userRole")
                
                // Actualizamos la UI
                self.currentUser = demoUser
                withAnimation {
                    self.isAuthenticated = true
                    self.errorMessage = ""
                }
                
                print("✅ Login fallback exitoso para: \(demoUser.name)")
                
                // Si la biometría está disponible pero no habilitada, y no hay credenciales guardadas,
                // preguntamos al usuario si desea habilitarla
                if self.isBiometricAvailable && !self.isBiometricEnabled && !self.biometricService.hasBiometricCredentials() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.showBiometricAlert = true
                    }
                }
                
                // Reiniciar el intervalo de reconexión y comenzar a verificar periódicamente
                self.resetReconnectInterval()
                self.startReconnectTimer()
            } else {
                self.errorMessage = "Credenciales inválidas (admin/password para modo fallback)"
            }
            
            self.isLoading = false
        }
    }
    
    // Función para intentar reconectar con el backend real
    func reconnectToBackend() {
        guard isUsingFallback, isAuthenticated, currentUser != nil else {
            return
        }
        
        // Intentar una petición simple para verificar si el backend está disponible
        authService.pingServer()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAvailable in
                guard let self = self else { return }
                
                if isAvailable {
                    print("✅ Servidor detectado nuevamente. Mostrando opción para reconectar.")
                    // Aquí podríamos mostrar una alerta o notificación al usuario
                    // para que sepa que puede volver al modo normal
                    
                    // Reiniciar el intervalo de reconexión
                    self.resetReconnectInterval()
                } else {
                    print("❌ Servidor sigue sin estar disponible. Incrementando intervalo de reconexión.")
                    // Incrementar el intervalo para la próxima verificación (estrategia de backoff)
                    self.increaseReconnectInterval()
                }
            }
            .store(in: &cancellables)
    }
    
    // Función para cerrar sesión
    func logout() {
        isLoading = true
        
        // Si estamos en modo fallback, simplemente limpiamos los datos locales
        if isUsingFallback {
            clearLocalData()
            return
        }
        
        // Intentar hacer logout en el servidor
        authService.logout()
        
        // Limpiar datos locales
        clearLocalData()
    }
    
    private func clearLocalData() {
        // Limpiar datos de la sesión
        withAnimation {
            isAuthenticated = false
            currentUser = nil
            isUsingFallback = false
            username = ""
            password = ""
            errorMessage = ""
            detailedErrorInfo = nil
        }
        
        // Detener el timer de reconexión si está activo
        stopReconnectTimer()
        
        // Finalizar la carga
        isLoading = false
    }
    
    // Funciones para la reconexión adaptativa
    private func startReconnectTimer() {
        stopReconnectTimer() // Asegurarse de que no haya un timer activo
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            self?.reconnectToBackend()
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func resetReconnectInterval() {
        reconnectInterval = 30 // Volver al intervalo inicial
    }
    
    private func increaseReconnectInterval() {
        // Estrategia de backoff exponencial con un límite máximo
        let maxInterval: TimeInterval = 15 * 60 // 15 minutos
        reconnectInterval = min(reconnectInterval * 2, maxInterval)
        
        // Programar la próxima verificación
        startReconnectTimer()
    }
    
    // Método para manejar la sesión expirada
    func sessionExpired() {
        print("⏰ La sesión ha expirado")
        
        // Limpiar datos y cerrar sesión
        clearLocalData()
        
        // Mostrar mensaje al usuario
        self.errorMessage = "Tu sesión ha expirado. Por favor, inicia sesión nuevamente."
    }
} 
