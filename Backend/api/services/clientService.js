import { loggerx } from "../middleware/logger/logger.js";
import Client from "../models/Client.js";
import { AuditTrail } from "../models/AuditTrail.js";
import mongoose from "mongoose";

export class ClientService {
    /**
     * Crea un nuevo cliente
     * @param {Object} clientData - Datos del cliente
     * @param {Object} currentUser - Usuario que realiza la acción
     * @param {Object} metadata - Metadatos para auditoria
     * @returns {Promise<Object>} Cliente creado
     */
    static async createClient(clientData, currentUser, metadata = {}) {
        // Verificar si estamos en modo desarrollo para evitar usar transacciones
        if (process.env.NODE_ENV === 'development') {
            try {
                loggerx.info("Modo desarrollo: No se usarán transacciones MongoDB para crear cliente");

                // Validar datos mínimos requeridos
                if (!clientData.name) {
                    throw new Error("Datos de cliente incompletos");
                }

                // Verificar si ya existe un cliente con el mismo nombre
                const existingClient = await Client.findOne({ name: clientData.name });
                if (existingClient) {
                    throw new Error("Ya existe un cliente con ese nombre");
                }

                // Crear objeto de cliente con los datos proporcionados
                const client = new Client({
                    name: clientData.name,
                    legalName: clientData.legalName || "",
                    rfc: clientData.rfc || null,
                    contactPerson: clientData.contactPerson || "",
                    email: clientData.email || "",
                    phone: clientData.phone || "",
                    address: clientData.address || "",
                    notes: clientData.notes || "",
                    active: clientData.active ?? true,
                    createdBy: currentUser ? currentUser._id : undefined,
                    updatedBy: currentUser ? currentUser._id : undefined
                });

                // Guardar cliente
                await client.save();

                // Registrar en el historial de cambios
                const auditTrail = new AuditTrail({
                    entityType: "client",
                    entityId: client._id,
                    action: "create",
                    changes: {
                        name: client.name,
                        legalName: client.legalName,
                        rfc: client.rfc,
                        contactPerson: client.contactPerson,
                        email: client.email,
                        phone: client.phone,
                        address: client.address,
                        notes: client.notes,
                        active: client.active
                    },
                    performedBy: currentUser ? currentUser._id : undefined,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Creación de cliente"
                });

                await auditTrail.save();

                return client;
            } catch (error) {
                loggerx.error(`Error al crear cliente: ${error.message}`);
                throw error;
            }
        } else {
            // En producción, sí usamos transacciones
            const session = await mongoose.startSession();
            session.startTransaction();

            try {
                // Validar datos
                if (!clientData.name) {
                    throw new Error("Datos de cliente incompletos");
                }

                // Verificar si el cliente ya existe
                const existingClient = await Client.findOne({
                    name: clientData.name
                });

                if (existingClient) {
                    throw new Error("Ya existe un cliente con ese nombre");
                }

                // Crear cliente
                const client = new Client({
                    name: clientData.name,
                    legalName: clientData.legalName || "",
                    rfc: clientData.rfc || null,
                    contactPerson: clientData.contactPerson || "",
                    email: clientData.email || "",
                    phone: clientData.phone || "",
                    address: clientData.address || "",
                    notes: clientData.notes || "",
                    active: clientData.active ?? true,
                    createdBy: currentUser ? currentUser._id : undefined,
                    updatedBy: currentUser ? currentUser._id : undefined
                });

                await client.save({ session });

                // Registrar en el historial de cambios
                const auditTrail = new AuditTrail({
                    entityType: "client",
                    entityId: client._id,
                    action: "create",
                    changes: {
                        name: client.name,
                        legalName: client.legalName,
                        rfc: client.rfc,
                        contactPerson: client.contactPerson,
                        email: client.email,
                        phone: client.phone,
                        address: client.address,
                        notes: client.notes,
                        active: client.active
                    },
                    performedBy: currentUser ? currentUser._id : undefined,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Creación de cliente"
                });

                await auditTrail.save({ session });

                // Confirmar transacción
                await session.commitTransaction();
                session.endSession();

                return client;
            } catch (error) {
                // Si hay algún error, abortar la transacción
                await session.abortTransaction();
                session.endSession();
                loggerx.error(`Error al crear cliente: ${error.message}`);
                throw error;
            }
        }
    }

