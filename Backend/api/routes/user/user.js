import { Router } from "express";
import {
    createUser,
    detailsUser,
    getAllUsers,
    updateUser,
    changePassword,
    deleteUser,
    getUserHistory
} from "../../controllers/user/user.js";

import {
    accessLevel
} from "../../middleware/authz/authz.js"

import { requiereToken } from "../../middleware/authn/authn.js";

const PERMISSIONS = {
    create: ['admin'],
    update: ['admin'],
    delete: ['admin'],
    read: ['admin', 'supervisor', 'technician']
}

const router = Router();

// Crear usuario (solo admin)
router.post("/", requiereToken, accessLevel(PERMISSIONS.create), createUser);

// Obtener todos los usuarios (paginado, con filtros)
router.get("/", requiereToken, accessLevel(PERMISSIONS.read), getAllUsers);

// Obtener detalles de un usuario específico
router.get("/:id", requiereToken, accessLevel(PERMISSIONS.read), detailsUser);

// Obtener historial de cambios de un usuario
router.get("/:id/history", requiereToken, accessLevel(PERMISSIONS.read), getUserHistory);

// Actualizar usuario
router.put("/:id", requiereToken, accessLevel(PERMISSIONS.update), updateUser);

// Cambiar contraseña
router.patch("/:id/password", requiereToken, accessLevel(PERMISSIONS.update), changePassword);

// Eliminar usuario (soft delete)
router.delete("/:id", requiereToken, accessLevel(PERMISSIONS.delete), deleteUser);

export default router;