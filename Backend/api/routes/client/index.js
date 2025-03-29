import express from 'express';
import * as clientController from '../../controllers/client/client.js';
import { requiereToken } from '../../middleware/authn/authn.js';
import { accessLevel } from '../../middleware/authz/authz.js';

const PERMISSIONS = {
    create: ['admin', 'supervisor'],
    update: ['admin', 'supervisor'],
    delete: ['admin'],
    read: ['admin', 'supervisor', 'technician', 'viewer']
}

const router = express.Router();

// GET /clients - Obtener todos los clientes (con paginación y filtros)
router.get('/', requiereToken, accessLevel(PERMISSIONS.read), clientController.getAllClients);

// POST /clients - Crear un nuevo cliente
router.post('/', requiereToken, accessLevel(PERMISSIONS.create), clientController.createClient);

// GET /clients/:id - Obtener detalles de un cliente específico
router.get('/:id', requiereToken, accessLevel(PERMISSIONS.read), clientController.getClientDetails);

// PUT /clients/:id - Actualizar un cliente existente
router.put('/:id', requiereToken, accessLevel(PERMISSIONS.update), clientController.updateClient);

// DELETE /clients/:id - Eliminar un cliente
router.delete('/:id', requiereToken, accessLevel(PERMISSIONS.delete), clientController.deleteClient);

// GET /clients/:id/history - Obtener historial de cambios de un cliente
router.get('/:id/history', requiereToken, accessLevel(PERMISSIONS.read), clientController.getClientHistory);

export default router; 