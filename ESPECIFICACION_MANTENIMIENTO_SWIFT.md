# Especificación de la Aplicación de Mantenimiento para Swift

Este documento detalla las especificaciones para recrear la funcionalidad de mantenimiento de la aplicación original de React Native en una nueva aplicación Swift.

## 1. Visión General

La aplicación original es una plataforma para gestionar diferentes tipos de mantenimiento (correctivo y preventivo) para diversos equipos técnicos. Los usuarios pueden registrar actividades de mantenimiento, tomar fotografías, añadir descripciones y documentar características específicas del equipo.

## 2. Modelos de Datos

### Tipos de Mantenimiento
```swift
enum TipoMantenimiento: String, Codable, CaseIterable, Identifiable {
    case preventivo = "Preventivo"
    case correctivo = "Correctivo"
    
    var id: String { self.rawValue }
    
    var descripcion: String {
        switch self {
        case .preventivo:
            return "Inspección visual de cables, cámaras, infraestructura, etc."
        case .correctivo:
            return "Reemplazo de hardware dañado, roto, configuración local del equipo, etc."
        }
    }
}
```

### Tipos de Equipo
```swift
enum TipoEquipo: String, Codable, CaseIterable, Identifiable {
    case arcoSeguridad = "Arco de seguridad"
    case plantaElectrica = "Planta eléctrica"
    case fibraOptica = "Fibra óptica"
    case videoWall = "Video wall"
    case equipoInformatico = "Equipo informático"
    case sistemaBiometrico = "Sistema biométrico"
    case sistemaSonido = "Sistema de sonido"
    case sistemaBacnet = "Sistema BACnet"
    
    var id: String { self.rawValue }
    
    var descripcionPorDefecto: String {
        switch self {
        case .arcoSeguridad:
            return "Mantenimiento de arco de seguridad"
        case .plantaElectrica:
            return "Mantenimiento de planta eléctrica"
        case .fibraOptica:
            return "Mantenimiento de fibra óptica"
        // Agregar más casos según necesidad
        default:
            return "Mantenimiento de \(self.rawValue.lowercased())"
        }
    }
}
```

### Registro de Mantenimiento
```swift
struct Mantenimiento: Identifiable, Codable {
    var id = UUID()
    var tipoMantenimiento: TipoMantenimiento
    var tipoEquipo: TipoEquipo
    var descripcion: String
    var imagenes: [Data] // Datos de UIImage codificados
    var fecha: Date
    var tecnicoId: String
    var ubicacion: String
    var notas: String?
    var equiposSeleccionados: [EquipoSeleccionado]
}
```

### Equipos Seleccionados
```swift
struct EquipoSeleccionado: Identifiable, Codable {
    var id = UUID()
    var tipoEquipo: TipoEquipo
    var nombre: String
    var valores: [String: String] // Valores específicos como cantidad, tipo, etc.
}
```

### Especificación de Equipo
```swift
struct EquipoEspecificacion {
    var nombre: String
    var opciones: [OpcionEquipo]
}

enum OpcionEquipo {
    case simple(String) // Nombre de un campo simple (ej: "Cantidad")
    case conOpciones(String, [String]) // Nombre y opciones (ej: "Tipo", ["Panorámica", "Fisheye"])
    
    var descripcion: String {
        switch self {
        case .simple(let nombre):
            return nombre
        case .conOpciones(let nombre, _):
            return nombre
        }
    }
}
```

## 3. Catálogo de Equipos

```swift
struct CatalogoEquipos {
    // Equipos para Video Wall
    static let equiposVideoWall: [EquipoEspecificacion] = [
        EquipoEspecificacion(
            nombre: "Pantallas",
            opciones: [
                .simple("Cantidad"),
                .conOpciones("Tipo", ["LCD", "LED", "OLED"])
            ]
        ),
        EquipoEspecificacion(
            nombre: "Controlador",
            opciones: [
                .simple("Cantidad"),
                .conOpciones("Marca", ["Samsung", "LG", "Phillips"])
            ]
        )
    ]
    
    // Equipos para Fibra Óptica
    static let equiposFibraOptica: [EquipoEspecificacion] = [
        EquipoEspecificacion(
            nombre: "Cables",
            opciones: [
                .simple("Metros"),
                .conOpciones("Tipo", ["Monomodo", "Multimodo"])
            ]
        ),
        EquipoEspecificacion(
            nombre: "Conectores",
            opciones: [
                .simple("Cantidad"),
                .conOpciones("Tipo", ["SC", "LC", "FC", "ST"])
            ]
        )
    ]
    
    // Método para obtener equipos según el tipo
    static func equiposPara(tipo: TipoEquipo) -> [EquipoEspecificacion] {
        switch tipo {
        case .videoWall:
            return equiposVideoWall
        case .fibraOptica:
            return equiposFibraOptica
        // Añadir más casos según sea necesario
        default:
            return []
        }
    }
}
```

