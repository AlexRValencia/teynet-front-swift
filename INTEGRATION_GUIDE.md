# Guía de Integración: Servicio de Mantenimiento con Backend

## Introducción

Hemos implementado un sistema completo para la comunicación entre el módulo de Mantenimiento de la aplicación y el backend. Esta implementación sigue el mismo patrón arquitectónico utilizado en otros módulos como Proyectos, utilizando Combine para gestionar operaciones asíncronas de manera reactiva.

## Arquitectura

La implementación sigue un patrón de arquitectura en capas:

1. **Capa de Modelo de Datos**: Define las estructuras de datos para las tareas de mantenimiento, etapas y fotos.
2. **Capa de Servicio**: `MaintenanceService.swift` - Comunicación directa con la API utilizando APIClient.
3. **Capa de Gestión**: `MaintenanceManager.swift` - Lógica de negocio y almacenamiento de estado.
4. **Capa de Vista**: `MaintenanceView.swift` y otras vistas - Interfaz de usuario.

## Archivos Principales

- **MaintenanceService.swift**: Nuevo servicio que maneja las comunicaciones con el backend.
- **MaintenanceManager.swift**: Actualizado para utilizar el servicio en lugar de datos locales.
- **MaintenanceView.swift**: Actualizado para mostrar estados de carga y errores.

## Puntos de Integración con el Backend

### Endpoints de API

El servicio implementa los siguientes endpoints:

- `GET /maintenance/tasks` - Obtener todas las tareas de mantenimiento
- `GET /maintenance/tasks/{id}` - Obtener una tarea específica
- `POST /maintenance/tasks` - Crear una nueva tarea
- `PUT /maintenance/tasks/{id}` - Actualizar una tarea existente
- `POST /maintenance/tasks/{id}/stages/complete` - Completar una etapa de mantenimiento
- `DELETE /maintenance/tasks/{id}` - Eliminar una tarea
- `POST /maintenance/tasks/{id}/support` - Solicitar apoyo para una tarea

### Flujo de datos

1. El usuario interactúa con la vista de mantenimiento
2. Las acciones del usuario se propagan al MaintenanceManager
3. MaintenanceManager utiliza MaintenanceService para comunicarse con el backend
4. Las respuestas del backend se transforman en modelos de dominio y se actualizan en MaintenanceManager
5. MaintenanceManager publica cambios que la vista consume para actualizarse

## DTOs (Data Transfer Objects)

Se han definido DTOs para la comunicación con el backend:

- `MaintenanceTaskDTO`: Representa una tarea de mantenimiento en el formato de API
- `MaintenanceStageDTO`: Representa una etapa de mantenimiento
- `MaintenancePhotoDTO`: Representa una foto de etapa de mantenimiento

Cada DTO tiene métodos para convertirse a modelos de dominio para uso interno de la aplicación.

## Manejo de Estados

El sistema maneja diversos estados:

- **Carga inicial**: Muestra un indicador de progreso mientras se cargan los datos.
- **Error**: Muestra un mensaje de error cuando la comunicación con el backend falla.
- **Modo Offline**: Si no hay conexión, carga datos de muestra para permitir el funcionamiento sin conexión.
- **Actualización**: Muestra indicadores durante operaciones de creación, actualización y eliminación.

## Gestión de Errores

- El sistema captura y muestra errores del backend de manera amigable
- Se implementa un sistema de reintentos para operaciones críticas
- Los errores de conexión muestran sugerencias apropiadas al usuario

## Cómo Usar

### Inicialización

El sistema se inicializa automáticamente cuando se carga la vista `MaintenanceView`. No se requieren acciones adicionales para la configuración básica.

### Carga de datos

Para cargar manualmente los datos desde el backend:

```swift
maintenanceManager.refreshTasks()
```

### Creación de una nueva tarea

```swift
let newTask = MaintenanceTask(
    id: UUID().uuidString,
    deviceName: "Nombre del dispositivo",
    taskType: "Tipo de tarea",
    maintenanceType: "Preventivo",
    description: "Descripción de la tarea",
    status: "Pendiente",
    scheduledDate: "10/04/2023",
    assignedTo: "Nombre del técnico",
    priority: "Alta",
    location: "Ubicación",
    siteName: "Nombre del sitio"
)

maintenanceManager.addTask(newTask)
```

### Actualización de una tarea

```swift
// Obtener la tarea existente
var task = existingTask
// Modificarla
task.status = "En desarrollo"
// Guardar los cambios
maintenanceManager.updateTask(task)
```

### Completar una etapa con una foto

```swift
maintenanceManager.completeStage(
    taskId: "id-de-la-tarea", 
    stageName: "Nombre de la etapa", 
    photo: uiImageObject
)
```

### Solicitar apoyo

```swift
maintenanceManager.requestSupport(
    taskId: "id-de-la-tarea",
    details: "Detalles de la solicitud de apoyo"
)
```

### Eliminar una tarea

```swift
maintenanceManager.deleteTask(id: "id-de-la-tarea")
```

## Mejores Prácticas

1. **Evite modificaciones directas al modelo**: Siempre utilice los métodos del MaintenanceManager para modificar datos.
2. **Propague errores adecuadamente**: No suprima errores, permita que lleguen al usuario cuando sea apropiado.
3. **Maneje correctamente los eventos de carga**: Utilice las propiedades `isLoading` y `errorMessage` del MaintenanceManager para actualizar la interfaz.
4. **Implemente almacenamiento en caché**: Para mejorar el rendimiento, considere almacenar datos en caché localmente.
5. **Realice pruebas exhaustivas**: Pruebe todos los escenarios, incluyendo casos de desconexión y reconexión.

## Configuración del Backend

El backend debe implementar los endpoints mencionados y debe devolver respuestas en el formato esperado. Consulte los modelos DTO para entender la estructura de datos esperada.

## Próximos Pasos

1. Implementar sincronización periódica en segundo plano
2. Añadir soporte para carga de múltiples imágenes por etapa
3. Implementar cache local para operaciones offline completas
4. Añadir sistema de notificaciones para actualización en tiempo real

## Resolución de Problemas

### Error de conexión

Si aparecen errores de conexión:
1. Verifique que la URL base en APIClient es correcta
2. Confirme que el backend está activo
3. Verifique la conectividad de red

### Error de decodificación

Si aparecen errores de decodificación:
1. Revise el formato de respuesta del backend
2. Asegúrese de que todos los campos requeridos estén presentes
3. Verifique que los tipos de datos sean correctos

### Errores de autorización

Si aparecen errores de autorización:
1. Verifique que el token de autorización sea válido
2. Confirme que el usuario tiene los permisos adecuados

## Conclusión

Esta implementación proporciona una base sólida para la comunicación entre el módulo de Mantenimiento de la aplicación y el backend. Siguiendo la estructura y pautas proporcionadas, debe ser posible extender la funcionalidad según sea necesario sin cambiar significativamente la arquitectura. 