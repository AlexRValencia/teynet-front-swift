import { loggerx } from "../../middleware/logger/logger.js";
import { ClientService } from "../../services/clientService.js";

/**
 * Crea un nuevo cliente
 */
export const createClient = async (req, res) => {
    try {
        const clientData = req.body;
        const currentUser = req.user; // Obtenido del middleware de autenticación

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes
        };

        loggerx.info({
            action: "CREATE_CLIENT_REQUEST",
            name: clientData.name,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        const newClient = await ClientService.createClient(clientData, currentUser, metadata);

        return res.status(201).json({
            ok: true,
            message: "Cliente creado exitosamente",
            data: newClient
        });
    } catch (error) {
        loggerx.error({
            action: "CREATE_CLIENT_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            clientData: {
                name: req.body.name
            }
        });

        console.error("Error detallado:", error);

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
            error: `Error al crear cliente: ${error.message}`
        });
    }
};

/**
 * Obtiene detalles de un cliente específico
 */
export const getClientDetails = async (req, res) => {
    try {
        if (!req.params.id) {
            return res.status(400).json({
                ok: false,
                error: 'Se requiere el ID del cliente'
            });
        }

        const clientId = req.params.id;
        const client = await ClientService.getClientById(clientId);

        // Asegurar que el ID sea devuelto como string en la propiedad id
        return res.status(200).json({
            ok: true,
            data: client
        });
    } catch (error) {
        loggerx.error(`Error en getClientDetails: ${error.message}`);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: 'Cliente no encontrado'
            });
        }

        return res.status(500).json({
            ok: false,
            error: 'Error al obtener cliente'
        });
    }
};

/**
 * Obtiene todos los clientes con filtros y paginación
 */
export const getAllClients = async (req, res) => {
    try {
        // Extraer parámetros de la solicitud
        const filters = {
            active: req.query.active !== undefined ? req.query.active === 'true' : undefined,
            search: req.query.search
        };

        const pagination = {
            page: parseInt(req.query.page) || 1,
            limit: parseInt(req.query.limit) || 10
        };

        const sort = {
            field: req.query.sortBy || 'name',
            order: req.query.sortOrder || 'asc'
        };

        // Obtener clientes a través del servicio
        const result = await ClientService.getClients(filters, pagination, sort);

        // Asegurar que los IDs sean manejados correctamente
        return res.status(200).json({
            ok: true,
            data: {
                clients: result.clients,
                pagination: result.pagination
            }
        });
    } catch (error) {
        loggerx.error(`Error en getAllClients: ${error.message}`);
        return res.status(500).json({
            ok: false,
            error: "Error al obtener clientes"
        });
    }
};

/**
 * Actualiza un cliente existente
 */
export const updateClient = async (req, res) => {
    try {
        const clientId = req.params.id;
        const updateData = req.body;
        const currentUser = req.user;

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes
        };

        loggerx.info({
            action: "UPDATE_CLIENT_REQUEST",
            clientId,
            updateFields: Object.keys(updateData).filter(k => k !== 'notes'),
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        const updatedClient = await ClientService.updateClient(clientId, updateData, currentUser, metadata);

        return res.json({
            ok: true,
            message: "Cliente actualizado exitosamente",
            data: updatedClient
        });
    } catch (error) {
        loggerx.error({
            action: "UPDATE_CLIENT_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            clientId: req.params.id,
            updateData: Object.keys(req.body).filter(k => k !== 'notes')
        });

        console.error("Error detallado en actualización:", error);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: error.message
            });
        }

        if (error.message.includes("ya existe")) {
            return res.status(409).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: `Error al actualizar cliente: ${error.message}`
        });
    }
};

/**
 * Elimina un cliente (soft delete)
 */
export const deleteClient = async (req, res) => {
    try {
        const clientId = req.params.id;
        const currentUser = req.user;

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes || "Eliminación de cliente"
        };

        loggerx.info({
            action: "DELETE_CLIENT_REQUEST",
            clientId,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        await ClientService.deleteClient(clientId, currentUser, metadata);

        return res.json({
            ok: true,
            message: "Cliente eliminado exitosamente"
        });
    } catch (error) {
        loggerx.error({
            action: "DELETE_CLIENT_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            clientId: req.params.id
        });

        console.error("Error detallado en eliminación:", error);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: `Error al eliminar cliente: ${error.message}`
        });
    }
};

/**
 * Obtiene el historial de cambios de un cliente
 */
export const getClientHistory = async (req, res) => {
    try {
        const clientId = req.params.id;

        const pagination = {
            page: parseInt(req.query.page) || 1,
            limit: parseInt(req.query.limit) || 20
        };

        const result = await ClientService.getClientHistory(clientId, pagination);

        // Transformar los ObjectId a strings para la respuesta
        const formattedHistory = result.history.map(entry => {
            const formattedEntry = entry.toObject();
            if (formattedEntry.performedBy) {
                formattedEntry.performedBy = formattedEntry.performedBy.toString();
            }
            if (formattedEntry.entityId) {
                formattedEntry.entityId = formattedEntry.entityId.toString();
            }
            return formattedEntry;
        });

        return res.json({
            ok: true,
            data: {
                history: formattedHistory,
                pagination: result.pagination
            }
        });
    } catch (error) {
        loggerx.error(`Error en getClientHistory: ${error.message}`);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: 'Cliente no encontrado'
            });
        }

        return res.status(500).json({
            ok: false,
            error: 'Error al obtener historial de cliente'
        });
    }
}; 