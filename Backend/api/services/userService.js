import { User } from "../models/User.js";
import { AuditTrail } from "../models/AuditTrail.js";
import { loggerx } from "../middleware/logger/logger.js";
import mongoose from "mongoose";
import bcrypt from "bcrypt";

export class UserService {
    /**
     * Crea un nuevo usuario
     * @param {Object} userData - Datos del usuario
     * @param {Object} adminUser - Usuario administrador que realiza la acción
     * @param {Object} metadata - Metadatos de la solicitud
     * @returns {Promise<Object>} Usuario creado
     */
    static async createUser(userData, adminUser, metadata = {}) {
        // Verificar si estamos en modo desarrollo para evitar usar transacciones
        const isDevelopment = process.env.NODE_ENV === 'development';

        // En modo desarrollo, no usamos transacciones
        if (isDevelopment) {
            try {
                console.log("Modo desarrollo: No se usarán transacciones MongoDB para crear usuario");

                // Validar datos mínimos requeridos
                if (!userData.username || !userData.password || !userData.fullName) {
                    throw new Error("Datos de usuario incompletos");
                }

                // Verificar si el username ya existe
                const existingUser = await User.findOne({ username: userData.username.toLowerCase() });
                if (existingUser) {
                    throw new Error("El nombre de usuario ya existe");
                }

                // Crear objeto de usuario con los datos proporcionados
                const user = new User({
                    username: userData.username.toLowerCase(),
                    fullName: userData.fullName,
                    password: userData.password,
                    role: userData.role || 'technician',
                    status: userData.status || 'active',
                    createdBy: adminUser ? adminUser._id : undefined,
                    updatedBy: adminUser ? adminUser._id : undefined
                });

                // Guardar usuario
                await user.save();

                // Registrar en el historial de cambios
                const auditTrail = new AuditTrail({
                    entityType: "user",
                    entityId: user._id,
                    action: "create",
                    changes: {
                        username: user.username,
                        fullName: user.fullName,
                        role: user.role,
                        status: user.status
                    },
                    performedBy: adminUser ? adminUser._id : undefined,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Creación de usuario"
                });

                await auditTrail.save();

                // Registrar actividad
                loggerx.info({
                    action: "USER_CREATED",
                    user: user._id.toString(),
                    username: user.username,
                    role: user.role,
                    createdBy: adminUser ? adminUser._id.toString() : "sistema",
                    timestamp: new Date()
                });

                return user;
            } catch (error) {
                loggerx.error({
                    action: "USER_CREATE_ERROR",
                    error: {
                        message: error.message,
                        stack: error.stack
                    },
                    username: userData.username,
                    timestamp: new Date()
                });
                throw error;
            }
        } else {
            // En producción, sí usamos transacciones
            const session = await mongoose.startSession();
            session.startTransaction();

            try {
                // Validar datos
                if (!userData.username || !userData.fullName || !userData.password) {
                    throw new Error("Datos de usuario incompletos");
                }

                // Verificar si el usuario ya existe
                const existingUser = await User.findOne({
                    username: userData.username.toLowerCase()
                });

                if (existingUser) {
                    throw new Error("El nombre de usuario ya existe");
                }

                // Crear usuario
                const user = new User({
                    ...userData,
                    username: userData.username.toLowerCase(),
                    createdBy: adminUser._id,
                    updatedBy: adminUser._id,
                    status: "active"
                });

                await user.save({ session });

                // Registrar en el historial de cambios
                const auditTrail = new AuditTrail({
                    entityType: "user",
                    entityId: user._id,
                    action: "create",
                    changes: {
                        username: user.username,
                        fullName: user.fullName,
                        role: user.role,
                        status: user.status
                    },
                    performedBy: adminUser._id,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Creación de usuario"
                });

                await auditTrail.save({ session });

                // Confirmar transacción
                await session.commitTransaction();

                // Registrar actividad
                loggerx.info({
                    action: "USER_CREATED",
                    user: user._id.toString(),
                    username: user.username,
                    role: user.role,
                    createdBy: adminUser ? adminUser._id.toString() : "sistema",
                    timestamp: new Date()
                });

                return user;
            } catch (error) {
                // Revertir transacción en caso de error
                await session.abortTransaction();

                loggerx.error({
                    action: "USER_CREATE_ERROR",
                    error: {
                        message: error.message,
                        stack: error.stack
                    },
                    username: userData.username,
                    timestamp: new Date()
                });
                throw error;
            } finally {
                session.endSession();
            }
        }
    }

