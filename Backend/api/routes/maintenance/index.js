import express from 'express';
import {
    createMaintenance,
    getMaintenanceDetails,
    getAllMaintenance,
    updateMaintenance,
    updateMaintenanceStage,
    deleteMaintenance,
    requestSupport,
    registerReport,
    addInitialPhotos,
    addFinalPhotos,
    updateDamagedEquipment,
    updateCableInstalled,
    generateServiceOrder
} from '../../controllers/maintenance/maintenance.js';
import { authMiddleware } from '../../middleware/auth/auth.js';
import { authorize } from '../../middleware/auth/authorize.js';
import testRoutes from './test.js';

const router = express.Router();

// Rutas de prueba
router.use('/test', testRoutes);

// Para mantener la compatibilidad con API anterior (versión mock)
// Estas rutas se mantienen temporalmente para no romper las aplicaciones existentes
// Colocadas antes del middleware de autenticación para permitir acceso público
router.get('/tasks', getAllMaintenance);
router.get('/tasks/:id', (req, res) => {
    req.params.id = req.params.id;
    getMaintenanceDetails(req, res);
});

// Ruta de creación de tareas - ahora requiere autenticación y rol admin
router.post('/tasks', authMiddleware, authorize(['admin']), (req, res) => {
    createMaintenance(req, res);
});

router.put('/tasks/:id', (req, res) => {
    req.params.id = req.params.id;
    // Si no hay usuario autenticado, asignar uno por defecto
    if (!req.user) {
        req.user = {
            _id: "000000000000000000000000",
            username: "system",
            fullName: "Sistema",
            role: "técnico"
        };
    }
    updateMaintenance(req, res);
});

router.post('/tasks/:id/stages/complete', (req, res) => {
    const { stageName } = req.body;

    // Buscar el stageId correspondiente según el nombre
    req.params.stageId = stageName; // Simplificado para compatibilidad
    req.params.id = req.params.id;

    // Asignar usuario por defecto si no existe
    if (!req.user) {
        req.user = {
            _id: "000000000000000000000000",
            username: "system",
            fullName: "Sistema",
            role: "técnico"
        };
    }

    // Ajustar el cuerpo de la solicitud para el formato esperado por el nuevo endpoint
    req.body = {
        isCompleted: true,
        photos: req.body.photoData ? [{
            imageData: req.body.photoData,
            caption: req.body.photoCaption || `Foto de ${stageName}`,
            timestamp: req.body.timestamp || new Date().toISOString()
        }] : []
    };

    updateMaintenanceStage(req, res);
});

router.post('/tasks/:id/support', (req, res) => {
    req.params.id = req.params.id;
    req.body.requestDetails = req.body.details;

    // Asignar usuario por defecto si no existe
    if (!req.user) {
        req.user = {
            _id: "000000000000000000000000",
            username: "system",
            fullName: "Sistema",
            role: "técnico"
        };
    }

    requestSupport(req, res);
});

router.delete('/tasks/:id', (req, res) => {
    req.params.id = req.params.id;

    // Asignar usuario por defecto si no existe
    if (!req.user) {
        req.user = {
            _id: "000000000000000000000000",
            username: "system",
            fullName: "Sistema",
            role: "técnico"
        };
    }

    deleteMaintenance(req, res);
});

// Todas las rutas de mantenimiento requieren autenticación
router.use(authMiddleware);

// Rutas principales para tareas de mantenimiento
router.post('/', authorize(['admin', 'supervisor', 'técnico']), createMaintenance);
router.get('/:id', authorize(['admin', 'supervisor', 'técnico']), getMaintenanceDetails);
router.get('/', authorize(['admin', 'supervisor', 'técnico']), getAllMaintenance);
router.put('/:id', authorize(['admin', 'supervisor', 'técnico']), updateMaintenance);
router.put('/:id/stage/:stageId', authorize(['admin', 'supervisor', 'técnico']), updateMaintenanceStage);
router.delete('/:id', authorize(['admin', 'supervisor']), deleteMaintenance);

// Rutas específicas para el formato de orden de servicio
router.post('/:id/initial-photos', authorize(['admin', 'supervisor', 'técnico']), addInitialPhotos);
router.post('/:id/final-photos', authorize(['admin', 'supervisor', 'técnico']), addFinalPhotos);
router.put('/:id/damaged-equipment', authorize(['admin', 'supervisor', 'técnico']), updateDamagedEquipment);
router.put('/:id/cable-installed', authorize(['admin', 'supervisor', 'técnico']), updateCableInstalled);
router.post('/:id/generate-order', authorize(['admin', 'supervisor', 'técnico']), generateServiceOrder);

// Rutas adicionales para funcionalidades específicas
router.post('/:id/support', authorize(['admin', 'supervisor', 'técnico']), requestSupport);
router.post('/:id/report', authorize(['admin', 'supervisor', 'técnico']), registerReport);

export default router; 