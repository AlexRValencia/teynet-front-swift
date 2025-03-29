import SwiftUI

struct AddProjectMaterialView: View {
    let projectId: String
    let projectName: String
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var inventoryManager = InventoryManager.shared
    @StateObject private var materialManager = ProjectMaterialManager.shared
    
    @State private var selectedCategory: String = "Todos"
    @State private var searchText: String = ""
    @State private var selectedItem: InventoryItem? = nil
    @State private var assignQuantity: String = ""
    @State private var notes: String = ""
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Filtros de categoría
    private var filteredItems: [InventoryItem] {
        var items = inventoryManager.filteredItems
        
        // Filtrar por búsqueda si es necesario
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.lowercased().contains(searchText.lowercased()) ||
                (item.supplier ?? "").lowercased().contains(searchText.lowercased())
            }
        }
        
        // Solo mostrar items con stock disponible
        items = items.filter { $0.available > 0 }
        
        return items
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Encabezado
                headerView
                
                // Sección de búsqueda y filtros
                searchAndFilterSection
                
                if selectedItem != nil {
                    // Detalles del ítem seleccionado
                    selectedItemSection
                } else {
                    // Lista de items de inventario disponibles
                    inventoryItemsList
                }
            }
            .navigationTitle("Añadir Material")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: selectedItem != nil ? Button("Asignar") {
                    assignMaterial()
                }
                .disabled(!canAssign)
                : nil
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                inventoryManager.loadInventory()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Proyecto: \(projectName)")
                .font(.headline)
                .padding(.top, 16)
            
            Text("Selecciona los materiales que deseas asignar a este proyecto")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 8) {
            // Barra de búsqueda
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Buscar en inventario", text: $searchText)
                
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
            
            // Selector de categoría
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryButton(title: "Todos", isSelected: selectedCategory == "Todos") {
                        selectedCategory = "Todos"
                        inventoryManager.filterByCategory(nil)
                    }
                    
                    ForEach(InventoryItem.categories, id: \.self) { category in
                        CategoryButton(title: category, isSelected: selectedCategory == category) {
                            selectedCategory = category
                            inventoryManager.filterByCategory(category)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var selectedItemSection: some View {
        VStack(spacing: 16) {
            if let item = selectedItem {
                // Sección del ítem seleccionado
                VStack(spacing: 12) {
                    HStack {
                        Text("Material seleccionado:")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            // Deseleccionar ítem
                            selectedItem = nil
                            assignQuantity = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Información del ítem
                    HStack(alignment: .top, spacing: 12) {
                        // Icono de categoría
                        ZStack {
                            Circle()
                                .fill(categoryColor(for: item.category).opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: categoryIcon(for: item.category))
                                .foregroundColor(categoryColor(for: item.category))
                                .font(.title2)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                            
                            Text(item.category)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if let price = item.price {
                                Text("Precio: $\(String(format: "%.2f", price))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text("Disponibles: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(item.available)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .bold()
                                Text("de \(item.quantity)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Sección de cantidad a asignar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cantidad a asignar:")
                        .font(.headline)
                    
                    TextField("Cantidad", text: $assignQuantity)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if let quantity = Int(assignQuantity), quantity > item.available {
                        Text("Error: No hay suficientes unidades disponibles")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                // Sección de notas
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notas (opcional):")
                        .font(.headline)
                    
                    TextEditor(text: $notes)
                        .padding(4)
                        .frame(minHeight: 100)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    private var inventoryItemsList: some View {
        List {
            ForEach(filteredItems) { item in
                InventoryItemSelectionRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItem = item
                        assignQuantity = "1" // Valor predeterminado
                    }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .overlay(
            Group {
                if inventoryManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if filteredItems.isEmpty {
                    VStack {
                        Image(systemName: "cube.box")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No se encontraron artículos disponibles")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        
                        if !searchText.isEmpty {
                            Text("Intenta con otra búsqueda")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        )
    }
    
    private var canAssign: Bool {
        guard let item = selectedItem, 
              let quantity = Int(assignQuantity),
              quantity > 0,
              quantity <= item.available else {
            return false
        }
        return true
    }
    
    private func assignMaterial() {
        guard let item = selectedItem, 
              let quantity = Int(assignQuantity),
              quantity > 0 else {
            showAlert(title: "Error", message: "Por favor ingresa una cantidad válida")
            return
        }
        
        if quantity > item.available {
            showAlert(title: "Error", message: "No hay suficientes unidades disponibles")
            return
        }
        
        let success = materialManager.assignMaterialToProject(
            inventoryItemId: item.id,
            projectId: projectId,
            quantity: quantity,
            notes: notes.isEmpty ? nil : notes
        )
        
        if success {
            presentationMode.wrappedValue.dismiss()
        } else {
            showAlert(title: "Error", message: materialManager.errorMessage ?? "No se pudo asignar el material")
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Cámaras":
            return .blue
        case "Redes":
            return .green
        case "Cables":
            return .orange
        case "Accesorios":
            return .purple
        case "Servidores":
            return .red
        default:
            return .gray
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Cámaras":
            return "video"
        case "Redes":
            return "wifi"
        case "Cables":
            return "cable.connector"
        case "Accesorios":
            return "gear"
        case "Servidores":
            return "server.rack"
        default:
            return "cube.box"
        }
    }
}

struct InventoryItemSelectionRow: View {
    let item: InventoryItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono de categoría
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
            }
            
            // Información del artículo
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(item.category)
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    if let price = item.price {
                        Text("•")
                            .foregroundColor(.gray)
                        Text("$\(String(format: "%.2f", price))")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Disponibilidad
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(item.available)")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.blue)
                    
                    Text("disponibles")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Color basado en la categoría
    private var categoryColor: Color {
        switch item.category {
        case "Cámaras":
            return .blue
        case "Redes":
            return .green
        case "Cables":
            return .orange
        case "Accesorios":
            return .purple
        case "Servidores":
            return .red
        default:
            return .gray
        }
    }
    
    // Icono basado en la categoría
    private var categoryIcon: String {
        switch item.category {
        case "Cámaras":
            return "video"
        case "Redes":
            return "wifi"
        case "Cables":
            return "cable.connector"
        case "Accesorios":
            return "gear"
        case "Servidores":
            return "server.rack"
        default:
            return "cube.box"
        }
    }
} 