    /**
     * Obtiene todos los clientes con filtros y paginación
     * @param {Object} filters - Filtros de búsqueda
     * @param {Object} pagination - Configuración de paginación
     * @param {Object} sort - Configuración de ordenamiento
     * @returns {Promise<Object>} Clientes y datos de paginación
     */
    static async getClients(filters = {}, pagination = {}, sort = {}) {
        try {
            const { active, search } = filters;
            const { page = 1, limit = 10 } = pagination;
            const { field = 'name', order = 'asc' } = sort;

            const skip = (page - 1) * limit;
            const sortOptions = { [field]: order === 'desc' ? -1 : 1 };

            // Construir query basado en filtros
            const query = {};

            // Filtro por estado (activo/inactivo)
            if (active !== undefined) {
                query.active = active;
            }

            // Búsqueda por texto en varios campos
            if (search) {
                query.$or = [
                    { name: { $regex: search, $options: 'i' } },
                    { contactPerson: { $regex: search, $options: 'i' } },
                    { email: { $regex: search, $options: 'i' } },
                    { phone: { $regex: search, $options: 'i' } },
                    { address: { $regex: search, $options: 'i' } }
                ];
            }

            // Obtener clientes y contar total para paginación
            const clientsPromise = Client.find(query)
                .sort(sortOptions)
                .skip(skip)
                .limit(limit);

            const totalPromise = Client.countDocuments(query);

            // Ejecutar ambas consultas en paralelo
            const [clients, total] = await Promise.all([clientsPromise, totalPromise]);

            // Calcular páginas para la paginación
            const totalPages = Math.ceil(total / limit);

            return {
                clients,
                pagination: {
                    total,
                    page,
                    limit,
                    totalPages
                }
            };
        } catch (error) {
            loggerx.error(`Error al obtener clientes: ${error.message}`);
            throw error;
        }
    }

    /**
     * Obtiene un cliente por su ID
     * @param {String} clientId - ID del cliente
     * @returns {Promise<Object>} Cliente encontrado
     */
    static async getClientById(clientId) {
        try {
            const client = await Client.findById(clientId);

            if (!client) {
                throw new Error("Cliente no encontrado");
            }

            return client;
        } catch (error) {
            loggerx.error(`Error al obtener cliente por ID: ${error.message}`);
            throw error;
        }
    }

