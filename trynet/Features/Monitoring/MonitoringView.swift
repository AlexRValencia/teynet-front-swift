import SwiftUI

struct MonitoringView: View {
    @State private var searchText = ""
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if isLandscape {
                    // Diseño optimizado para modo horizontal
                    HStack(alignment: .top, spacing: 16) {
                        // Panel izquierdo con controles
                        VStack(spacing: 16) {
                            // Barra de búsqueda y botón de añadir
                            searchAndAddBar
                            
                            // Resumen de estadísticas
                            VStack(spacing: 10) {
                                MonitoringStat(title: "Dispositivos activos", value: "18", icon: "checkmark.circle.fill", color: .green)
                                MonitoringStat(title: "Alertas activas", value: "3", icon: "exclamationmark.triangle.fill", color: .orange)
                                MonitoringStat(title: "Desconectados", value: "2", icon: "xmark.circle.fill", color: .red)
                            }
                        }
                        .frame(width: 220)
                        .padding(.vertical)
                        
                        // Panel derecho con lista de dispositivos
                        ScrollView {
                            deviceList
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                } else {
                    // Diseño original para modo vertical
                    // Barra de búsqueda y botón
                    searchAndAddBar
                        .padding(.horizontal)
                    
                    // Scroll horizontal con resumen de estadísticas
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            MonitoringStat(title: "Dispositivos activos", value: "18", icon: "checkmark.circle.fill", color: .green)
                            MonitoringStat(title: "Alertas activas", value: "3", icon: "exclamationmark.triangle.fill", color: .orange)
                            MonitoringStat(title: "Desconectados", value: "2", icon: "xmark.circle.fill", color: .red)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Lista de dispositivos
                    ScrollView {
                        deviceList
                            .padding(.horizontal)
                    }
                }
            }
            .toolbar(removing: .title)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .adaptToDeviceOrientation()
    }
    
    // MARK: - Componentes
    
    // Barra de búsqueda y botón de añadir
    var searchAndAddBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Buscar dispositivos...", text: $searchText)
                
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
                // Acción para añadir nuevo dispositivo
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
    
    // Lista de dispositivos
    var deviceList: some View {
        VStack(spacing: 15) {
            ForEach(1...5, id: \.self) { deviceId in
                if isLandscape {
                    // Tarjeta optimizada para landscape
                    LandscapeDeviceMonitorCard(
                        deviceId: "Dispositivo \(deviceId)",
                        status: deviceId % 3 == 0 ? "Inactivo" : "Activo",
                        lastUpdate: "Hace \(deviceId * 5) minutos"
                    )
                } else {
                    // Tarjeta original
                    DeviceMonitorCard(
                        deviceId: "Dispositivo \(deviceId)",
                        status: deviceId % 3 == 0 ? "Inactivo" : "Activo",
                        lastUpdate: "Hace \(deviceId * 5) minutos"
                    )
                }
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Componentes visuales

struct MonitoringStat: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        if isLandscape {
            // Diseño horizontal para landscape
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
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
            .frame(width: 200)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        } else {
            // Diseño vertical para portrait
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 160, height: 90)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        }
    }
}

struct DeviceMonitorCard: View {
    var deviceId: String
    var status: String
    var lastUpdate: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(deviceId)
                    .font(.headline)
                
                Spacer()
                
                Circle()
                    .fill(status == "Activo" ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(status == "Activo" ? .green : .red)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("CPU: 42%")
                    Text("Memoria: 1.2GB/4GB")
                    Text("Temperatura: 62°C")
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Conexión: 6 Mbps")
                    Text("Alertas: 0")
                    Text(lastUpdate)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// Versión optimizada para landscape
struct LandscapeDeviceMonitorCard: View {
    var deviceId: String
    var status: String
    var lastUpdate: String
    
    var body: some View {
        HStack(spacing: 20) {
            // Información de identidad y estado
            VStack(alignment: .leading, spacing: 8) {
                Text(deviceId)
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(status == "Activo" ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Text(status)
                        .font(.caption)
                        .foregroundColor(status == "Activo" ? .green : .red)
                }
                
                Text(lastUpdate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 150)
            
            // Información de rendimiento
            HStack(spacing: 30) {
                // Columna 1
                VStack(alignment: .leading, spacing: 8) {
                    Text("CPU: 42%")
                    Text("Memoria: 1.2GB/4GB")
                    Text("Temperatura: 62°C")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Columna 2
                VStack(alignment: .leading, spacing: 8) {
                    Text("Conexión: 6 Mbps")
                    Text("Alertas: 0")
                    Text("Uptime: 5d 3h")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Botones de acción
                VStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "arrow.clockwise.circle")
                            .foregroundColor(.blue)
                    }
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                }
                .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    MonitoringView()
} 