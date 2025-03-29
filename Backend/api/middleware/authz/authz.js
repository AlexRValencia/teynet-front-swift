import jwt from 'jsonwebtoken';
import { User } from '../../models/User.js';

const tokenErrors = {
    "invalid signature": "La firma del JWT no es válida",
    "jwt expired": "JWT expirado",
    "invalid token": "Token invalido",
    "No Bearer": "Utiliza formato Bearer",
    "jwt malformed": "JWT formato invalido",
    "No existe el token": "No existe el token",
    "Error al verificar token": "Error al verificar token",
    "Permission denied": "No tiene los permisos necesarios",
};

export const accessLevel = permissions => {
    return async (req, res, next) => {
        try {
            const token = req.headers.authorization.split(" ")[1]
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Buscar el usuario en la base de datos
            const user = await User.findById(decoded.uid);
            if (!user) {
                return res.status(401).json({
                    ok: false,
                    error: {
                        detail: "Usuario no encontrado"
                    }
                });
            }

            // Verificar que el usuario tenga el rol permitido
            if (permissions.length > 0 && !permissions.includes(user.role)) {
                return res.status(403).json({
                    ok: false,
                    error: {
                        detail: tokenErrors["Permission denied"]
                    }
                });
            }

            // Asignar el usuario al request
            req.user = user;

            next();
        } catch (error) {
            console.error("Error en accessLevel:", error.message);
            return res.status(401).json({
                ok: false,
                error: {
                    detail: tokenErrors[error.message] || "Error de autenticación"
                }
            });
        }
    }
}