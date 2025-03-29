import Foundation
import Combine
import SwiftUI

class ProjectViewModel: ObservableObject {
    // Estado de la lista de proyectos
    @Published var projects: [Project] = []
    @Published var filteredProjects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var searchText = ""
    @Published var hasLoadedProjects = false
    @Published var selectedStatusFilter: String? = nil
    
    // Servicios
    private let projectService = ProjectService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Configurar enlace entre searchText y filteredProjects
        $searchText
            .removeDuplicates()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.filterProjects(searchText: searchText)
            }
            .store(in: &cancellables)
        
        // Cargar proyectos al iniciar
        loadProjects()
    }
    
    // Filtrar proyectos basados en el texto de búsqueda
    func filterProjects(searchText: String) {
        if searchText.isEmpty && selectedStatusFilter == nil {
            // Si no hay filtros, mostrar todos los proyectos
            filteredProjects = projects
        } else {
            // Aplicar filtros
            filteredProjects = projects.filter { project in
                let matchesSearch = searchText.isEmpty || 
                                   project.name.localizedCaseInsensitiveContains(searchText) || 
                                   project.client.localizedCaseInsensitiveContains(searchText)
                
                let matchesStatus = selectedStatusFilter == nil || selectedStatusFilter == "Todos" || 
                                   project.status == selectedStatusFilter
                
                return matchesSearch && matchesStatus
            }
        }
    }
    
    // Aplicar filtro de estado
    func applyStatusFilter(_ status: String?) {
        selectedStatusFilter = status
        filterProjects(searchText: searchText)
    }
    
    // Cargar proyectos desde el servicio
    func loadProjects() {
        print("🔄 Cargando proyectos desde el API...")
        
        if isLoading {
            print("⚠️ Ya hay una carga en progreso, se omite esta solicitud")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        projectService.getProjects()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        print("❌ Error al cargar proyectos: \(error.message)")
                        self.errorMessage = "No se pudieron cargar los proyectos: \(error.message)"
                    }
                },
                receiveValue: { [weak self] projects in
                    guard let self = self else { return }
                    
                    print("✅ Lista de proyectos cargada: \(projects.count) proyectos")
                    
                    // Actualizar la lista ordenada
                    let sortedProjects = projects.sorted { $0.name < $1.name }
                    self.projects = sortedProjects
                    
                    // Aplicar filtro actual
                    self.filterProjects(searchText: self.searchText)
                    
                    // Limpiar cualquier mensaje de error previo
                    self.errorMessage = nil
                    
                    // Indicar que ya cargamos los datos
                    self.hasLoadedProjects = true
                    
                    // Ya no mostraremos mensaje de error cuando la lista esté vacía
                    // Solo registramos en consola para debugging
                    if sortedProjects.isEmpty {
                        print("ℹ️ No se encontraron proyectos en el servidor")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Método asíncrono para cargar proyectos
    @MainActor
    func refreshProjects() async {
        print("🔄 Recargando proyectos desde el API (async)...")
        
        // Evitamos múltiples cargas simultáneas
        if isLoading {
            print("⚠️ Ya hay una carga en progreso, se omite esta solicitud")
            return
        }
        
        // Indicamos que estamos cargando
        isLoading = true
        errorMessage = nil
        
        do {
            let projects = try await projectService.fetchProjects()
            
            print("✅ Lista de proyectos recargada: \(projects.count) proyectos")
            
            // Actualizar la lista ordenada
            let sortedProjects = projects.sorted { $0.name < $1.name }
            self.projects = sortedProjects
            
            // Aplicar filtro actual
            self.filterProjects(searchText: self.searchText)
            
            // Limpiar cualquier mensaje de error previo
            self.errorMessage = nil
            
            // Indicar que ya cargamos los datos
            self.hasLoadedProjects = true
            
            // Ya no mostraremos mensaje de error cuando la lista esté vacía
            // Solo registramos en consola para debugging
            if sortedProjects.isEmpty {
                print("ℹ️ No se encontraron proyectos en el servidor")
            }
            
            self.isLoading = false
        } catch let error as APIError {
            print("❌ Error al recargar proyectos: \(error.message)")
            
            // Información detallada para errores de decodificación
            if case .decodingError(let decodingError, let data) = error {
                print("📄 Error específico de decodificación: \(decodingError)")
                
                // Intentar identificar exactamente qué falló en la decodificación
                if let decodingError = decodingError as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        let errorDetail = "Falta la clave '\(key.stringValue)' en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                        print("🔑 \(errorDetail)")
                        self.errorMessage = "Error de formato en datos del servidor: \(errorDetail)"
                    case .valueNotFound(let type, let context):
                        let errorDetail = "Valor nulo para tipo \(type) en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                        print("📭 \(errorDetail)")
                        self.errorMessage = "Error de formato en datos del servidor: \(errorDetail)"
                    case .typeMismatch(let type, let context):
                        let errorDetail = "Tipo de dato incorrecto, se esperaba \(type) en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                        print("❌ \(errorDetail)")
                        self.errorMessage = "Error de formato en datos del servidor: \(errorDetail)"
                    default:
                        self.errorMessage = "Error al procesar datos del servidor: \(decodingError.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Error al procesar la respuesta: \(error.message)"
                }
                
                if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                    print("📊 Respuesta problemática: \(responseString)")
                }
            } else {
                self.errorMessage = "No se pudieron cargar los proyectos: \(error.message)"
            }
            
            self.isLoading = false
        } catch {
            print("❌ Error desconocido al recargar proyectos: \(error)")
            self.errorMessage = "Error desconocido al cargar los proyectos: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
} 