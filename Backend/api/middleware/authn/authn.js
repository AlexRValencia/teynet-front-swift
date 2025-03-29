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

export const requiereToken = async (req, res, next) => {
    try {
        let token = req.headers.authorization;
        if (!token) throw new Error("invalid signature");
        token = token.split(" ")[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        if (!decoded) throw new Error("invalid token");

        // Buscar el usuario en la base de datos y asignarlo a req.user
        const user = await User.findById(decoded.uid);
        if (!user) throw new Error("invalid token");

        // Asignar el usuario al request para usarlo en los controladores
        req.user = user;

        next();
    } catch (error) {
        return res.status(401).json({
            error: {
                source: "body/username:password",
                detail: tokenErrors[error.message],
            }
        })
    }
}