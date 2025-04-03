import SwiftUI

// Importamos el modelo InventoryItem desde el módulo principal
import Foundation
import UIKit // Aseguramos la importación correcta de UIKit

// Importamos el modelo InventoryItem
struct InventoryView: View {
    @StateObject private var inventoryManager = InventoryManager.shared
    @State private var selectedCategory: String = "Todos"
    @State private var searchText: String = ""
    @State private var showingAddItemSheet = false
    @State private var showingItemDetailSheet = false
    @State private var selectedItem: InventoryItem? = nil
    
    // Estadísticas de resumen
    @State private var totalItems: Int = 0
    @State private var totalValue: Double = 0
    @State private var lowStockCount: Int = 0
    @State private var outOfStockCount: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header con estadísticas
                inventoryHeader
                
                // Filtros y búsqueda
                filterBar
                
                // Lista de inventario
                inventoryList
            }
            .navigationTitle("Inventario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItemSheet = true
                    }) {
                        Label("Agregar", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                AddInventoryItemView(inventoryManager: inventoryManager)
            }
            .sheet(item: $selectedItem) { item in
                InventoryItemDetailView(item: item, inventoryManager: inventoryManager)
            }
            .onAppear {
                updateStats()
                inventoryManager.loadInventory()
            }
            .onChange(of: inventoryManager.inventoryItems) { _, newValue in
                updateStats()
            }
            .onChange(of: searchText) { _, newValue in
                inventoryManager.searchItems(query: newValue)
            }
        }
    }
    
    private var inventoryHeader: some View {
        VStack(spacing: 8) {
            Text("Resumen de Inventario")
                .font(.headline)
                .padding(.top, 16)
            
            HStack(spacing: 16) {
                StatCard(title: "Total Artículos", value: "\(totalItems)", icon: "cube.box", color: .blue)
                StatCard(title: "Valor Total", value: "$\(String(format: "%.2f", totalValue))", icon: "dollarsign.circle", color: .green)
            }
            
            HStack(spacing: 16) {
                StatCard(title: "Bajo Stock", value: "\(lowStockCount)", icon: "exclamationmark.triangle", color: .orange)
                StatCard(title: "Sin Stock", value: "\(outOfStockCount)", icon: "xmark.circle", color: .red)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private var filterBar: some View {
        VStack(spacing: 8) {
            // Barra de búsqueda
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Buscar en inventario", text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        inventoryManager.searchItems(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        inventoryManager.searchItems(query: "")
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
    
    private var inventoryList: some View {
        List {
            ForEach(inventoryManager.filteredItems) { item in
                InventoryItemRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItem = item
                    }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .overlay(
            Group {
                if inventoryManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if inventoryManager.filteredItems.isEmpty {
                    VStack {
                        Image(systemName: "cube.box")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No se encontraron artículos")
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
    
    // Función para actualizar las estadísticas
    private func updateStats() {
        totalItems = inventoryManager.inventoryItems.count
        totalValue = inventoryManager.getTotalInventoryValue()
        lowStockCount = inventoryManager.getLowStockItems().count
        outOfStockCount = inventoryManager.getOutOfStockCount()
    }
}

// Componente de fila de artículo de inventario
struct InventoryItemRow: View {
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
                    Text("\(item.available)/\(item.quantity)")
                        .font(.subheadline)
                        .bold()
                    
                    Text("disp.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // Barra de disponibilidad
                AvailabilityBar(available: item.available, total: item.quantity)
                    .frame(width: 60, height: 4)
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

// Componente de barra de disponibilidad
struct AvailabilityBar: View {
    let available: Int
    let total: Int
    
    private var ratio: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(available) / CGFloat(total)
    }
    
    private var barColor: Color {
        if ratio <= 0.2 {
            return .red
        } else if ratio <= 0.5 {
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
                    .frame(width: geometry.size.width * ratio)
            }
        }
    }
}

// Componente de botón de categoría
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// Componente de tarjeta de estadística
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// Vista para agregar un nuevo artículo al inventario
struct AddInventoryItemView: View {
    @Environment(\.presentationMode) var presentationMode
    let inventoryManager: InventoryManager
    
    @State private var name: String = ""
    @State private var category: String = InventoryItem.categories.first ?? ""
    @State private var quantity: String = ""
    @State private var location: String = InventoryItem.locations.first ?? ""
    @State private var price: String = ""
    @State private var supplier: String = ""
    @State private var serialNumber: String = ""
    @State private var notes: String = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información Básica")) {
                    TextField("Nombre", text: $name)
                    
                    Picker("Categoría", selection: $category) {
                        ForEach(InventoryItem.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    TextField("Cantidad", text: $quantity)
                        .keyboardType(.numberPad)
                    
                    Picker("Ubicación", selection: $location) {
                        ForEach(InventoryItem.locations, id: \.self) { location in
                            Text(location).tag(location)
                        }
                    }
                }
                
                Section(header: Text("Detalles adicionales")) {
                    TextField("Precio unitario ($)", text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextField("Proveedor", text: $supplier)
                    
                    TextField("Número de serie", text: $serialNumber)
                }
                
                Section(header: Text("Notas")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Nuevo Artículo")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Guardar") {
                    saveItem()
                }
                .disabled(name.isEmpty || quantity.isEmpty)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveItem() {
        guard let quantityInt = Int(quantity) else {
            alertMessage = "Por favor ingresa una cantidad válida"
            showAlert = true
            return
        }
        
        let priceDouble = Double(price) ?? 0.0
        
        let newItem = InventoryItem(
            id: UUID().uuidString,
            name: name,
            category: category,
            quantity: quantityInt,
            available: quantityInt, // Al inicio, todos están disponibles
            location: location,
            price: priceDouble > 0 ? priceDouble : nil,
            supplier: supplier.isEmpty ? nil : supplier,
            serialNumber: serialNumber.isEmpty ? nil : serialNumber,
            notes: notes.isEmpty ? nil : notes
        )
        
        inventoryManager.addItem(newItem)
        presentationMode.wrappedValue.dismiss()
    }
}

// Vista de detalle del artículo
struct InventoryItemDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let item: InventoryItem
    let inventoryManager: InventoryManager
    
    @State private var isEditing = false
    @State private var updatedItem: InventoryItem
    @State private var showDeleteConfirmation = false
    
    init(item: InventoryItem, inventoryManager: InventoryManager) {
        self.item = item
        self.inventoryManager = inventoryManager
        _updatedItem = State(initialValue: item)
    }
    
    var body: some View {
        NavigationView {
            Form {
                if isEditing {
                    editingView
                } else {
                    detailView
                }
            }
            .navigationTitle(isEditing ? "Editar Artículo" : "Detalle de Artículo")
            .navigationBarItems(
                leading: Button(isEditing ? "Cancelar" : "Cerrar") {
                    if isEditing {
                        // Restaurar el ítem original
                        updatedItem = item
                        isEditing = false
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                trailing: HStack {
                    if !isEditing {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        
                        Button("Editar") {
                            isEditing = true
                        }
                    } else {
                        Button("Guardar") {
                            inventoryManager.updateItem(updatedItem)
                            isEditing = false
                        }
                    }
                }
            )
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Eliminar Artículo"),
                    message: Text("¿Estás seguro que deseas eliminar \(item.name)? Esta acción no se puede deshacer."),
                    primaryButton: .destructive(Text("Eliminar")) {
                        inventoryManager.deleteItem(id: item.id)
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private var detailView: some View {
        Group {
            Section(header: Text("Información Básica")) {
                InventoryDetailRow(label: "Nombre", value: item.name)
                InventoryDetailRow(label: "Categoría", value: item.category)
                InventoryDetailRow(label: "Cantidad", value: "\(item.quantity)")
                InventoryDetailRow(label: "Disponible", value: "\(item.available)")
                InventoryDetailRow(label: "Ubicación", value: item.location)
            }
            
            Section(header: Text("Detalles adicionales")) {
                if let price = item.price {
                    InventoryDetailRow(label: "Precio unitario", value: "$\(String(format: "%.2f", price))")
                }
                
                if let supplier = item.supplier {
                    InventoryDetailRow(label: "Proveedor", value: supplier)
                }
                
                if let serialNumber = item.serialNumber {
                    InventoryDetailRow(label: "Número de serie", value: serialNumber)
                }
                
                if let lastCheckDate = item.lastCheckDate {
                    InventoryDetailRow(label: "Última verificación", value: lastCheckDate)
                }
            }
            
            if let notes = item.notes, !notes.isEmpty {
                Section(header: Text("Notas")) {
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            
            Section(header: Text("Acciones")) {
                Button(action: {
                    // Aquí iría la lógica para registrar asignación a proyecto
                }) {
                    Label("Asignar a Proyecto", systemImage: "arrow.right.circle")
                        .foregroundColor(.blue)
                }
                .disabled(item.available <= 0)
                
                Button(action: {
                    // Aquí iría la lógica para registrar una verificación de inventario
                }) {
                    Label("Registrar Verificación", systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    // Aquí iría la lógica para generar un reporte QR
                }) {
                    Label("Generar Código QR", systemImage: "qrcode")
                        .foregroundColor(.purple)
                }
            }
        }
    }
    
    private var editingView: some View {
        Group {
            Section(header: Text("Información Básica")) {
                TextField("Nombre", text: $updatedItem.name)
                
                Picker("Categoría", selection: $updatedItem.category) {
                    ForEach(InventoryItem.categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                
                HStack {
                    Text("Cantidad")
                    Spacer()
                    TextField("Cantidad", value: $updatedItem.quantity, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Disponible")
                    Spacer()
                    TextField("Disponible", value: $updatedItem.available, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                Picker("Ubicación", selection: $updatedItem.location) {
                    ForEach(InventoryItem.locations, id: \.self) { location in
                        Text(location).tag(location)
                    }
                }
            }
            
            Section(header: Text("Detalles adicionales")) {
                HStack {
                    Text("Precio unitario ($)")
                    Spacer()
                    TextField("Precio", value: $updatedItem.price as Binding<Double?>, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                TextField("Proveedor", text: Binding(
                    get: { updatedItem.supplier ?? "" },
                    set: { updatedItem.supplier = $0.isEmpty ? nil : $0 }
                ))
                
                TextField("Número de serie", text: Binding(
                    get: { updatedItem.serialNumber ?? "" },
                    set: { updatedItem.serialNumber = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Section(header: Text("Notas")) {
                TextEditor(text: Binding(
                    get: { updatedItem.notes ?? "" },
                    set: { updatedItem.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
            }
        }
    }
    
    private func lastCheckDateFormatted(_ dateString: String) -> String {
        return dateString
    }
}

// Componente para fila de detalle
struct InventoryDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

// Vista previa
struct InventoryView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryView()
    }
} 