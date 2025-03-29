import express from 'express';
import { requiereToken } from '../../middleware/authn/authn.js';
import {
    getPoints,
    getPoint,
    createPoint,
    updatePoint,
    deletePoint
} from '../../controllers/points/points.js';

const router = express.Router();

// Aplicar middleware de autenticación a todas las rutas
router.use(requiereToken);

// Rutas de puntos
router.get('/project/:projectId', getPoints);
router.get('/:id', getPoint);
router.post('/project/:projectId', createPoint);
router.put('/:id', updatePoint);
router.delete('/:id/project/:projectId', deletePoint);

export default router; 