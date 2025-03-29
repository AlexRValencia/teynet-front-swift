import SwiftUI

struct UserHistoryView: View {
    @ObservedObject var viewModel: UserAdminViewModel
    let userId: String
    let userName: String
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Título y botón de cierre
            HStack {
                Text("Historial de \(userName)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Contenido
            ZStack {
                if viewModel.isLoadingHistory && viewModel.selectedUserHistory.isEmpty {
                    ProgressView("Cargando historial...")
                } else if let error = viewModel.historyError {
                    errorView(error: error)
                } else if viewModel.selectedUserHistory.isEmpty {
                    emptyHistoryView()
                } else {
                    historyListView()
                }
            }
            .onAppear {
                viewModel.loadUserHistory(userId: userId)
            }
        }
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
    }
    
    // Vista de error
    func errorView(error: Error) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.largeTitle)
                .padding()
            
            Text("Error al cargar el historial")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error.localizedDescription)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Reintentar") {
                viewModel.loadUserHistory(userId: userId)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    // Vista de historial vacío
    func emptyHistoryView() -> some View {
        VStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.gray)
                .font(.largeTitle)
                .padding()
            
            Text("No hay historial disponible")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // Vista de lista de historial
    func historyListView() -> some View {
        VStack(spacing: 0) {
            // Lista de eventos de historial
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.selectedUserHistory) { historyItem in
                        HistoryItemView(historyItem: historyItem)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    if viewModel.isLoadingHistory {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.bottom, 16)
            }
            
            paginationView()
        }
    }
    
    // Vista de paginación
    func paginationView() -> some View {
        Group {
            if viewModel.historyTotalPages > 1 {
                HStack {
                    Button(action: {
                        viewModel.previousHistoryPage()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(viewModel.historyPage > 1 ? .blue : .gray)
                    }
                    .disabled(viewModel.historyPage <= 1)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    
                    Text("Página \(viewModel.historyPage) de \(viewModel.historyTotalPages)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        viewModel.nextHistoryPage()
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(viewModel.historyPage < viewModel.historyTotalPages ? .blue : .gray)
                    }
                    .disabled(viewModel.historyPage >= viewModel.historyTotalPages)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemGray6))
            }
        }
    }
}

struct HistoryItemView: View {
    let historyItem: UserHistory
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView()
            
