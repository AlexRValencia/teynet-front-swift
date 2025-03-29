import Project from '../models/Project.js';
import { loggerx } from '../middleware/logger/logger.js';

// Obtener todos los proyectos
export const getProjects = async (req, res) => {
    try {
        const projects = await Project.find()
            .populate('client', 'name')
            .populate('team', 'fullName')
            .sort({ createdAt: -1 });

        res.json({
            ok: true,
            data: projects
        });
    } catch (error) {
        loggerx.error(`Error al obtener proyectos: ${error.message}`);
        res.status(500).json({
            ok: false,
            message: 'Error al obtener los proyectos',
            error: error.message
        });
    }
};

// Obtener un proyecto por ID
export const getProjectById = async (req, res) => {
    try {
        const project = await Project.findById(req.params.id)
            .populate('client', 'name')
            .populate('team', 'fullName');

        if (!project) {
            return res.status(404).json({
                ok: false,
                message: 'Proyecto no encontrado'
            });
        }

        res.json({
            ok: true,
            data: project
        });
    } catch (error) {
        loggerx.error(`Error al obtener proyecto: ${error.message}`);
        res.status(500).json({
            ok: false,
            message: 'Error al obtener el proyecto',
            error: error.message
        });
    }
};

// Crear un nuevo proyecto
export const createProject = async (req, res) => {
    try {
        const projectData = {
            ...req.body,
            createdBy: req.user._id
        };

        const project = await Project.create(projectData);

        res.status(201).json({
            ok: true,
            message: 'Proyecto creado exitosamente',
            data: project
        });
    } catch (error) {
        loggerx.error(`Error al crear proyecto: ${error.message}`);
        res.status(500).json({
            ok: false,
            message: 'Error al crear el proyecto',
            error: error.message
        });
    }
};

// Actualizar un proyecto
export const updateProject = async (req, res) => {
    try {
        const project = await Project.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true, runValidators: true }
        );

        if (!project) {
            return res.status(404).json({
                ok: false,
                message: 'Proyecto no encontrado'
            });
        }

        res.json({
            ok: true,
            message: 'Proyecto actualizado exitosamente',
            data: project
        });
    } catch (error) {
        loggerx.error(`Error al actualizar proyecto: ${error.message}`);
        res.status(500).json({
            ok: false,
            message: 'Error al actualizar el proyecto',
            error: error.message
        });
    }
};

// Eliminar un proyecto
export const deleteProject = async (req, res) => {
    try {
        const project = await Project.findByIdAndDelete(req.params.id);

        if (!project) {
            return res.status(404).json({
                ok: false,
                message: 'Proyecto no encontrado'
            });
        }

        res.json({
            ok: true,
            message: 'Proyecto eliminado exitosamente'
        });
    } catch (error) {
        loggerx.error(`Error al eliminar proyecto: ${error.message}`);
        res.status(500).json({
            ok: false,
            message: 'Error al eliminar el proyecto',
            error: error.message
        });
    }
};

// Actualizar el estado de salud de un proyecto
export const updateProjectHealth = async (req, res) => {
    try {
        const { health } = req.body;
        const project = await Project.findByIdAndUpdate(
            req.params.id,
            { health },
            { new: true, runValidators: true }
        );

        if (!project) {
            return res.status(404).json({
                ok: false,
                message: 'Proyecto no encontrado'
            });
        }

        res.json({
            ok: true,
            message: 'Estado de salud actualizado exitosamente',
            data: project
        });
    } catch (error) {
        loggerx.error(`Error al actualizar estado de salud: ${error.message}`);
        res.status(500).json({
            ok: false,
            message: 'Error al actualizar el estado de salud',
            error: error.message
        });
    }
}; 