    /**
     * Actualiza un usuario existente
     * @param {String} userId - ID del usuario a actualizar
     * @param {Object} updateData - Datos a actualizar
     * @param {Object} adminUser - Usuario administrador que realiza la acción
     * @param {Object} metadata - Metadatos de la solicitud
     * @returns {Promise<Object>} Usuario actualizado
     */
    static async updateUser(userId, updateData, adminUser, metadata = {}) {
        // Verificar si estamos en modo desarrollo para evitar usar transacciones
        const isDevelopment = process.env.NODE_ENV === 'development';

        // En modo desarrollo, no usamos transacciones
        if (isDevelopment) {
            try {
                console.log("Modo desarrollo: No se usarán transacciones MongoDB");

                // Obtener usuario actual para registrar cambios
                const currentUser = await User.findById(userId);

                if (!currentUser) {
                    throw new Error("Usuario no encontrado");
                }

                // Verificar si se intenta cambiar el username y si ya existe
                if (updateData.username &&
                    updateData.username.toLowerCase() !== currentUser.username.toLowerCase()) {
                    const existingUser = await User.findOne({
                        username: updateData.username.toLowerCase(),
                        _id: { $ne: userId }
                    });

                    if (existingUser) {
                        throw new Error("El nombre de usuario ya está en uso");
                    }
                }

                // Preparar datos para actualizar
                const updateFields = {};
                const changes = {};
                const previousData = {};

                // Campos permitidos para actualizar
                const allowedFields = ['username', 'fullName', 'role', 'status'];

                // Detectar si se están intentando actualizar campos no permitidos
                const receivedFields = Object.keys(updateData);
                const nonAllowedFields = receivedFields.filter(field =>
                    !allowedFields.includes(field) && field !== 'notes'
                );

                // Registrar advertencia si se reciben campos no permitidos
                if (nonAllowedFields.length > 0) {
                    loggerx.warn({
                        action: "INVALID_UPDATE_FIELDS",
                        user: userId.toString(),
                        fields: nonAllowedFields,
                        requestData: updateData,
                        message: "Estos campos serán ignorados en la actualización"
                    });
                }

                allowedFields.forEach(field => {
                    if (updateData[field] !== undefined &&
                        updateData[field] !== currentUser[field]) {
                        updateFields[field] = updateData[field];
                        changes[field] = updateData[field];
                        previousData[field] = currentUser[field];
                    }
                });

                // Si no hay cambios, retornar usuario actual
                if (Object.keys(changes).length === 0) {
                    loggerx.info(`No se detectaron cambios en la actualización para el usuario ${userId}`);
                    return currentUser;
                }

                // Añadir campo updatedBy si adminUser está definido
                if (adminUser && adminUser._id) {
                    updateFields.updatedBy = adminUser._id;
                }

                // Actualizar usuario sin usar sesión
                const updatedUser = await User.findByIdAndUpdate(
                    userId,
                    { $set: updateFields },
                    { new: true, runValidators: true }
                );

                // Registrar en el historial de cambios sin usar sesión
                const auditTrail = new AuditTrail({
                    entityType: "user",
                    entityId: userId,
                    action: "update",
                    changes,
                    previousData,
                    performedBy: adminUser ? adminUser._id : undefined,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Actualización de usuario"
                });

                await auditTrail.save();

                // Registrar actividad
                loggerx.info({
                    action: "USER_UPDATED",
                    user: userId.toString(),
                    username: updatedUser.username,
                    updatedBy: adminUser ? adminUser._id.toString() : "sistema",
                    changes,
                    timestamp: new Date()
                });

                return updatedUser;
            } catch (error) {
                loggerx.error(`Error al actualizar usuario: ${error.message}`);
                throw error;
            }
        } else {
            // En producción, sí usamos transacciones
            const session = await mongoose.startSession();
            session.startTransaction();

            try {
                // Obtener usuario actual para registrar cambios
                const currentUser = await User.findById(userId);

                if (!currentUser) {
                    throw new Error("Usuario no encontrado");
                }

                // Verificar si se intenta cambiar el username y si ya existe
                if (updateData.username &&
                    updateData.username.toLowerCase() !== currentUser.username.toLowerCase()) {
                    const existingUser = await User.findOne({
                        username: updateData.username.toLowerCase(),
                        _id: { $ne: userId }
                    });

                    if (existingUser) {
                        throw new Error("El nombre de usuario ya está en uso");
                    }
                }

                // Preparar datos para actualizar
                const updateFields = {};
                const changes = {};
                const previousData = {};

                // Campos permitidos para actualizar
                const allowedFields = ['username', 'fullName', 'role', 'status'];

                // Detectar si se están intentando actualizar campos no permitidos
                const receivedFields = Object.keys(updateData);
                const nonAllowedFields = receivedFields.filter(field =>
                    !allowedFields.includes(field) && field !== 'notes'
                );

                // Registrar advertencia si se reciben campos no permitidos
                if (nonAllowedFields.length > 0) {
                    loggerx.warn({
                        action: "INVALID_UPDATE_FIELDS",
                        user: userId.toString(),
                        fields: nonAllowedFields,
                        requestData: updateData,
                        message: "Estos campos serán ignorados en la actualización"
                    });
                }

                allowedFields.forEach(field => {
                    if (updateData[field] !== undefined &&
                        updateData[field] !== currentUser[field]) {
                        updateFields[field] = updateData[field];
                        changes[field] = updateData[field];
                        previousData[field] = currentUser[field];
                    }
                });

                // Si no hay cambios, retornar usuario actual
                if (Object.keys(changes).length === 0) {
                    loggerx.info(`No se detectaron cambios en la actualización para el usuario ${userId}`);
                    return currentUser;
                }

                // Añadir campo updatedBy
                updateFields.updatedBy = adminUser._id;

                // Actualizar usuario
                const updatedUser = await User.findByIdAndUpdate(
                    userId,
                    { $set: updateFields },
                    { new: true, runValidators: true, session }
                );

                // Registrar en el historial de cambios
                const auditTrail = new AuditTrail({
                    entityType: "user",
                    entityId: userId,
                    action: "update",
                    changes,
                    previousData,
                    performedBy: adminUser._id,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Actualización de usuario"
                });

                await auditTrail.save({ session });

                // Confirmar transacción
                await session.commitTransaction();

                // Registrar actividad
                loggerx.info({
                    action: "USER_UPDATED",
                    user: userId.toString(),
                    username: updatedUser.username,
                    updatedBy: adminUser ? adminUser._id.toString() : "sistema",
                    changes,
                    timestamp: new Date()
                });

                return updatedUser;
            } catch (error) {
                // Revertir transacción en caso de error
                await session.abortTransaction();

                loggerx.error(`Error al actualizar usuario: ${error.message}`);
                throw error;
            } finally {
                session.endSession();
            }
        }
    }

