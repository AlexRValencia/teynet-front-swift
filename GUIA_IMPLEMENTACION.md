# Guía de Implementación: Backend para el Módulo de Mantenimiento

## Introducción

Esta guía proporciona las instrucciones necesarias para implementar un backend que se integre correctamente con el módulo de mantenimiento de la aplicación. La aplicación utiliza Swift Combine para manejar las operaciones asíncronas y espera una serie de endpoints específicos.

## Requisitos del Backend

### Endpoints Necesarios

El backend debe implementar los siguientes endpoints REST:

1. **GET /maintenance/tasks**
   - Devuelve todas las tareas de mantenimiento
   - Formato de respuesta: `{ "tasks": [...], "totalCount": 123 }`

2. **GET /maintenance/tasks/{id}**
   - Devuelve una tarea específica por su ID
   - Formato de respuesta: Un objeto `MaintenanceTaskDTO`

3. **POST /maintenance/tasks**
   - Crea una nueva tarea de mantenimiento
   - Cuerpo de la petición: Objeto con propiedades de la tarea
   - Formato de respuesta: La tarea creada como `MaintenanceTaskDTO`

4. **PUT /maintenance/tasks/{id}**
   - Actualiza una tarea existente
   - Cuerpo de la petición: Objeto con propiedades a actualizar
   - Formato de respuesta: La tarea actualizada como `MaintenanceTaskDTO`

5. **POST /maintenance/tasks/{id}/stages/complete**
   - Marca una etapa de una tarea como completada
   - Cuerpo de la petición: Incluye `stageName`, `photoData` (base64), `photoCaption` y `timestamp`
   - Formato de respuesta: La tarea actualizada como `MaintenanceTaskDTO`

6. **DELETE /maintenance/tasks/{id}**
   - Elimina una tarea de mantenimiento
   - Formato de respuesta: Objeto vacío o indicador de éxito

7. **POST /maintenance/tasks/{id}/support**
   - Solicita apoyo para una tarea
   - Cuerpo de la petición: Incluye `details` con la descripción de la solicitud
   - Formato de respuesta: La tarea actualizada como `MaintenanceTaskDTO`

### Formato de Datos (DTOs)

#### MaintenanceTaskDTO

```json
{
  "id": "string",
  "deviceName": "string",
  "taskType": "string",
  "maintenanceType": "string", 
  "description": "string",
  "status": "string",
  "scheduledDate": "dd/MM/yyyy",
  "completedDate": "dd/MM/yyyy",
  "assignedTo": "string",
  "priority": "string",
  "location": "string",
  "siteName": "string",
  "stages": [MaintenanceStageDTO],
  "supportRequested": boolean,
  "supportRequestDetails": "string"
}
```

#### MaintenanceStageDTO

```json
{
  "name": "string",
  "description": "string",
  "percentageValue": double,
  "isCompleted": boolean,
  "photos": [MaintenancePhotoDTO]
}
```

#### MaintenancePhotoDTO

```json
{
  "imageUrl": "string",
  "imageData": "string", // Base64
  "imageName": "string",
  "caption": "string",
  "timestamp": "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
}
```

## Autenticación

La autenticación se maneja a través de tokens JWT. El backend debe:

1. Validar un token JWT incluido en el encabezado `Authorization` como `Bearer {token}`
2. Devolver errores 401 si el token no es válido o ha expirado
3. Implementar la renovación de tokens según sea necesario

## Gestión de Errores

El backend debe devolver errores en el siguiente formato:

```json
{
  "error": true,
  "message": "Descripción del error",
  "code": "ERROR_CODE"
}
```

Los códigos de error recomendados son:
- `INVALID_TOKEN`: Token de autenticación inválido
- `NOT_FOUND`: Recurso no encontrado
- `VALIDATION_ERROR`: Datos de entrada inválidos
- `SERVER_ERROR`: Error interno del servidor

## Manejo de Imágenes

El endpoint para completar etapas recibe imágenes en formato base64. El backend debe:

1. Decodificar las imágenes base64
2. Guardarlas en un sistema de almacenamiento (sistema de archivos, S3, etc.)
3. Opcionalmente, generar URLs para acceder a ellas posteriormente
4. Devolver las URLs en el campo `imageUrl` de `MaintenancePhotoDTO`

## Implementación de Ejemplo (Node.js/Express)

A continuación, se muestra un ejemplo básico de implementación usando Node.js y Express:

```javascript
const express = require('express');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const app = express();

app.use(bodyParser.json({ limit: '50mb' }));

// Middleware de autenticación
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: true,
      message: 'Token de autenticación requerido',
      code: 'INVALID_TOKEN'
    });
  }
  
  const token = authHeader.split(' ')[1];
  try {
    const user = jwt.verify(token, 'your-secret-key');
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({
      error: true,
      message: 'Token inválido o expirado',
      code: 'INVALID_TOKEN'
    });
  }
}

// Endpoints de mantenimiento
app.get('/maintenance/tasks', authenticate, (req, res) => {
  // Implementación para obtener tareas
  // Consultar base de datos, etc.
  res.json({
    tasks: [
      // Array de MaintenanceTaskDTO
    ],
    totalCount: 10
  });
});

app.get('/maintenance/tasks/:id', authenticate, (req, res) => {
  // Obtener tarea específica
});

app.post('/maintenance/tasks', authenticate, (req, res) => {
  // Crear nueva tarea
});

app.put('/maintenance/tasks/:id', authenticate, (req, res) => {
  // Actualizar tarea existente
});

app.post('/maintenance/tasks/:id/stages/complete', authenticate, (req, res) => {
  // Completar etapa
  // Procesar imagen en base64
  const { stageName, photoData, photoCaption, timestamp } = req.body;
  
  // Decodificar y guardar imagen
  const imageBuffer = Buffer.from(photoData, 'base64');
  // Guardar en sistema de archivos o servicio de almacenamiento
  
  // Devolver tarea actualizada
});

app.delete('/maintenance/tasks/:id', authenticate, (req, res) => {
  // Eliminar tarea
  res.json({ success: true });
});

app.post('/maintenance/tasks/:id/support', authenticate, (req, res) => {
  // Solicitar apoyo
});

app.listen(3000, () => {
  console.log('API de mantenimiento ejecutándose en puerto 3000');
});
```

## Pruebas y Validación

Para validar que su backend funciona correctamente con la aplicación:

1. Implemente los endpoints descritos
2. Configure la URL base en el `APIClient` de la aplicación
3. Realice las siguientes pruebas:
   - Obtener la lista de tareas
   - Crear una nueva tarea
   - Actualizar una tarea existente
   - Completar una etapa con una foto
   - Solicitar apoyo
   - Eliminar una tarea

## Recomendaciones

1. **Latencia**: Optimice las respuestas para mantener la latencia baja
2. **Caché**: Implemente estrategias de caché para mejorar el rendimiento
3. **Compresión**: Utilice compresión para las respuestas HTTP
4. **Rate Limiting**: Implemente límites de frecuencia para prevenir abusos
5. **Logs**: Mantenga registros detallados para facilitar la depuración
6. **Monitoreo**: Implemente monitoreo para detectar problemas temprano

## Conclusión

Implementar el backend para el módulo de mantenimiento requiere seguir estrictamente los formatos de datos y endpoints definidos. La aplicación está diseñada para manejar errores de manera elegante, pero un backend bien implementado mejorará significativamente la experiencia del usuario.

Para cualquier duda o aclaración sobre la implementación, consulte la documentación adicional o contacte al equipo de desarrollo. 