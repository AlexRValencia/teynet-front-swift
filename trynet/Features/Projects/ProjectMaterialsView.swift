import SwiftUI

struct ProjectMaterialsView: View {
    let projectId: String
    let projectName: String
    
    @StateObject private var materialManager = ProjectMaterialManager.shared
    @State private var searchText: String = ""
    @State private var showingAddMaterialSheet = false
    @State private var selectedMaterial: ProjectMaterial? = nil
    @State private var selectedTab = 0
    
    // Estadísticas
    @State private var totalItems: Int = 0
    @State private var usedItems: Int = 0
    @State private var totalValue: Double = 0
    
    // Materiales filtrados
    private var filteredMaterials: [ProjectMaterial] {
        let materials = materialManager.getMaterialsForProject(projectId: projectId)
        
        if searchText.isEmpty {
            return materials
        }
        
        return materials.filter { material in
            material.name.lowercased().contains(searchText.lowercased()) ||
            material.category.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Encabezado con estadísticas
            materialsHeader
            
            // Barra de búsqueda
            searchBar
            
            // Lista de materiales
            materialsList
        }
        .navigationTitle("Materiales")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddMaterialSheet = true
                }) {
                    Label("Agregar", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMaterialSheet) {
            AddProjectMaterialView(projectId: projectId, projectName: projectName)
        }
        .sheet(item: $selectedMaterial) { material in
            MaterialDetailView(material: material)
        }
        .onAppear {
            updateStats()
        }
    }
    
    private var materialsHeader: some View {
        VStack(spacing: 8) {
            Text("Materiales para: \(projectName)")
                .font(.headline)
                .padding(.top, 16)
            
            HStack(spacing: 16) {
                ProjectMaterialStatCard(
                    title: "Total Asignados",
                    value: "\(totalItems)",
                    icon: "cube.box",
                    color: .blue
                )
                
                ProjectMaterialStatCard(
                    title: "Total Utilizados",
                    value: "\(usedItems)",
                    icon: "hammer",
                    color: .orange
                )
                
                ProjectMaterialStatCard(
                    title: "Valor Total",
                    value: "$\(String(format: "%.2f", totalValue))",
                    icon: "dollarsign.circle",
                    color: .green
                )
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Buscar materiales", text: $searchText)
                .autocapitalization(.none)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var materialsList: some View {
        List {
            if filteredMaterials.isEmpty {
                Text("No hay materiales asignados a este proyecto")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                ForEach(filteredMaterials) { material in
                    ProjectMaterialRow(material: material)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMaterial = material
                        }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func updateStats() {
        let stats = materialManager.getProjectMaterialStats(projectId: projectId)
        totalItems = stats.total
        usedItems = stats.used
        totalValue = stats.value
    }
}

// Componente para fila de material
struct ProjectMaterialRow: View {
    let material: ProjectMaterial
    
    private var materialStatus: MaterialStatus {
        return MaterialStatus.fromUsage(assigned: material.assignedQuantity, used: material.usedQuantity)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono de categoría
            ZStack {
                Circle()
                    .fill(Color(materialStatus.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: materialStatus.systemImage)
                    .foregroundColor(Color(materialStatus.color))
            }
            
            // Información del material
            VStack(alignment: .leading, spacing: 4) {
                Text(material.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(material.category)
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Text("Asignado: \(dateFormatter.string(from: material.dateAssigned))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Cantidades
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(material.usedQuantity)/\(material.assignedQuantity)")
                    .font(.subheadline)
                    .bold()
                
                // Barra de progreso
                MaterialProgressBar(value: material.usagePercentage)
                    .frame(width: 60, height: 4)
                
                Text(materialStatus.rawValue)
                    .font(.caption)
                    .foregroundColor(Color(materialStatus.color))
            }
        }
        .padding(.vertical, 4)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

// Componente de barra de progreso
struct MaterialProgressBar: View {
    let value: Double
    
    private var barColor: Color {
        if value <= 0.3 {
            return .blue
        } else if value <= 0.7 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fondo
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                
                // Barra de progreso
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: geometry.size.width * min(1, max(0, value)))
            }
        }
    }
}

// Componente de tarjeta de estadística
struct ProjectMaterialStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headline)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// Vista previa
struct ProjectMaterialsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProjectMaterialsView(projectId: "project1", projectName: "Instalación Torres Torreón")
        }
    }
} 