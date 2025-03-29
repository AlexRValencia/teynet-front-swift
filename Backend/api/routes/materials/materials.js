import express from 'express';
import { requiereToken } from '../../middleware/authn/authn.js';
import {
    getMaterials,
    getMaterial,
    createMaterial,
    updateMaterial,
    deleteMaterial
} from '../../controllers/materials/materials.js';

const router = express.Router();

// Aplicar middleware de autenticación a todas las rutas
router.use(requiereToken);

// Rutas de materiales
router.get('/project/:projectId', getMaterials);
router.get('/:id', getMaterial);
router.post('/project/:projectId', createMaterial);
router.put('/:id', updateMaterial);
router.delete('/:id/project/:projectId', deleteMaterial);

export default router; 