import { loggerx } from "../../middleware/logger/logger.js";
import { UserService } from "../../services/userService.js";

/**
 * Crea un nuevo usuario
 */
export const createUser = async (req, res) => {
    try {
        const userData = req.body;
        const adminUser = req.user; // Obtenido del middleware de autenticación

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes
        };

        loggerx.info({
            action: "CREATE_USER_REQUEST",
            username: userData.username,
            fullName: userData.fullName,
            role: userData.role,
            requestedBy: adminUser?._id.toString() || "anónimo"
        });

        const newUser = await UserService.createUser(userData, adminUser, metadata);

        return res.status(201).json({
            ok: true,
            message: "Usuario creado exitosamente",
            data: newUser
        });
    } catch (error) {
        loggerx.error({
            action: "CREATE_USER_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            userData: {
                username: req.body.username,
                fullName: req.body.fullName,
                role: req.body.role
            }
        });

        if (error.message.includes("ya existe")) {
            return res.status(409).json({
                ok: false,
                error: error.message
            });
        }

        if (error.message.includes("incompletos")) {
            return res.status(400).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: "Error al crear usuario"
        });
    }
};

/**
 * Obtiene detalles de un usuario específico
 */
export const detailsUser = async (req, res) => {
    try {
        if (!req.params.id) {
            return res.status(400).json({
                ok: false,
                error: 'Se requiere el ID del usuario'
            });
        }

        const userId = req.params.id;
        const user = await UserService.getUserById(userId);

        return res.status(200).json({
            ok: true,
            data: user
        });
    } catch (error) {
        loggerx.error(`Error en detailsUser: ${error.message}`);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: 'Usuario no encontrado'
            });
        }

        return res.status(500).json({
            ok: false,
            error: 'Error al obtener usuario'
        });
    }
};

/**
 * Obtiene todos los usuarios con filtros y paginación
 */
export const getAllUsers = async (req, res) => {
    try {
        // Extraer parámetros de la solicitud
        const filters = {
            role: req.query.role || req.query.rol,
            status: req.query.status || req.query.statusDB,
            search: req.query.search
        };

        const pagination = {
            page: parseInt(req.query.page) || 1,
            limit: parseInt(req.query.limit) || 10
        };

        const sort = {
            field: req.query.sortBy || 'createdAt',
            order: req.query.sortOrder || 'desc'
        };

        // Obtener usuarios a través del servicio
        const result = await UserService.getUsers(filters, pagination, sort);

        return res.status(200).json({
            ok: true,
            data: {
                users: result.users,
                pagination: result.pagination
            }
        });
    } catch (error) {
        loggerx.error(`Error en getAllUsers: ${error.message}`);
        return res.status(500).json({
            ok: false,
            error: "Error al obtener usuarios"
        });
    }
};

/**
 * Actualiza un usuario existente
 */
export const updateUser = async (req, res) => {
    try {
        const userId = req.params.id;
        const updateData = req.body;
        const adminUser = req.user;

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes
        };

        loggerx.info({
            action: "UPDATE_USER_REQUEST",
            userId,
            updateFields: Object.keys(updateData).filter(k => k !== 'notes'),
            requestedBy: adminUser?._id.toString() || "anónimo"
        });

        const updatedUser = await UserService.updateUser(userId, updateData, adminUser, metadata);

        return res.json({
            ok: true,
            message: "Usuario actualizado exitosamente",
            data: updatedUser
        });
    } catch (error) {
        loggerx.error({
            action: "UPDATE_USER_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            userId: req.params.id,
            updateData: Object.keys(req.body).filter(k => k !== 'password' && k !== 'notes')
        });

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: error.message
            });
        }

        if (error.message.includes("ya está en uso")) {
            return res.status(409).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: "Error al actualizar usuario"
        });
    }
};

/**
 * Cambia la contraseña de un usuario
 */
export const changePassword = async (req, res) => {
    try {
        const userId = req.params.id;
        const { password } = req.body;
        const adminUser = req.user;

        // Validación mejorada para la contraseña
        if (!password) {
            return res.status(400).json({
                ok: false,
                error: "La contraseña es obligatoria",
                details: "Se debe proporcionar una contraseña en el cuerpo de la petición"
            });
        }

        if (typeof password !== 'string') {
            return res.status(400).json({
                ok: false,
                error: "Formato de contraseña incorrecto",
                details: `La contraseña debe ser una cadena de texto, se recibió: ${typeof password}`
            });
        }

        if (password.length < 8) {
            return res.status(400).json({
                ok: false,
                error: "La contraseña debe tener al menos 8 caracteres",
                details: `Se recibió una contraseña de ${password.length} caracteres`
            });
        }

        // Validar que la contraseña contenga al menos una letra y un número
        if (!/^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$/.test(password)) {
            return res.status(400).json({
                ok: false,
                error: "Formato de contraseña incorrecto",
                details: "La contraseña debe contener al menos una letra y un número"
            });
        }

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes
        };

        await UserService.changePassword(userId, password, adminUser, metadata);

        return res.status(200).json({
            ok: true,
            message: "Contraseña actualizada exitosamente"
        });
    } catch (error) {
        loggerx.error(`Error en changePassword: ${error.message}`);
        loggerx.error(`Stack trace: ${error.stack}`);

        // Log de datos recibidos para facilitar la depuración
        loggerx.error(`Datos recibidos: ${JSON.stringify({
            userId: req.params.id,
            passwordLength: req.body.password ? req.body.password.length : 0,
            method: req.method,
            path: req.path
        })}`);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: error.message,
                details: "El usuario para cambiar la contraseña no existe"
            });
        }

        // Errores de validación
        if (error.name === 'ValidationError') {
            const validationErrors = Object.values(error.errors).map(err => err.message);
            return res.status(400).json({
                ok: false,
                error: "Error de validación en la contraseña",
                details: validationErrors
            });
        }

        // Errores de casting (por ejemplo, formato de ID incorrecto)
        if (error.name === 'CastError') {
            return res.status(400).json({
                ok: false,
                error: "Formato de ID incorrecto",
                details: `El ID de usuario tiene un formato inválido: ${error.value}`
            });
        }

        return res.status(500).json({
            ok: false,
            error: "Error al cambiar contraseña",
            details: error.message
        });
    }
};

/**
 * Elimina un usuario (soft delete)
 */
export const deleteUser = async (req, res) => {
    try {
        const userId = req.params.id;
        const adminUser = req.user;

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes || "Eliminación de usuario"
        };

        loggerx.info({
            action: "DELETE_USER_REQUEST",
            userId,
            requestedBy: adminUser?._id.toString() || "anónimo"
        });

        await UserService.deleteUser(userId, adminUser, metadata);

        return res.json({
            ok: true,
            message: "Usuario eliminado exitosamente"
        });
    } catch (error) {
        loggerx.error({
            action: "DELETE_USER_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            userId: req.params.id
        });

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: "Error al eliminar usuario"
        });
    }
};

/**
 * Obtiene el historial de cambios de un usuario
 */
export const getUserHistory = async (req, res) => {
    try {
        const userId = req.params.id;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;

        const result = await UserService.getUserHistory(userId, { page, limit });

        return res.status(200).json({
            ok: true,
            data: result
        });
    } catch (error) {
        loggerx.error(`Error en getUserHistory: ${error.message}`);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: "Error al obtener historial de usuario"
        });
    }
};