    /**
     * Cambia la contraseña de un usuario
     * @param {String} userId - ID del usuario
     * @param {Object} newPassword - Datos de la nueva contraseña
     * @param {Object} adminUser - Usuario administrador que realiza la acción
     * @param {Object} metadata - Metadatos de la solicitud
     * @returns {Promise<Object>} Resultado de la operación
     */
    static async changePassword(userId, newPassword, adminUser, metadata = {}) {
        // Verificar si estamos en modo desarrollo para evitar usar transacciones
        const isDevelopment = process.env.NODE_ENV === 'development';

        // En modo desarrollo, no usamos transacciones
        if (isDevelopment) {
            try {
                console.log("Modo desarrollo: No se usarán transacciones MongoDB para cambiar contraseña");

                // Validar datos mínimos requeridos
                if (!newPassword || typeof newPassword !== 'string') {
                    throw new Error("Nueva contraseña requerida");
                }

                // Obtener usuario actual
                const user = await User.findById(userId);

                if (!user) {
                    throw new Error("Usuario no encontrado");
                }

                // Actualizar contraseña
                user.password = newPassword;

                // Establecer campo updatedBy si adminUser está definido
                if (adminUser && adminUser._id) {
                    user.updatedBy = adminUser._id;
                }

                // Guardar cambios
                await user.save();

                // Registrar en el historial de cambios
                const auditTrail = new AuditTrail({
                    entityType: "user",
                    entityId: userId,
                    action: "password_change",
                    changes: {
                        password: "**********" // No almacenamos la contraseña real
                    },
                    performedBy: adminUser ? adminUser._id : undefined,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Cambio de contraseña"
                });

                await auditTrail.save();

                // Registrar actividad
                loggerx.info({
                    action: "PASSWORD_CHANGED",
                    user: userId,
                    changedBy: adminUser ? adminUser._id : undefined,
                    timestamp: new Date()
                });

                return { success: true };
            } catch (error) {
                loggerx.error(`Error al cambiar contraseña: ${error.message}`);
                throw error;
            }
        } else {
            // En producción, sí usamos transacciones
            const session = await mongoose.startSession();
            session.startTransaction();

            try {
                // Verificar formato de la contraseña
                if (typeof newPassword !== 'string') {
                    throw new Error(`La contraseña debe ser una cadena de texto, se recibió: ${typeof newPassword}`);
                }

                if (newPassword.length < 8) {
                    throw new Error(`La contraseña debe tener al menos 8 caracteres, se recibió una de ${newPassword.length} caracteres`);
                }

                // Obtener usuario
                const user = await User.findById(userId).select('+password');

                if (!user) {
                    throw new Error("Usuario no encontrado");
                }

                // Verificar si la contraseña es igual a la actual
                const isSamePassword = await bcrypt.compare(newPassword, user.password);
                if (isSamePassword) {
                    throw new Error("La nueva contraseña es igual a la actual, debe ser diferente");
                }

                // Actualizar contraseña
                user.password = newPassword;
                user.updatedBy = adminUser._id;

                // Log detallado antes de guardar
                loggerx.info(`Guardando nueva contraseña para usuario ${userId}`);

                try {
                    await user.save({ session });
                    loggerx.info(`Contraseña actualizada correctamente para usuario ${userId}`);
                } catch (saveError) {
                    loggerx.error(`Error al guardar nueva contraseña: ${saveError.message}`);
                    loggerx.error(`Stack trace: ${saveError.stack}`);
                    throw saveError;
                }

                // Registrar en el historial de cambios (sin guardar la contraseña)
                const auditTrail = new AuditTrail({
                    entityType: "user",
                    entityId: userId,
                    action: "password_change",
                    changes: {
                        passwordChanged: true
                    },
                    performedBy: adminUser._id,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Cambio de contraseña"
                });

                await auditTrail.save({ session });

                // Confirmar transacción
                await session.commitTransaction();

                // Registrar actividad
                loggerx.info({
                    action: "PASSWORD_CHANGED",
                    user: userId,
                    changedBy: adminUser._id,
                    timestamp: new Date()
                });

                return true;
            } catch (error) {
                // Revertir transacción en caso de error
                await session.abortTransaction();

                loggerx.error(`Error al cambiar contraseña: ${error.message}`);
                throw error;
            } finally {
                session.endSession();
            }
        }
    }