            // Detalles (solo si está expandido)
            if showDetails {
                detailsView()
            }
        }
    }
    
    // Vista del encabezado
    func headerView() -> some View {
        HStack {
            // Icono según el tipo de acción
            iconView()
            
            // Información principal
            infoView()
            
            Spacer()
            
            // Botón para expandir/contraer detalles
            Button(action: {
                withAnimation {
                    showDetails.toggle()
                }
            }) {
                Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Vista del icono
    func iconView() -> some View {
        Image(systemName: iconForAction(historyItem.action))
            .foregroundColor(colorForAction(historyItem.action))
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(colorForAction(historyItem.action).opacity(0.2))
            )
    }
    
    // Vista de la información principal
    func infoView() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Título de la acción
            Text(titleForAction(historyItem.action))
                .font(.headline)
                .foregroundColor(.primary)
            
            // Fecha y hora
            Text(formattedDate(historyItem.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Vista de los detalles
    func detailsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cambios (si hay)
            changesView()
            
            // Datos previos (si hay)
            previousDataView()
            
            // Notas (si hay)
            notesView()
            
            // Información de la sesión
            sessionInfoView()
            
            // Creado por (si hay)
            createdByView()
        }
        .padding(.leading, 36)
        .transition(.opacity)
    }
    
    // Vista de los datos previos
    func previousDataView() -> some View {
        Group {
            if let previousData = historyItem.previousData, !previousData.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Datos anteriores:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    changesListView(changes: previousData)
                }
            }
        }
    }
    
    // Vista de la información de la sesión
    func sessionInfoView() -> some View {
        Group {
            if historyItem.ipAddress != nil || historyItem.userAgent != nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Información de conexión:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let ipAddress = historyItem.ipAddress {
                            HStack(alignment: .top) {
                                Image(systemName: "network")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("IP: \(ipAddress)")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let userAgent = historyItem.userAgent {
                            HStack(alignment: .top) {
                                Image(systemName: "desktopcomputer")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("Dispositivo: \(formatUserAgent(userAgent))")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // Vista de las notas
    func notesView() -> some View {
        Group {
            if let notes = historyItem.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notas:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // Vista de los cambios
    func changesView() -> some View {
        Group {
            if let changes = historyItem.changes, !changes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cambios:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    changesListView(changes: changes)
                }
            }
        }
    }
    
    // Vista de la lista de cambios
    func changesListView(changes: [String: AnyCodable]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(changes.keys.sorted()), id: \.self) { key in
                if let value = changes[key] {
                    HStack(alignment: .top) {
                        Text(formatFieldName(key) + ":")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        
                        Text(formatValue(value))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // Formatear valor de AnyCodable a String
    func formatValue(_ anyCodable: AnyCodable) -> String {
        if let value = anyCodable.value as? String {
            return value
        } else if let value = anyCodable.value as? Int {
            return String(value)
        } else if let value = anyCodable.value as? Double {
            return String(format: "%.2f", value)
        } else if let value = anyCodable.value as? Bool {
            return value ? "Sí" : "No"
        } else if anyCodable.value is NSNull {
            return "No asignado"
        } else if let array = anyCodable.value as? [Any] {
            return "\(array.count) elementos"
        } else if let dict = anyCodable.value as? [String: Any] {
            return "\(dict.count) campos"
        } else {
            return "Valor desconocido"
        }
    }
    
    // Vista de creado por
    func createdByView() -> some View {
        Group {
            if let createdByName = historyItem.createdByName {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Realizado por:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text(createdByName)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // Formato para la fecha
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
    
    // Icono según la acción
    func iconForAction(_ action: String) -> String {
        switch action.lowercased() {
        case "create": return "plus.circle"
        case "update": return "pencil"
        case "delete": return "trash"
        case "password_change": return "key"
        case "login": return "person.fill.checkmark"
        case "logout": return "person.fill.xmark"
        case "failed_login": return "exclamationmark.shield"
        default: return "clock.arrow.circlepath"
        }
    }
    
    // Color según la acción
    func colorForAction(_ action: String) -> Color {
        switch action.lowercased() {
        case "create": return .green
        case "update": return .blue
        case "delete": return .red
        case "password_change": return .orange
        case "login": return .green
        case "logout": return .gray
        case "failed_login": return .red
        default: return .secondary
        }
    }
    
    // Título según la acción
    func titleForAction(_ action: String) -> String {
        switch action.lowercased() {
        case "create": return "Usuario creado"
        case "update": return "Datos actualizados"
        case "delete": return "Usuario eliminado"
        case "password_change": return "Contraseña cambiada"
        case "login": return "Inicio de sesión"
        case "logout": return "Cierre de sesión"
        case "failed_login": return "Intento de inicio fallido"
        default: return action.capitalized
        }
    }
    
    // Formatear nombre de campo
    func formatFieldName(_ field: String) -> String {
        switch field {
        case "username": return "Usuario"
        case "fullName": return "Nombre"
        case "role": return "Rol"
        case "status": return "Estado"
        case "password": return "Contraseña"
        default: return field.capitalized
        }
    }
    
    // Formatea el agente de usuario para mostrar información más legible
    func formatUserAgent(_ userAgent: String) -> String {
        // Simplificar el user agent para mostrar información relevante
        if userAgent.contains("CFNetwork") {
            return "Aplicación iOS"
        } else if userAgent.contains("Mozilla") && userAgent.contains("Safari") {
            return "Navegador Safari"
        } else if userAgent.contains("Chrome") {
            return "Navegador Chrome"
        } else if userAgent.contains("Firefox") {
            return "Navegador Firefox"
        } else {
            return userAgent
        }
    }
}

// Para la vista previa
struct UserHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = UserAdminViewModel()
        UserHistoryView(viewModel: viewModel, userId: "123", userName: "Juan Pérez")
    }
} 