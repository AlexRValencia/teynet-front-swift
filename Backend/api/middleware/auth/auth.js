import jwt from 'jsonwebtoken';
import { User } from '../../models/User.js';
import { loggerx } from '../../middleware/logger/logger.js';

const tokenErrors = {
    "invalid signature": "La firma del JWT no es válida",
    "jwt expired": "JWT expirado",
    "invalid token": "Token inválido",
    "No Bearer": "Utiliza formato Bearer",
    "jwt malformed": "JWT formato inválido",
    "No existe el token": "No existe el token",
    "Error al verificar token": "Error al verificar token"
};

/**
 * Middleware de autenticación para verificar el JWT
 * Agrega el usuario al objeto de solicitud si el token es válido
 */
export const authMiddleware = async (req, res, next) => {
    try {
        let token = req.headers.authorization;

        // Verificar que exista un token
        if (!token) {
            throw new Error("No existe el token");
        }

        // Verificar que sea formato Bearer
        if (!token.startsWith('Bearer ')) {
            throw new Error("No Bearer");
        }

        // Extraer el token
        token = token.split(" ")[1];

        // Verificar el token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        if (!decoded) {
            throw new Error("invalid token");
        }

        // Buscar el usuario en la base de datos
        const user = await User.findById(decoded.uid);
        if (!user) {
            throw new Error("invalid token");
        }

        // Asignar el usuario al request para usarlo en los controladores
        req.user = user;

        // Log de acceso
        loggerx.info({
            action: "AUTH_SUCCESS",
            userId: user._id.toString(),
            username: user.username,
            role: user.role,
            ip: req.ip
        });

        next();
    } catch (error) {
        loggerx.warn({
            action: "AUTH_FAILURE",
            error: error.message,
            ip: req.ip,
            path: req.originalUrl
        });

        return res.status(401).json({
            ok: false,
            error: {
                source: "authorization",
                detail: tokenErrors[error.message] || "Error de autenticación"
            }
        });
    }
}; 