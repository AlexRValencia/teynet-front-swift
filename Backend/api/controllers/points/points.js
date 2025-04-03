import Point from '../../models/Point.js';
import Project from '../../models/Project.js';

// Obtener todos los puntos de un proyecto
export const getPoints = async (req, res) => {
    try {
        const { projectId } = req.params;
        const points = await Point.find({ project: projectId })
            .populate('createdBy', 'fullName')
            .sort({ createdAt: -1 });

        res.json({
            ok: true,
            data: points
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al obtener los puntos',
            error: error.message
        });
    }
};

// Obtener todos los puntos con sus proyectos
export const getAllPoints = async (req, res) => {
    try {
        // Opciones para la consulta (paginación, filtros, etc.)
        const { limit = 100, page = 1, type, city, operational } = req.query;
        const skip = (page - 1) * limit;

        // Construir filtros
        const filters = {};
        if (type) filters.type = type;
        if (city) filters.city = city;
        if (operational !== undefined) filters.operational = operational === 'true';

        // Contar total para paginación
        const total = await Point.countDocuments(filters);

        // Obtener puntos con sus proyectos como IDs, no como objetos populados
        const points = await Point.find(filters)
            .populate('createdBy', 'fullName')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(parseInt(limit));

        res.json({
            ok: true,
            data: points,
            pagination: {
                total,
                page: parseInt(page),
                pages: Math.ceil(total / limit),
                limit: parseInt(limit)
            }
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al obtener los puntos',
            error: error.message
        });
    }
};

// Obtener un punto específico
export const getPoint = async (req, res) => {
    try {
        const { id } = req.params;
        const point = await Point.findById(id)
            .populate('createdBy', 'fullName');

        if (!point) {
            return res.status(404).json({
                ok: false,
                message: 'Punto no encontrado'
            });
        }

        res.json({
            ok: true,
            data: point
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al obtener el punto',
            error: error.message
        });
    }
};

// Crear un nuevo punto
export const createPoint = async (req, res) => {
    try {
        const { projectId } = req.params;

        // Verificar que req.user exista y tenga la propiedad adecuada
        if (!req.user) {
            return res.status(401).json({
                ok: false,
                message: 'Usuario no autenticado'
            });
        }

        // Usar _id si está disponible, si no, usar uid
        const userId = req.user._id || req.user.uid || req.user.id;

        if (!userId) {
            console.error("Detalles del usuario:", JSON.stringify(req.user));
            return res.status(400).json({
                ok: false,
                message: 'No se pudo determinar el ID del usuario',
                userDetails: {
                    hasUser: !!req.user,
                    keys: req.user ? Object.keys(req.user) : []
                }
            });
        }

        // Construir los datos del punto
        let pointData = {
            ...req.body,
            project: projectId,
            createdBy: userId
        };

        // Verificar si se recibió longitude y latitude sin el formato GeoJSON
        if (req.body.longitude !== undefined && req.body.latitude !== undefined) {
            pointData.location = {
                type: 'Point',
                coordinates: [req.body.longitude, req.body.latitude]
            };
            // Eliminar los campos individuales
            delete pointData.longitude;
            delete pointData.latitude;
        }
        // Verificar si location ya tiene el formato correcto
        else if (req.body.location && req.body.location.latitude !== undefined && req.body.location.longitude !== undefined) {
            // Si location viene como un objeto con latitude y longitude (desde el frontend)
            pointData.location = {
                type: 'Point',
                coordinates: [req.body.location.longitude, req.body.location.latitude]
            };
        }
        // Si no hay location, o no está en ninguno de los formatos esperados
        else if (!pointData.location || !pointData.location.type || !pointData.location.coordinates) {
            return res.status(400).json({
                ok: false,
                message: 'Se requiere información de ubicación válida (latitude/longitude o location)'
            });
        }

        console.log("Intentando crear punto con datos:", JSON.stringify(pointData, null, 2));

        const point = await Point.create(pointData);

        // Actualizar el proyecto con el nuevo punto
        await Project.findByIdAndUpdate(
            projectId,
            { $push: { points: point._id } }
        );

        res.status(201).json({
            ok: true,
            message: 'Punto creado exitosamente',
            data: point
        });
    } catch (error) {
        console.error("Error detallado:", error);
        res.status(500).json({
            ok: false,
            message: 'Error al crear el punto',
            error: error.message
        });
    }
};

// Actualizar un punto
export const updatePoint = async (req, res) => {
    try {
        const { id } = req.params;
        const point = await Point.findByIdAndUpdate(
            id,
            req.body,
            { new: true, runValidators: true }
        );

        if (!point) {
            return res.status(404).json({
                ok: false,
                message: 'Punto no encontrado'
            });
        }

        res.json({
            ok: true,
            message: 'Punto actualizado exitosamente',
            data: point
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al actualizar el punto',
            error: error.message
        });
    }
};

// Eliminar un punto
export const deletePoint = async (req, res) => {
    try {
        const { id, projectId } = req.params;
        const point = await Point.findByIdAndDelete(id);

        if (!point) {
            return res.status(404).json({
                ok: false,
                message: 'Punto no encontrado'
            });
        }

        // Eliminar la referencia del punto en el proyecto
        await Project.findByIdAndUpdate(
            projectId,
            { $pull: { points: id } }
        );

        res.json({
            ok: true,
            message: 'Punto eliminado exitosamente'
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al eliminar el punto',
            error: error.message
        });
    }
}; 