    /**
     * Actualiza un cliente existente
     * @param {String} clientId - ID del cliente
     * @param {Object} updateData - Datos a actualizar
     * @param {Object} currentUser - Usuario que realiza la acción
     * @param {Object} metadata - Metadatos para auditoría
     * @returns {Promise<Object>} Cliente actualizado
     */
    static async updateClient(clientId, updateData, currentUser, metadata = {}) {
        // Verificar si estamos en modo desarrollo para evitar usar transacciones
        if (process.env.NODE_ENV === 'development') {
            try {
                loggerx.info("Modo desarrollo: No se usarán transacciones MongoDB para actualizar cliente");

                // Verificar si el cliente existe
                const client = await Client.findById(clientId);

                if (!client) {
                    throw new Error("Cliente no encontrado");
                }

                // Verificar si el nuevo nombre ya está en uso por otro cliente
                if (updateData.name && updateData.name !== client.name) {
                    const existingClient = await Client.findOne({
                        name: updateData.name,
                        _id: { $ne: clientId }
                    });

                    if (existingClient) {
                        throw new Error("Ya existe otro cliente con ese nombre");
                    }
                }

                // Guardar valores originales para auditoría
                const originalValues = {
                    name: client.name,
                    legalName: client.legalName,
                    rfc: client.rfc,
                    contactPerson: client.contactPerson,
                    email: client.email,
                    phone: client.phone,
                    address: client.address,
                    notes: client.notes,
                    active: client.active
                };

                // Actualizar los campos
                if (updateData.name) client.name = updateData.name;
                if (updateData.legalName !== undefined) client.legalName = updateData.legalName;
                if (updateData.rfc !== undefined) client.rfc = updateData.rfc;
                if (updateData.contactPerson !== undefined) client.contactPerson = updateData.contactPerson;
                if (updateData.email !== undefined) client.email = updateData.email;
                if (updateData.phone !== undefined) client.phone = updateData.phone;
                if (updateData.address !== undefined) client.address = updateData.address;
                if (updateData.notes !== undefined) client.notes = updateData.notes;
                if (updateData.active !== undefined) client.active = updateData.active;

                // Actualizar metadatos
                client.updatedBy = currentUser ? currentUser._id : undefined;

                // Guardar cambios
                await client.save();

                // Identificar cambios para auditoría
                const changes = {};
                for (const key in originalValues) {
                    if (originalValues[key] !== client[key]) {
                        changes[key] = {
                            from: originalValues[key],
                            to: client[key]
                        };
                    }
                }

                // Solo crear registro de auditoría si hay cambios
                if (Object.keys(changes).length > 0) {
                    const auditTrail = new AuditTrail({
                        entityType: "client",
                        entityId: client._id,
                        action: "update",
                        changes,
                        performedBy: currentUser ? currentUser._id : undefined,
                        ipAddress: metadata.ipAddress,
                        userAgent: metadata.userAgent,
                        notes: metadata.notes || "Actualización de cliente"
                    });

                    await auditTrail.save();
                }

                return client;
            } catch (error) {
                loggerx.error(`Error al actualizar cliente: ${error.message}`);
                throw error;
            }
        } else {
            // En producción, sí usamos transacciones
            const session = await mongoose.startSession();
            session.startTransaction();

            try {
                // Verificar si el cliente existe
                const client = await Client.findById(clientId).session(session);

                if (!client) {
                    throw new Error("Cliente no encontrado");
                }

                // Verificar si el nuevo nombre ya está en uso por otro cliente
                if (updateData.name && updateData.name !== client.name) {
                    const existingClient = await Client.findOne({
                        name: updateData.name,
                        _id: { $ne: clientId }
                    }).session(session);

                    if (existingClient) {
                        throw new Error("Ya existe otro cliente con ese nombre");
                    }
                }

                // Guardar valores originales para auditoría
                const originalValues = {
                    name: client.name,
                    legalName: client.legalName,
                    rfc: client.rfc,
                    contactPerson: client.contactPerson,
                    email: client.email,
                    phone: client.phone,
                    address: client.address,
                    notes: client.notes,
                    active: client.active
                };

                // Actualizar los campos
                if (updateData.name) client.name = updateData.name;
                if (updateData.legalName !== undefined) client.legalName = updateData.legalName;
                if (updateData.rfc !== undefined) client.rfc = updateData.rfc;
                if (updateData.contactPerson !== undefined) client.contactPerson = updateData.contactPerson;
                if (updateData.email !== undefined) client.email = updateData.email;
                if (updateData.phone !== undefined) client.phone = updateData.phone;
                if (updateData.address !== undefined) client.address = updateData.address;
                if (updateData.notes !== undefined) client.notes = updateData.notes;
                if (updateData.active !== undefined) client.active = updateData.active;

                // Actualizar metadatos
                client.updatedBy = currentUser ? currentUser._id : undefined;

                // Guardar cambios
                await client.save({ session });

                // Identificar cambios para auditoría
                const changes = {};
                for (const key in originalValues) {
                    if (originalValues[key] !== client[key]) {
                        changes[key] = {
                            from: originalValues[key],
                            to: client[key]
                        };
                    }
                }

                // Solo crear registro de auditoría si hay cambios
                if (Object.keys(changes).length > 0) {
                    const auditTrail = new AuditTrail({
                        entityType: "client",
                        entityId: client._id,
                        action: "update",
                        changes,
                        performedBy: currentUser ? currentUser._id : undefined,
                        ipAddress: metadata.ipAddress,
                        userAgent: metadata.userAgent,
                        notes: metadata.notes || "Actualización de cliente"
                    });

                    await auditTrail.save({ session });
                }

                // Confirmar transacción
                await session.commitTransaction();
                session.endSession();

                return client;
            } catch (error) {
                // Abortar transacción en caso de error
                await session.abortTransaction();
                session.endSession();

                loggerx.error(`Error al actualizar cliente: ${error.message}`);
                throw error;
            }
        }
    }

