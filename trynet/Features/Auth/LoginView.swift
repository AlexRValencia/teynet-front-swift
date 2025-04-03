import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var focusedField: Field?
    @State private var showPassword = false
    @State private var serverCheckTimer: Timer?
    @State private var serverIsReachable = false
    @State private var shouldSetInitialFocus = true
    @State private var isCheckingServer = false
    @State private var lastCheckTime: Date? = nil
    @State private var showDetailedError = false
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        ZStack {
            // Fondo que se extiende por toda la pantalla sin moverse cuando aparece el teclado
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.4)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Contenido principal en un ScrollView para manejar mejor el teclado
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Logo y título
                    logoSection
                    
                    // Indicador de estado del servidor con botón para verificar manualmente
                    serverStatusSection
                    
                    // Formulario de login
                    loginFormSection
                    
                    Spacer(minLength: 40)
                    
                    // Footer
                    footerSection
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .opacity(0.8)
                        .shadow(radius: 5)
                )
                .padding(.horizontal, 20)
            }
            
            // Alerta biométrica
            .alert("Usar \(authViewModel.biometricType.description) para iniciar sesión", isPresented: $authViewModel.showBiometricAlert) {
                Button("No, gracias", role: .cancel) {
                    // No hacer nada, el usuario no quiere usar biometría
                }
                Button("Activar") {
                    authViewModel.toggleBiometricAuth(enabled: true)
                }
            } message: {
                Text("¿Deseas usar \(authViewModel.biometricType.description) para iniciar sesión más rápido la próxima vez?")
            }
            
            // Capa de bloqueo durante el inicio de sesión
            if authViewModel.isLoading {
                loadingOverlay
            }
        }
        .onTapGesture {
            // Cerrar teclado al tocar fuera de un campo
            focusedField = nil
        }
        .task {
            // Verificar el estado del servidor de forma asíncrona
            // para no bloquear la UI
            await MainActor.run {
                isCheckingServer = true
            }
            await checkServerStatusAsync()
            await MainActor.run {
                lastCheckTime = Date()
                isCheckingServer = false
            }
        }
        .onAppear {
            // Establecer el foco en el campo de usuario después de un breve retraso
            // para asegurar que la vista esté completamente cargada
            if shouldSetInitialFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusedField = .username
                    shouldSetInitialFocus = false
                }
            }
            
            // Configurar el timer de forma asíncrona para no bloquear la UI
            DispatchQueue.main.async {
                // Aumentamos el intervalo a 90 segundos para reducir el consumo de recursos
                serverCheckTimer = Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { _ in
                    // Solo verificar si la aplicación está activa (no en background)
                    if UIApplication.shared.applicationState == .active {
                        Task {
                            await self.checkServerStatusAsync()
                            // Actualizamos lastCheckTime en el actor principal
                            await MainActor.run {
                                self.lastCheckTime = Date()
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            // Detener el timer cuando la vista desaparece
            serverCheckTimer?.invalidate()
            serverCheckTimer = nil
        }
        .onChange(of: authViewModel.errorMessage) { _, newValue in
            // Resetear el estado de visualización de error detallado cuando cambia el mensaje
            if newValue.isEmpty {
                showDetailedError = false
            }
        }
    }
    
    // MARK: - View Components
    
    private var logoSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "network")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("TryNet")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Sistema de gestión de proyectos")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60) // Espacio adicional en la parte superior para evitar el notch
        .padding(.bottom, 40)
    }
    
    private var serverStatusSection: some View {
        HStack {
            serverStatusBadge
            
            Spacer()
            
            // Botón para verificar la conexión manualmente
            Button(action: {
                Task {
                    await MainActor.run {
                        isCheckingServer = true
                    }
                    await checkServerStatusAsync()
                    await MainActor.run {
                        lastCheckTime = Date()
                        isCheckingServer = false
                    }
                }
            }) {
                HStack(spacing: 4) {
                    if isCheckingServer {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text("Verificar")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .disabled(isCheckingServer || authViewModel.isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    private var loginFormSection: some View {
        VStack(spacing: 20) {
            // Campo de usuario
            VStack(alignment: .leading, spacing: 5) {
                Text("Usuario")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                    
                    TextField("Ingresa tu nombre de usuario", text: $authViewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                        .disabled(authViewModel.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Campo de contraseña
            VStack(alignment: .leading, spacing: 5) {
                Text("Contraseña")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    
                    if showPassword {
                        TextField("Ingresa tu contraseña", text: $authViewModel.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit(login)
                            .disabled(authViewModel.isLoading)
                    } else {
                        SecureField("Ingresa tu contraseña", text: $authViewModel.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit(login)
                            .disabled(authViewModel.isLoading)
                    }
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .disabled(authViewModel.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Mensaje de error
            if !authViewModel.errorMessage.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Spacer()
                        
                        // Botón para mostrar detalles técnicos si están disponibles
                        if authViewModel.detailedErrorInfo != nil {
                            Button(action: {
                                showDetailedError.toggle()
                            }) {
                                Image(systemName: showDetailedError ? "chevron.up.circle" : "info.circle")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            .disabled(authViewModel.isLoading)
                        }
                    }
                    
                    // Detalles técnicos del error
                    if showDetailedError, let detailedInfo = authViewModel.detailedErrorInfo {
                        Text(detailedInfo)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 5)
            }
            
            // Información de fallback para modo offline
            if !serverIsReachable {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("El servidor local no está disponible. Puedes usar modo demo con usuario: admin y contraseña: password.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 5)
            }
            
            // Botones de inicio de sesión
            VStack(spacing: 15) {
                // Botón de inicio de sesión tradicional
                Button(action: login) {
                    if authViewModel.isLoading {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            
                            Text("Iniciando sesión...")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    } else {
                        Text("Iniciar Sesión")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(authViewModel.username.isEmpty || authViewModel.password.isEmpty || authViewModel.isLoading)
                .opacity(
                    (authViewModel.username.isEmpty || authViewModel.password.isEmpty || authViewModel.isLoading) 
                    ? 0.7 : 1.0
                )
                
                // Botón de autenticación biométrica - asegurarse que sea visible si está disponible
                if authViewModel.biometricType != .none {
                    Button(action: {
                        Task {
                            await authViewModel.loginWithBiometrics()
                        }
                    }) {
                        HStack {
                            Image(systemName: authViewModel.biometricType.iconName)
                                .font(.system(size: 18))
                            
                            Text("Iniciar con \(authViewModel.biometricType.description)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .disabled(authViewModel.isLoading)
                    .opacity(authViewModel.isLoading ? 0.7 : 1.0)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var footerSection: some View {
        VStack(spacing: 5) {
            if let lastCheck = lastCheckTime {
                Text("Última verificación: \(timeAgoString(from: lastCheck))")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)
            }
            
            HStack(spacing: 15) {
                Button(action: {
                    // Acción para recuperar contraseña
                }) {
                    Text("¿Olvidaste tu contraseña?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .disabled(authViewModel.isLoading)
                
                if authViewModel.biometricType != .none {
                    Button(action: {
                        authViewModel.toggleBiometricAuth(enabled: !authViewModel.isBiometricEnabled)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: authViewModel.isBiometricEnabled ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                            
                            Text("Recordar con \(authViewModel.biometricType.description)")
                                .font(.footnote)
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(authViewModel.isLoading)
                }
            }
            
            Text("© 2025 TryNet. Todos los derechos reservados.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 20) // Espacio adicional en la parte inferior para evitar el área del teclado
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            // Fondo semitransparente
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Contenedor con indicador de carga y mensaje
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Iniciando sesión...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.7))
            )
        }
        .transition(.opacity)
        .animation(.easeInOut, value: authViewModel.isLoading)
        .zIndex(100) // Asegura que esté por encima de todo
    }
    
    // Badge que muestra el estado de conexión con el servidor
    var serverStatusBadge: some View {
        HStack {
            if isCheckingServer {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.trailing, 2)
            } else {
                Image(systemName: serverIsReachable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(serverIsReachable ? .green : .orange)
            }
            
            Text(isCheckingServer ? "Verificando..." : 
                    (serverIsReachable ? "Servidor local conectado" : "Modo fallback activo"))
                .font(.caption)
                .foregroundColor(isCheckingServer ? .gray : (serverIsReachable ? .green : .orange))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(serverIsReachable ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(serverIsReachable ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Actions & Helpers
    
    private func login() {
        focusedField = nil
        
        #if DEBUG
        // En modo debug podemos usar el fallback para pruebas sin backend
        if ProcessInfo.processInfo.arguments.contains("--use-mock-api") || !serverIsReachable {
            authViewModel.loginFallback()
            return
        }
        #endif
        
        // Usar el login real
        authViewModel.login()
    }
    
    // Método asíncrono para verificar el estado del servidor sin bloquear la UI
    private func checkServerStatusAsync() async {
        // Creamos un Task para que no bloquee la UI
        await withCheckedContinuation { continuation in
            AuthService.shared.pingServer()
                .receive(on: DispatchQueue.main)
                .sink { isAvailable in
                    Task { @MainActor in
                        withAnimation {
                            serverIsReachable = isAvailable
                        }
                    }
                    continuation.resume()
                }
                .store(in: &AuthService.shared.cancellables)
        }
    }
    
    // Función para formatear el tiempo desde la última verificación
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.second, .minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day) día\(day == 1 ? "" : "s") atrás"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) hora\(hour == 1 ? "" : "s") atrás"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) minuto\(minute == 1 ? "" : "s") atrás"
        } else if let second = components.second {
            return "\(second) segundo\(second == 1 ? "" : "s") atrás"
        }
        return "ahora"
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
} 