## 4. Funcionalidades Principales

### Captura y Gestión de Imágenes
- Tomar fotos con la cámara del dispositivo
- Seleccionar imágenes de la galería
- Mostrar imágenes en una cuadrícula
- Eliminar imágenes seleccionadas

### Descripción de Mantenimiento
- Campo de texto para descripción detallada
- Validación de contenido mínimo

### Selección de Equipos
- Seleccionar tipo de equipo principal
- Seleccionar equipos específicos con sus características
- Entrada de datos para propiedades como cantidad, tipo, marca, etc.

### Almacenamiento
- Guardar registros localmente (en la versión inicial)
- Opción para exportar o sincronizar (futuras versiones)

## 5. Estructura de Pantallas

### 1. Pantalla Principal
- Botones para Mantenimiento Correctivo y Preventivo
- Opción para ver registros anteriores

### 2. Pantalla de Mantenimiento Correctivo
- Selector de tipo de equipo
- Sección para tomar/seleccionar fotos
- Campo de descripción
- Botón para seleccionar equipos específicos
- Botón de guardar/enviar

### 3. Pantalla de Selección de Equipos
- Lista de equipos disponibles según el tipo seleccionado
- Formularios dinámicos según las características de cada equipo
- Botón para confirmar selección

### 4. Pantalla de Historial de Mantenimientos
- Lista de mantenimientos realizados
- Filtros por tipo, fecha, equipo
- Detalles de cada registro al seleccionar

## 6. Arquitectura Propuesta

Se recomienda utilizar el patrón MVVM (Model-View-ViewModel) para la implementación en Swift:

### Modelos
- Estructuras de datos definidas en la sección 2
- Lógica de persistencia de datos

### Vistas
- Implementaciones SwiftUI para cada pantalla
- Componentes reutilizables (vista de cuadrícula de imágenes, selector de equipos)

### ViewModels
- Lógica de negocio para cada pantalla
- Manejo de estados de la UI
- Validación de formularios

## 7. Sugerencias de Implementación

### Selector de Imágenes
Utilizar `UIImagePickerController` o `PHPickerViewController` integrados con SwiftUI mediante `UIViewControllerRepresentable`.

### Persistencia de Datos
Para la versión inicial, se puede usar `UserDefaults` para almacenar los registros de mantenimiento. En versiones posteriores, considerar CoreData o Realm para una persistencia más robusta.

### Interfaz de Usuario
Utilizar componentes nativos de SwiftUI como:
- `List` para mostrar listas de elementos
- `Form` para formularios
- `TabView` para navegación entre secciones principales
- `NavigationView` para la navegación jerárquica

### Consideraciones de Rendimiento
- Optimizar el almacenamiento de imágenes (redimensionar antes de guardar)
- Implementar carga perezosa (lazy loading) para listas largas
- Considerar el manejo eficiente de memoria con imágenes grandes

## 8. Extensiones Futuras

### Sincronización en la Nube
- Implementar sincronización con un servidor para compartir registros entre dispositivos
- Almacenamiento de imágenes en servicios como Firebase Storage o AWS S3

### Notificaciones
- Recordatorios para mantenimientos preventivos programados
- Alertas para equipos con mantenimientos pendientes

### Exportación de Reportes
- Generar PDF con registros de mantenimiento
- Opciones para compartir por correo u otras aplicaciones

## 9. Requisitos Técnicos

### Permisos Necesarios
- Cámara
- Galería de fotos
- Almacenamiento

### Versiones Mínimas
- iOS 14.0 o superior (para mejor soporte de SwiftUI)
- Xcode 12 o superior

### Orientación
- Soportar tanto orientación vertical como horizontal en iPad
- Principalmente vertical en iPhone

## 10. Conclusiones

La aplicación de mantenimiento en Swift debe mantener todas las funcionalidades clave de la versión original en React Native, aprovechando las capacidades nativas de iOS para ofrecer una experiencia de usuario más fluida y eficiente. El enfoque MVVM propuesto facilitará el mantenimiento y la extensión del código a medida que la aplicación evolucione. 