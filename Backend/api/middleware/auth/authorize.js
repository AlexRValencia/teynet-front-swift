import { loggerx } from '../logger/logger.js';

/**
 * Middleware de autorización para verificar roles de usuario
 * @param {Array} allowedRoles - Array de roles permitidos para acceder a la ruta
 * @returns {Function} - Middleware de Express
 */
export const authorize = (allowedRoles = []) => {
    return (req, res, next) => {
        try {
            // El middleware de autenticación ya debe haber puesto el usuario en req.user
            if (!req.user) {
                loggerx.warn({
                    action: "AUTHORIZATION_FAILURE",
                    error: "No hay usuario autenticado",
                    ip: req.ip,
                    path: req.originalUrl
                });

                return res.status(401).json({
                    ok: false,
                    error: {
                        detail: "Se requiere autenticación"
                    }
                });
            }

            // Si no se especifican roles, se permite el acceso a cualquier usuario autenticado
            if (!allowedRoles || allowedRoles.length === 0) {
                return next();
            }

            // Verificar que el usuario tenga al menos uno de los roles permitidos
            if (!allowedRoles.includes(req.user.role)) {
                loggerx.warn({
                    action: "AUTHORIZATION_FAILURE",
                    error: "Rol no autorizado",
                    userRole: req.user.role,
                    requiredRoles: allowedRoles,
                    userId: req.user._id.toString(),
                    username: req.user.username,
                    ip: req.ip,
                    path: req.originalUrl
                });

                return res.status(403).json({
                    ok: false,
                    error: {
                        detail: "No tiene los permisos necesarios para acceder a este recurso"
                    }
                });
            }

            // Log de autorización exitosa
            loggerx.info({
                action: "AUTHORIZATION_SUCCESS",
                userRole: req.user.role,
                userId: req.user._id.toString(),
                username: req.user.username,
                ip: req.ip,
                path: req.originalUrl
            });

            next();
        } catch (error) {
            loggerx.error({
                action: "AUTHORIZATION_ERROR",
                error: error.message,
                ip: req.ip,
                path: req.originalUrl
            });

            return res.status(500).json({
                ok: false,
                error: {
                    detail: "Error al verificar permisos"
                }
            });
        }
    };
}; 