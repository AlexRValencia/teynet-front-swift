# Trynet

Aplicación móvil para la gestión de tareas de mantenimiento, inventario y administración de proyectos para la empresa Trynet.

## Estructura del proyecto

El proyecto está dividido en dos partes principales:

- **Frontend**: Aplicación iOS desarrollada con SwiftUI
- **Backend**: API REST desarrollada con Node.js

## Requisitos previos

### Frontend (iOS)
- macOS Ventura o superior
- Xcode 14.0 o superior
- iOS 16.0 o superior (para ejecutar la aplicación)
- Swift 5.7 o superior

### Backend
- Node.js 16.x o superior
- npm 8.x o superior
- MongoDB 5.0 o superior (opcional, para almacenamiento persistente)

## Configuración del entorno

### Configuración del Backend

1. Navega al directorio del backend:
   ```bash
   cd Backend
   ```

2. Instala las dependencias:
   ```bash
   npm install
   ```

3. Crea un archivo `.env` con las siguientes variables:
   ```
   PORT=42067
   MONGODB_URI=mongodb://localhost:27017/trynet
   JWT_SECRET=tu_secreto_jwt
   NODE_ENV=development
   ```

4. Inicia el servidor:
   ```bash
   node server.js
   ```
   
   El servidor estará disponible en http://localhost:42067

### Configuración del Frontend

1. Abre el proyecto en Xcode:
   ```bash
   open trynet.xcodeproj
   ```

2. Configura la URL del backend en `APIClient.swift`:
   ```swift
   // Opciones para conexión local
   let url = "http://192.168.100.70:42067/api/v1"  // Ajusta esta URL a la dirección de tu servidor
   ```

3. Construye y ejecuta la aplicación en el simulador o dispositivo.

## Funcionalidades principales

### Módulo de Mantenimiento
- Visualización de tareas de mantenimiento
- Creación y edición de tareas
- Seguimiento de etapas de mantenimiento con fotografías
- Generación de reportes en PDF

### Módulo de Inventario
- Gestión de inventario de equipos y materiales
- Registro de movimientos de inventario
- Visualización de disponibilidad

### Módulo de Proyectos
- Gestión de proyectos y clientes
- Asignación de recursos y materiales
- Seguimiento de avance

## API Endpoints

### Autenticación
- `POST /api/v1/authn/login`: Iniciar sesión
- `POST /api/v1/authn/refresh`: Refrescar token

### Mantenimiento
- `GET /api/v1/maintenance/tasks`: Obtener todas las tareas
- `GET /api/v1/maintenance/tasks/:id`: Obtener una tarea específica
- `POST /api/v1/maintenance/tasks`: Crear una nueva tarea
- `PUT /api/v1/maintenance/tasks/:id`: Actualizar una tarea
- `DELETE /api/v1/maintenance/tasks/:id`: Eliminar una tarea
- `POST /api/v1/maintenance/tasks/:id/stages/complete`: Completar una etapa
- `POST /api/v1/maintenance/tasks/:id/support`: Solicitar apoyo

### Usuarios
- `GET /api/v1/users`: Obtener todos los usuarios
- `POST /api/v1/users`: Crear un nuevo usuario
- `PUT /api/v1/users/:id`: Actualizar un usuario

### Clientes y Proyectos
- `GET /api/v1/clients`: Obtener todos los clientes
- `GET /api/v1/projects`: Obtener todos los proyectos
- `POST /api/v1/projects`: Crear un nuevo proyecto

## Contribución

Para contribuir al proyecto, sigue estos pasos:

1. Clona el repositorio
   ```bash
   git clone https://github.com/tu-usuario/trynet.git
   ```

2. Crea una rama para tu funcionalidad
   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```

3. Haz tus cambios y realiza commits
   ```bash
   git commit -m "Descripción de los cambios"
   ```

4. Envía tus cambios al repositorio
   ```bash
   git push origin feature/nueva-funcionalidad
   ```

5. Crea un Pull Request

## Comandos útiles para git

### Inicializar un nuevo repositorio
```bash
git init
git add .
git commit -m "Commit inicial"
git branch -M main
git remote add origin https://github.com/tu-usuario/trynet.git
git push -u origin main
```

### Clonar un repositorio existente
```bash
git clone https://github.com/tu-usuario/trynet.git
```

### Actualizar tu repositorio local
```bash
git pull origin main
```

## Licencia

Este proyecto está licenciado bajo [tu licencia].

# Instrucciones para importar puntos a MongoDB

Este proyecto contiene scripts para convertir datos de puntos geográficos al formato requerido por MongoDB.

## Archivos

- `data.json`: Archivo original con los datos de los puntos.
- `puntos_mongodb.json`: Archivo convertido con el formato adecuado para importar a MongoDB.
- `convertir_puntos.js`: Script para convertir el formato.

## Pasos para la conversión

1. Ejecutar el script de conversión:
   ```
   node convertir_puntos.js
   ```

2. El script generará un archivo `puntos_mongodb.json` con el formato adecuado para MongoDB.

## Importación a MongoDB

Para importar los datos directamente a MongoDB, puedes usar el comando `mongoimport`:

```bash
mongoimport --uri="mongodb://tuUsuario:tuContraseña@tuHost:tuPuerto/tuBaseDeDatos" --collection=points --file=puntos_mongodb.json --jsonArray
```

O si estás usando MongoDB Atlas:

```bash
mongoimport --uri="mongodb+srv://tuUsuario:tuContraseña@tuCluster.mongodb.net/tuBaseDeDatos" --collection=points --file=puntos_mongodb.json --jsonArray
```

## Notas importantes

- El script realiza validaciones básicas de los datos:
  - Convierte las coordenadas a números
  - Asigna valores por defecto a campos vacíos
  - Normaliza los tipos de puntos según el esquema
  - No incluye los puntos que no tienen proyecto asignado

- Todos los puntos son asignados al mismo usuario creador (definido en el script)
- La fecha de creación y actualización es la misma para todos los puntos
- No se asigna un ID específico, MongoDB lo generará automáticamente 