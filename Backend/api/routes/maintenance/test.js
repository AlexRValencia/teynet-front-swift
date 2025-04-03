import express from 'express';
import { authMiddleware } from '../../middleware/auth/auth.js';
import { authorize } from '../../middleware/auth/authorize.js';

const router = express.Router();

// Ruta pública para verificar que el servidor está funcionando
router.get('/public', (req, res) => {
    return res.json({
        ok: true,
        message: 'Ruta pública accesible sin autenticación'
    });
});

// Ruta protegida por autenticación
router.get('/auth', authMiddleware, (req, res) => {
    return res.json({
        ok: true,
        message: 'Ruta protegida por autenticación',
        user: {
            id: req.user._id,
            username: req.user.username,
            role: req.user.role
        }
    });
});

// Ruta protegida por rol de admin
router.get('/admin', authMiddleware, authorize(['admin']), (req, res) => {
    return res.json({
        ok: true,
        message: 'Ruta protegida para administradores',
        user: {
            id: req.user._id,
            username: req.user.username,
            role: req.user.role
        }
    });
});

// Ruta protegida por roles múltiples
router.get('/tech', authMiddleware, authorize(['admin', 'supervisor', 'técnico']), (req, res) => {
    return res.json({
        ok: true,
        message: 'Ruta protegida para técnicos y superiores',
        user: {
            id: req.user._id,
            username: req.user.username,
            role: req.user.role
        }
    });
});

export default router; 