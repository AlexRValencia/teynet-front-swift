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
        const pointData = {
            ...req.body,
            project: projectId,
            createdBy: req.user.uid
        };

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