    /**
     * Cambia el estado de un usuario (activar/desactivar)
     * @param {String} userId - ID del usuario
     * @param {String} newStatus - Nuevo estado ('active', 'inactive', 'deleted')
     * @param {Object} adminUser - Usuario administrador que realiza la acción
     * @param {Object} metadata - Metadatos de la solicitud
     * @returns {Promise<Object>} Usuario actualizado
     */
    static async changeUserStatus(userId, newStatus, adminUser, metadata = {}) {
        const session = await mongoose.startSession();
        session.startTransaction();

        try {
            // Validar estado
            if (!['active', 'inactive', 'deleted'].includes(newStatus)) {
                throw new Error("Estado no válido");
            }

            // Obtener usuario actual
            const currentUser = await User.findById(userId);

            if (!currentUser) {
                throw new Error("Usuario no encontrado");
            }

            // Si el estado es el mismo, retornar usuario actual
            if (currentUser.status === newStatus) {
                return currentUser;
            }

            // Actualizar estado
            const updatedUser = await User.findByIdAndUpdate(
                userId,
                {
                    $set: {
                        status: newStatus,
                        updatedBy: adminUser._id
                    }
                },
                { new: true, runValidators: true, session }
            );

            // Registrar en el historial de cambios
            const auditTrail = new AuditTrail({
                entityType: "user",
                entityId: userId,
                action: "status_change",
                changes: {
                    status: newStatus
                },
                previousData: {
                    status: currentUser.status
                },
                performedBy: adminUser._id,
                ipAddress: metadata.ipAddress,
                userAgent: metadata.userAgent,
                notes: metadata.notes || `Cambio de estado a ${newStatus}`
            });

            await auditTrail.save({ session });

            // Confirmar transacción
            await session.commitTransaction();

            // Registrar actividad
            loggerx.info({
                action: "USER_STATUS_CHANGED",
                user: userId,
                previousStatus: currentUser.status,
                newStatus,
                changedBy: adminUser._id,
                timestamp: new Date()
            });

            return updatedUser;
        } catch (error) {
            // Revertir transacción en caso de error
            await session.abortTransaction();

            loggerx.error(`Error al cambiar estado de usuario: ${error.message}`);
            throw error;
        } finally {
            session.endSession();
        }
    }

