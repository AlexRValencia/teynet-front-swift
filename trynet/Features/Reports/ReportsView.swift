import SwiftUI

struct ReportsView: View {
    @State private var selectedReportType = "Rendimiento"
    @State private var selectedPeriod = "Últimos 7 días"
    @State private var searchText = ""
    @Environment(\.isLandscape) private var isLandscape
    
    let reportTypes = ["Rendimiento", "Incidentes", "Costos", "Utilización"]
    let periods = ["Últimos 7 días", "Último mes", "Último trimestre", "Año actual"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLandscape {
                    // Diseño optimizado para orientación horizontal
                    HStack(alignment: .top, spacing: 16) {
                        // Panel izquierdo con controles
                        VStack(spacing: 16) {
                            // Barra de búsqueda y botón
                            searchAndAddBar
                            
                            // Selectores en formato vertical para landscape
                            VStack(spacing: 12) {
                                reportTypeSelector
                                periodSelector
                            }
                        }
                        .frame(width: 220)
                        .padding(.vertical)
                        
                        // Panel derecho con el gráfico
                        chartSection
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                } else {
                    // Diseño original para orientación vertical
                    // Barra de búsqueda y botón
                    searchAndAddBar
                        .padding(.horizontal)
                    
                    // Selectores horizontales
                    HStack {
                        reportTypeSelector
                        periodSelector
                    }
                    .padding(.horizontal)
                    
                    // Área del gráfico
                    chartSection
                        .padding(.horizontal)
                }
                
                // Lista de reportes recientes
                recentReportsList
            }
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
                
                TextField("Buscar reportes...", text: $searchText)
                
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
                // Acción para crear nuevo reporte
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
    
    // Selector de tipo de reporte
    var reportTypeSelector: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Tipo de Reporte")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Tipo de Reporte", selection: $selectedReportType) {
                ForEach(reportTypes, id: \.self) { type in
                    Text(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // Selector de período
    var periodSelector: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Período")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Período", selection: $selectedPeriod) {
                ForEach(periods, id: \.self) { period in
                    Text(period)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // Sección del gráfico
    var chartSection: some View {
        VStack {
            Text("\(selectedReportType) - \(selectedPeriod)")
                .font(.headline)
                .padding(.bottom, 10)
            
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: isLandscape ? 300 : 250) // Más alto en landscape
                
                if selectedReportType == "Rendimiento" {
                    PerformanceChartPlaceholder()
                } else if selectedReportType == "Incidentes" {
                    IncidentsChartPlaceholder()
                } else if selectedReportType == "Costos" {
                    CostChartPlaceholder()
                } else {
                    UtilizationChartPlaceholder()
                }
            }
            .cornerRadius(10)
        }
    }
    
    // Lista de reportes recientes
    var recentReportsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reportes recientes")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ReportCard(title: "Rendimiento Semanal", date: "12/05/2025", icon: "chart.line.uptrend.xyaxis", color: .blue)
                    ReportCard(title: "Incidentes Críticos", date: "10/05/2025", icon: "exclamationmark.triangle", color: .red)
                    ReportCard(title: "Utilización de Red", date: "08/05/2025", icon: "network", color: .green)
                    ReportCard(title: "Costos Operativos", date: "05/05/2025", icon: "dollarsign.circle", color: .purple)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 10)
    }
}

// Placeholders para los diferentes tipos de gráficos
struct PerformanceChartPlaceholder: View {
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.system(size: isLandscape ? 50 : 40))
            .foregroundColor(.blue.opacity(0.7))
            .overlay(
                Text("Gráfico de Rendimiento")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 60)
            )
    }
}

struct IncidentsChartPlaceholder: View {
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        Image(systemName: "chart.bar")
            .font(.system(size: isLandscape ? 50 : 40))
            .foregroundColor(.red.opacity(0.7))
            .overlay(
                Text("Gráfico de Incidentes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 60)
            )
    }
}

struct CostChartPlaceholder: View {
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        Image(systemName: "chart.pie")
            .font(.system(size: isLandscape ? 50 : 40))
            .foregroundColor(.purple.opacity(0.7))
            .overlay(
                Text("Gráfico de Costos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 60)
            )
    }
}

struct UtilizationChartPlaceholder: View {
    @Environment(\.isLandscape) private var isLandscape
    
    var body: some View {
        Image(systemName: "chart.xyaxis.line")
            .font(.system(size: isLandscape ? 50 : 40))
            .foregroundColor(.green.opacity(0.7))
            .overlay(
                Text("Gráfico de Utilización")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 60)
            )
    }
}

// Tarjeta para reportes recientes
struct ReportCard: View {
    var title: String
    var date: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("Descargar")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Image(systemName: "arrow.down.doc")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(width: 200, height: 130)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    ReportsView()
} 