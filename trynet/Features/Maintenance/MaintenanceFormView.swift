import SwiftUI
import PhotosUI
// Importaciones necesarias
import Foundation
// Comentamos la importación problemática
// import trynet.Features.Maintenance.MaintenanceTask

struct MaintenanceFormView: View {
    @Binding var isPresented: Bool
    var onSave: (MaintenanceTask) -> Void
    
    // Datos básicos
    @State private var deviceName = ""
    @State private var taskType = "Revisión"
    @State private var maintenanceType = "Preventivo"
    @State private var description = ""
    @State private var scheduledDate = Date()
    @State private var assignedTo = ""
    @State private var priority = "Media"
    @State private var location = "Torreón"
    @State private var siteName = ""
    
    // Datos adicionales de equipamiento
    @State private var showingEquipmentDetailsSheet = false
    @State private var damagedEquipment: [String] = []
    @State private var tempDamagedEquipment = ""
    @State private var cableInstalled: [String: String] = [:]
    @State private var tempCableType = "UTP"
    @State private var tempCableLength = ""
    
    // Colecciones para los pickers
    let taskTypes = ["Revisión", "Actualización", "Limpieza", "Reparación", "Instalación"]
    let maintenanceTypes = ["Preventivo", "Correctivo"]
    let priorities = ["Alta", "Media", "Baja"]
    let locationOptions = ["Acuña", "Piedras Negras", "Monclova", "Torreón", "Saltillo"]
    let cableTypes = ["UTP", "Eléctrico", "Fibra", "Coaxial", "HDMI"]
    
    // Placeholder para imágenes (en la versión real se usaría UIImagePicker)
    @State private var initialPhotos: [UIImage] = []
    @State private var finalPhotos: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var isCapturingInitialPhoto = true
    
    var body: some View {
        NavigationView {
            Form {
                // Sección 1: Información básica
                Section(header: Text("Información básica")) {
                    TextField("Nombre del dispositivo", text: $deviceName)
                    
                    Picker("Tipo de tarea", selection: $taskType) {
                        ForEach(taskTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Picker("Tipo de mantenimiento", selection: $maintenanceType) {
                        ForEach(maintenanceTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Picker("Prioridad", selection: $priority) {
                        ForEach(priorities, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                // Sección 2: Ubicación
                Section(header: Text("Ubicación")) {
                    Picker("Localidad", selection: $location) {
                        ForEach(locationOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    TextField("Nombre del sitio", text: $siteName)
                        .autocapitalization(.words)
                }
                
                // Sección 3: Detalles y asignación
                Section(header: Text("Detalles")) {
                    DatePicker("Fecha programada", selection: $scheduledDate, displayedComponents: .date)
                    
                    TextField("Asignado a", text: $assignedTo)
                        .autocapitalization(.words)
                    
                    VStack(alignment: .leading) {
                        Text("Descripción")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Sección 4: Equipo dañado
                Section(header: Text("Equipo dañado")) {
                    ForEach(damagedEquipment, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                            Button(action: {
                                if let index = damagedEquipment.firstIndex(of: item) {
                                    damagedEquipment.remove(at: index)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Agregar equipo dañado", text: $tempDamagedEquipment)
                        
                        Button(action: {
                            if !tempDamagedEquipment.isEmpty {
                                damagedEquipment.append(tempDamagedEquipment)
                                tempDamagedEquipment = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Sección 5: Cables instalados
                Section(header: Text("Cable instalado (metros)")) {
                    ForEach(Array(cableInstalled.keys.sorted()), id: \.self) { key in
                        if let value = cableInstalled[key], !value.isEmpty {
                            HStack {
                                Text(key)
                                Spacer()
                                Text("\(value) MTS")
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    cableInstalled.removeValue(forKey: key)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Picker("Tipo", selection: $tempCableType) {
                            ForEach(cableTypes, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                        
                        TextField("Metros", text: $tempCableLength)
                            .keyboardType(.numberPad)
                        
                        Button(action: {
                            if !tempCableLength.isEmpty {
                                cableInstalled[tempCableType] = tempCableLength
                                tempCableLength = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Sección 6: Fotos (simuladas en esta implementación)
                Section(header: Text("Fotografías")) {
                    Button(action: {
                        isCapturingInitialPhoto = true
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Capturar foto inicial")
                        }
                    }
                    
                    Button(action: {
                        isCapturingInitialPhoto = false
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Capturar foto final")
                        }
                    }
                    
                    // Mostrar miniaturas simuladas
                    if !initialPhotos.isEmpty {
                        Text("Fotos iniciales: \(initialPhotos.count)")
                            .font(.caption)
                    }
                    
                    if !finalPhotos.isEmpty {
                        Text("Fotos finales: \(finalPhotos.count)")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Nueva tarea")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    isPresented = false
                },
                trailing: Button("Guardar") {
                    saveTask()
                }
                .disabled(deviceName.isEmpty || description.isEmpty || assignedTo.isEmpty || siteName.isEmpty)
            )
            // Aquí se agregaría el ImagePicker en una implementación real
        }
    }
    
    private func saveTask() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let newTask = MaintenanceTask.createTask(
            deviceName: deviceName,
            taskType: taskType,
            maintenanceType: maintenanceType,
            description: description,
            scheduledDate: dateFormatter.string(from: scheduledDate),
            assignedTo: assignedTo,
            priority: priority,
            location: location,
            siteName: siteName,
            damagedEquipment: damagedEquipment,
            cableInstalled: cableInstalled,
            initialPhotos: initialPhotos,
            finalPhotos: finalPhotos
        )
        
        onSave(newTask)
    }
    
    // Método simulado para agregar fotos (en la versión real usaría UIImagePickerController)
    private func didSelectImage(_ image: UIImage) {
        if isCapturingInitialPhoto {
            initialPhotos.append(image)
        } else {
            finalPhotos.append(image)
        }
    }
}

// Vista para filtros avanzados
struct AdvancedFilterView: View {
    @Binding var selectedEquipmentFilter: String
    let equipmentTypes: [String]
    @Binding var dateRangeStart: Date?
    @Binding var dateRangeEnd: Date?
    @Binding var isPresented: Bool
    
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()
    @State private var useStartDate = false
    @State private var useEndDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tipo de Equipo")) {
                    Picker("Tipo de Equipo", selection: $selectedEquipmentFilter) {
                        ForEach(equipmentTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                Section(header: Text("Rango de Fechas")) {
                    Toggle("Filtrar por fecha inicial", isOn: $useStartDate)
                    
                    if useStartDate {
                        DatePicker("Desde", selection: $tempStartDate, displayedComponents: .date)
                    }
                    
                    Toggle("Filtrar por fecha final", isOn: $useEndDate)
                    
                    if useEndDate {
                        DatePicker("Hasta", selection: $tempEndDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filtros Avanzados")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    isPresented = false
                },
                trailing: Button("Aplicar") {
                    // Aplicar los filtros
                    dateRangeStart = useStartDate ? tempStartDate : nil
                    dateRangeEnd = useEndDate ? tempEndDate : nil
                    isPresented = false
                }
            )
            .onAppear {
                // Inicializar fechas temporales
                if let start = dateRangeStart {
                    tempStartDate = start
                    useStartDate = true
                }
                
                if let end = dateRangeEnd {
                    tempEndDate = end
                    useEndDate = true
                }
            }
        }
    }
}

struct MaintenanceFormView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceFormView(isPresented: .constant(true), onSave: { _ in })
    }
} 