    /**
     * Elimina un usuario (soft delete)
     * @param {String} userId - ID del usuario a eliminar
     * @param {Object} adminUser - Usuario administrador que realiza la acción
     * @param {Object} metadata - Metadatos de la solicitud
     * @returns {Promise<Object>} Usuario actualizado
     */
    static async deleteUser(userId, adminUser, metadata = {}) {
        try {
            // Utilizar changeUserStatus para establecer el estado como "deleted"
            const deletedUser = await this.changeUserStatus(userId, "deleted", adminUser, {
                ...metadata,
                notes: metadata.notes || "Eliminación de usuario"
            });

            loggerx.info({
                action: "USER_DELETED",
                userId,
                deletedBy: adminUser ? adminUser._id.toString() : "sistema",
                timestamp: new Date()
            });

            return deletedUser;
        } catch (error) {
            loggerx.error(`Error al eliminar usuario: ${error.message}`);
            throw error;
        }
    }

    /**
     * Obtiene el historial de cambios de un usuario
     * @param {String} userId - ID del usuario
     * @param {Object} options - Opciones de paginación
     * @returns {Promise<Object>} Historial de cambios
     */
    static async getUserHistory(userId, options = {}) {
        try {
            const { page = 1, limit = 20 } = options;
            const skip = (page - 1) * limit;

            // Verificar si el usuario existe
            const userExists = await User.exists({ _id: userId });

            if (!userExists) {
                throw new Error("Usuario no encontrado");
            }

            // Obtener historial
            const history = await AuditTrail.find({
                entityType: "user",
                entityId: userId
            })
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .populate('performedBy', 'username fullName')
                .lean();

            const total = await AuditTrail.countDocuments({
                entityType: "user",
                entityId: userId
            });

            return {
                history,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            };
        } catch (error) {
            loggerx.error(`Error al obtener historial de usuario: ${error.message}`);
            throw error;
        }
    }

    /**
     * Obtiene usuarios con filtros y paginación
     * @param {Object} filters - Filtros a aplicar
     * @param {Object} pagination - Opciones de paginación
     * @param {Object} sort - Opciones de ordenamiento
     * @returns {Promise<Object>} Usuarios y paginación
     */
    static async getUsers(filters = {}, pagination = {}, sort = {}) {
        try {
            const { page = 1, limit = 10 } = pagination;
            const skip = (page - 1) * limit;

            // Construir filtros
            const query = { status: { $ne: "deleted" } };

            if (filters.role) query.role = filters.role;
            if (filters.status) query.status = filters.status;

            if (filters.search) {
                const searchRegex = new RegExp(filters.search, 'i');
                query.$or = [
                    { username: searchRegex },
                    { fullName: searchRegex }
                ];
            }

            // Ejecutar consulta
            const users = await User.find(query)
                .skip(skip)
                .limit(limit)
                .sort(sort.field ? { [sort.field]: sort.order === 'desc' ? -1 : 1 } : { createdAt: -1 })
                .populate('createdBy', 'username fullName')
                .populate('updatedBy', 'username fullName')
                .lean();

            const total = await User.countDocuments(query);

            return {
                users,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    pages: Math.ceil(total / limit)
                }
            };
        } catch (error) {
            loggerx.error(`Error al obtener usuarios: ${error.message}`);
            throw error;
        }
    }

    /**
     * Obtiene un usuario por ID
     * @param {String} userId - ID del usuario
     * @returns {Promise<Object>} Usuario
     */
    static async getUserById(userId) {
        try {
            const user = await User.findById(userId)
                .populate('createdBy', 'username fullName')
                .populate('updatedBy', 'username fullName')
                .lean();

            if (!user) {
                throw new Error("Usuario no encontrado");
            }

            return user;
        } catch (error) {
            loggerx.error(`Error al obtener usuario: ${error.message}`);
            throw error;
        }
    }
} 