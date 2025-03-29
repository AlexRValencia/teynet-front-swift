import express from 'express';
import { requiereToken } from '../middleware/authn/authn.js';
import {
    getProjects,
    getProjectById,
    createProject,
    updateProject,
    deleteProject,
    updateProjectHealth
} from '../controllers/projectController.js';

const router = express.Router();

// Aplicar middleware de autenticación a todas las rutas
router.use(requiereToken);

// Rutas de proyectos
router.get('/', getProjects);
router.get('/:id', getProjectById);
router.post('/', createProject);
router.put('/:id', updateProject);
router.delete('/:id', deleteProject);

// Ruta específica para actualizar la salud del proyecto
router.patch('/:id/health', updateProjectHealth);

export default router; 