    /**
     * Elimina un cliente (soft delete)
     * @param {String} clientId - ID del cliente a eliminar
     * @param {Object} currentUser - Usuario que realiza la acción
     * @param {Object} metadata - Metadatos para auditoría
     * @returns {Promise<Boolean>} Resultado de la operación
     */
    static async deleteClient(clientId, currentUser, metadata = {}) {
        // Verificar si estamos en modo desarrollo para evitar usar transacciones
        if (process.env.NODE_ENV === 'development') {
            try {
                loggerx.info("Modo desarrollo: No se usarán transacciones MongoDB para eliminar cliente");

                // Verificar si el cliente existe
                const client = await Client.findById(clientId);

                if (!client) {
                    throw new Error("Cliente no encontrado");
                }

                // En lugar de eliminar, marcar como inactivo
                client.active = false;
                client.updatedBy = currentUser ? currentUser._id : undefined;

                await client.save();

                // Registrar en auditoria
                const auditTrail = new AuditTrail({
                    entityType: "client",
                    entityId: client._id,
                    action: "delete",
                    changes: {
                        active: {
                            from: true,
                            to: false
                        }
                    },
                    performedBy: currentUser ? currentUser._id : undefined,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Eliminación de cliente (soft delete)"
                });

                await auditTrail.save();

                return true;
            } catch (error) {
                loggerx.error(`Error al eliminar cliente: ${error.message}`);
                throw error;
            }
        } else {
            // En producción, sí usamos transacciones
            const session = await mongoose.startSession();
            session.startTransaction();

            try {
                // Verificar si el cliente existe
                const client = await Client.findById(clientId).session(session);

                if (!client) {
                    throw new Error("Cliente no encontrado");
                }

                // En lugar de eliminar, marcar como inactivo
                client.active = false;
                client.updatedBy = currentUser ? currentUser._id : undefined;

                await client.save({ session });

                // Registrar en auditoria
                const auditTrail = new AuditTrail({
                    entityType: "client",
                    entityId: client._id,
                    action: "delete",
                    changes: {
                        active: {
                            from: true,
                            to: false
                        }
                    },
                    performedBy: currentUser ? currentUser._id : undefined,
                    ipAddress: metadata.ipAddress,
                    userAgent: metadata.userAgent,
                    notes: metadata.notes || "Eliminación de cliente (soft delete)"
                });

                await auditTrail.save({ session });

                // Confirmar transacción
                await session.commitTransaction();
                session.endSession();

                return true;
            } catch (error) {
                // Abortar transacción en caso de error
                await session.abortTransaction();
                session.endSession();

                loggerx.error(`Error al eliminar cliente: ${error.message}`);
                throw error;
            }
        }
    }

    /**
     * Obtiene el historial de cambios de un cliente
     * @param {String} clientId - ID del cliente
     * @param {Object} pagination - Opciones de paginación
     * @returns {Promise<Object>} Historial y datos de paginación
     */
    static async getClientHistory(clientId, pagination = {}) {
        try {
            const { page = 1, limit = 20 } = pagination;
            const skip = (page - 1) * limit;

            // Verificar si el cliente existe
            const client = await Client.findById(clientId);

            if (!client) {
                throw new Error("Cliente no encontrado");
            }

            // Obtener historial de cambios
            const historyQuery = {
                entityType: "client",
                entityId: clientId
            };

            // Ejecutar las consultas - sin populate para simplificar
            const history = await AuditTrail.find(historyQuery)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit);

            const total = await AuditTrail.countDocuments(historyQuery);

            // Calcular total de páginas
            const totalPages = Math.ceil(total / limit);

            return {
                history,
                pagination: {
                    total,
                    page,
                    limit,
                    totalPages
                }
            };
        } catch (error) {
            loggerx.error(`Error al obtener historial de cliente: ${error.message}`);
            throw error;
        }
    }
} 