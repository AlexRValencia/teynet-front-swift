import { loggerx } from "../../middleware/logger/logger.js";
import { MaintenanceService } from "../../services/maintenanceService.js";

/**
 * Crea una nueva tarea de mantenimiento
 */
export const createMaintenance = async (req, res) => {
    try {
        const maintenanceData = req.body;
        const currentUser = req.user; // Obtenido del middleware de autenticación

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes
        };

        loggerx.info({
            action: "CREATE_MAINTENANCE_REQUEST",
            deviceName: maintenanceData.deviceName,
            taskType: maintenanceData.taskType,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        const newMaintenance = await MaintenanceService.createMaintenance(maintenanceData, currentUser, metadata);

        return res.status(201).json({
            ok: true,
            message: "Tarea de mantenimiento creada exitosamente",
            data: newMaintenance
        });
    } catch (error) {
        loggerx.error({
            action: "CREATE_MAINTENANCE_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceData: {
                deviceName: req.body.deviceName,
                taskType: req.body.taskType
            }
        });

        console.error("Error detallado:", error);

        if (error.message.includes("no existe")) {
            return res.status(404).json({
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
            error: `Error al crear tarea de mantenimiento: ${error.message}`
        });
    }
};

/**
 * Obtiene detalles de una tarea de mantenimiento específica
 */
export const getMaintenanceDetails = async (req, res) => {
    try {
        if (!req.params.id) {
            return res.status(400).json({
                ok: false,
                error: 'Se requiere el ID de la tarea de mantenimiento'
            });
        }

        const maintenanceId = req.params.id;
        const maintenance = await MaintenanceService.getMaintenanceById(maintenanceId);

        return res.status(200).json({
            ok: true,
            data: maintenance
        });
    } catch (error) {
        loggerx.error(`Error en getMaintenanceDetails: ${error.message}`);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: 'Tarea de mantenimiento no encontrada'
            });
        }

        return res.status(500).json({
            ok: false,
            error: 'Error al obtener tarea de mantenimiento'
        });
    }
};

/**
 * Obtiene todas las tareas de mantenimiento con filtros y paginación
 */
export const getAllMaintenance = async (req, res) => {
    try {
        // Extraer parámetros de la solicitud
        const filters = {
            search: req.query.search,
            status: req.query.status,
            taskType: req.query.taskType,
            maintenanceType: req.query.maintenanceType,
            priority: req.query.priority,
            location: req.query.location,
            assignedTo: req.query.assignedTo,
            project: req.query.project,
            point: req.query.point,
            scheduledFrom: req.query.scheduledFrom,
            scheduledTo: req.query.scheduledTo
        };

        const pagination = {
            page: parseInt(req.query.page) || 1,
            limit: parseInt(req.query.limit) || 10
        };

        const sort = {
            field: req.query.sortBy || 'createdAt',
            order: req.query.sortOrder || 'desc'
        };

        // Obtener tareas a través del servicio
        const result = await MaintenanceService.getMaintenance(filters, pagination, sort);

        return res.status(200).json({
            ok: true,
            data: {
                maintenance: result.maintenance,
                pagination: result.pagination
            }
        });
    } catch (error) {
        loggerx.error(`Error en getAllMaintenance: ${error.message}`);
        return res.status(500).json({
            ok: false,
            error: "Error al obtener tareas de mantenimiento"
        });
    }
};

/**
 * Actualiza una tarea de mantenimiento existente
 */
export const updateMaintenance = async (req, res) => {
    try {
        const maintenanceId = req.params.id;
        const updateData = req.body;
        const currentUser = req.user;

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes
        };

        loggerx.info({
            action: "UPDATE_MAINTENANCE_REQUEST",
            maintenanceId,
            updateFields: Object.keys(updateData).filter(k => k !== 'notes'),
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        const updatedMaintenance = await MaintenanceService.updateMaintenance(maintenanceId, updateData, currentUser, metadata);

        return res.json({
            ok: true,
            message: "Tarea de mantenimiento actualizada exitosamente",
            data: updatedMaintenance
        });
    } catch (error) {
        loggerx.error({
            action: "UPDATE_MAINTENANCE_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id,
            updateData: Object.keys(req.body).filter(k => k !== 'notes')
        });

        console.error("Error detallado en actualización:", error);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: `Error al actualizar tarea de mantenimiento: ${error.message}`
        });
    }
};

/**
 * Actualiza una etapa específica de una tarea de mantenimiento
 */
export const updateMaintenanceStage = async (req, res) => {
    try {
        const maintenanceId = req.params.id;
        const stageId = req.params.stageId;
        const stageData = req.body;
        const currentUser = req.user;

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes
        };

        loggerx.info({
            action: "UPDATE_MAINTENANCE_STAGE_REQUEST",
            maintenanceId,
            stageId,
            updateFields: Object.keys(stageData).filter(k => k !== 'notes'),
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        const updatedMaintenance = await MaintenanceService.updateMaintenanceStage(maintenanceId, stageId, stageData, currentUser, metadata);

        return res.json({
            ok: true,
            message: "Etapa de tarea de mantenimiento actualizada exitosamente",
            data: updatedMaintenance
        });
    } catch (error) {
        loggerx.error({
            action: "UPDATE_MAINTENANCE_STAGE_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id,
            stageId: req.params.stageId,
            updateData: Object.keys(req.body).filter(k => k !== 'notes')
        });

        console.error("Error detallado en actualización de etapa:", error);

        if (error.message.includes("no encontrad")) {
            return res.status(404).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: `Error al actualizar etapa de tarea de mantenimiento: ${error.message}`
        });
    }
};

/**
 * Elimina una tarea de mantenimiento (soft delete)
 */
export const deleteMaintenance = async (req, res) => {
    try {
        const maintenanceId = req.params.id;

        // Crear un usuario por defecto si req.user es undefined
        const currentUser = req.user || {
            _id: "000000000000000000000000",
            username: "system",
            fullName: "Sistema"
        };

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            notes: req.body.notes || "Eliminación de tarea de mantenimiento"
        };

        loggerx.info({
            action: "DELETE_MAINTENANCE_REQUEST",
            maintenanceId,
            requestedBy: currentUser._id.toString()
        });

        await MaintenanceService.deleteMaintenance(maintenanceId, currentUser, metadata);

        return res.json({
            ok: true,
            message: "Tarea de mantenimiento eliminada exitosamente"
        });
    } catch (error) {
        loggerx.error({
            action: "DELETE_MAINTENANCE_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id
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
            error: `Error al eliminar tarea de mantenimiento: ${error.message}`
        });
    }
};

/**
 * Solicita apoyo para una tarea de mantenimiento
 */
export const requestSupport = async (req, res) => {
    try {
        const maintenanceId = req.params.id;
        const { requestDetails } = req.body;
        const currentUser = req.user;

        if (!requestDetails) {
            return res.status(400).json({
                ok: false,
                error: "Se requieren detalles para la solicitud de apoyo"
            });
        }

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        };

        loggerx.info({
            action: "REQUEST_MAINTENANCE_SUPPORT",
            maintenanceId,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        const updatedMaintenance = await MaintenanceService.requestSupport(maintenanceId, requestDetails, currentUser, metadata);

        return res.json({
            ok: true,
            message: "Solicitud de apoyo registrada exitosamente",
            data: updatedMaintenance
        });
    } catch (error) {
        loggerx.error({
            action: "REQUEST_MAINTENANCE_SUPPORT_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id
        });

        console.error("Error detallado en solicitud de apoyo:", error);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: error.message
            });
        }

        if (error.message.includes("Ya se ha solicitado")) {
            return res.status(409).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: `Error al solicitar apoyo: ${error.message}`
        });
    }
};

/**
 * Registra la generación de un informe para una tarea de mantenimiento
 */
export const registerReport = async (req, res) => {
    try {
        const maintenanceId = req.params.id;
        const { reportURL } = req.body;
        const currentUser = req.user;

        if (!reportURL) {
            return res.status(400).json({
                ok: false,
                error: "Se requiere la URL del informe generado"
            });
        }

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        };

        loggerx.info({
            action: "REGISTER_MAINTENANCE_REPORT",
            maintenanceId,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        const updatedMaintenance = await MaintenanceService.registerReport(maintenanceId, reportURL, currentUser, metadata);

        return res.json({
            ok: true,
            message: "Informe registrado exitosamente",
            data: updatedMaintenance
        });
    } catch (error) {
        loggerx.error({
            action: "REGISTER_MAINTENANCE_REPORT_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id
        });

        console.error("Error detallado en registro de informe:", error);

        if (error.message.includes("no encontrado")) {
            return res.status(404).json({
                ok: false,
                error: error.message
            });
        }

        return res.status(500).json({
            ok: false,
            error: `Error al registrar informe: ${error.message}`
        });
    }
};

/**
 * Añade fotos iniciales a una tarea de mantenimiento
 */
export const addInitialPhotos = async (req, res) => {
    try {
        const maintenanceId = req.params.id;
        const { photos } = req.body;
        const currentUser = req.user;

        if (!photos || !Array.isArray(photos) || photos.length === 0) {
            return res.status(400).json({
                ok: false,
                error: "Se requieren fotos iniciales para agregar"
            });
        }

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        };

        loggerx.info({
            action: "ADD_INITIAL_PHOTOS_REQUEST",
            maintenanceId,
            photoCount: photos.length,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        // Buscar la tarea existente
        const maintenance = await MaintenanceService.getMaintenanceById(maintenanceId);
        if (!maintenance) {
            return res.status(404).json({
                ok: false,
                error: "Tarea de mantenimiento no encontrada"
            });
        }

        // Preparar datos para actualización
        const updateData = {
            initialPhotos: photos.map(photo => ({
                imageName: photo.imageName || `inicial_${Date.now()}`,
                imageData: photo.imageData,
                caption: photo.caption || "Foto inicial",
                timestamp: photo.timestamp || new Date().toISOString()
            })),
            updatedBy: currentUser._id
        };

        // Actualizar la tarea
        const updatedMaintenance = await MaintenanceService.updateMaintenance(
            maintenanceId,
            updateData,
            currentUser,
            metadata
        );

        return res.status(200).json({
            ok: true,
            message: "Fotos iniciales agregadas exitosamente",
            data: updatedMaintenance
        });
    } catch (error) {
        loggerx.error({
            action: "ADD_INITIAL_PHOTOS_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id
        });

        console.error("Error detallado:", error);

        return res.status(500).json({
            ok: false,
            error: `Error al agregar fotos iniciales: ${error.message}`
        });
    }
};

/**
 * Añade fotos finales a una tarea de mantenimiento
 */
export const addFinalPhotos = async (req, res) => {
    try {
        const maintenanceId = req.params.id;
        const { photos } = req.body;
        const currentUser = req.user;

        if (!photos || !Array.isArray(photos) || photos.length === 0) {
            return res.status(400).json({
                ok: false,
                error: "Se requieren fotos finales para agregar"
            });
        }

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        };

        loggerx.info({
            action: "ADD_FINAL_PHOTOS_REQUEST",
            maintenanceId,
            photoCount: photos.length,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        // Buscar la tarea existente
        const maintenance = await MaintenanceService.getMaintenanceById(maintenanceId);
        if (!maintenance) {
            return res.status(404).json({
                ok: false,
                error: "Tarea de mantenimiento no encontrada"
            });
        }

        // Preparar datos para actualización
        const updateData = {
            finalPhotos: photos.map(photo => ({
                imageName: photo.imageName || `final_${Date.now()}`,
                imageData: photo.imageData,
                caption: photo.caption || "Foto final",
                timestamp: photo.timestamp || new Date().toISOString()
            })),
            updatedBy: currentUser._id
        };

        // Si se proporcionan fotos finales, considerar marcar la tarea como finalizada
        if (!maintenance.completedDate && !updateData.completedDate) {
            updateData.completedDate = new Date();
            updateData.status = 'Finalizado';
        }

        // Actualizar la tarea
        const updatedMaintenance = await MaintenanceService.updateMaintenance(
            maintenanceId,
            updateData,
            currentUser,
            metadata
        );

        return res.status(200).json({
            ok: true,
            message: "Fotos finales agregadas exitosamente",
            data: updatedMaintenance
        });
    } catch (error) {
        loggerx.error({
            action: "ADD_FINAL_PHOTOS_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id
        });

        console.error("Error detallado:", error);

        return res.status(500).json({
            ok: false,
            error: `Error al agregar fotos finales: ${error.message}`
        });
    }
};

/**
 * Actualiza los datos de equipos dañados
 */
export const updateDamagedEquipment = async (req, res) => {
    try {
        const maintenanceId = req.params.id;
        const { damagedEquipment } = req.body;
        const currentUser = req.user;

        if (!Array.isArray(damagedEquipment)) {
            return res.status(400).json({
                ok: false,
                error: "La lista de equipos dañados debe ser un array"
            });
        }

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        };

        loggerx.info({
            action: "UPDATE_DAMAGED_EQUIPMENT_REQUEST",
            maintenanceId,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        // Actualizar la tarea
        const updatedMaintenance = await MaintenanceService.updateMaintenance(
            maintenanceId,
            { damagedEquipment, updatedBy: currentUser._id },
            currentUser,
            metadata
        );

        return res.status(200).json({
            ok: true,
            message: "Equipos dañados actualizados exitosamente",
            data: updatedMaintenance
        });
    } catch (error) {
        loggerx.error({
            action: "UPDATE_DAMAGED_EQUIPMENT_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id
        });

        console.error("Error detallado:", error);

        return res.status(500).json({
            ok: false,
            error: `Error al actualizar equipos dañados: ${error.message}`
        });
    }
};

/**
 * Actualiza los datos de cable instalado
 */
export const updateCableInstalled = async (req, res) => {
    try {
        const maintenanceId = req.params.id;
        const { cableInstalled } = req.body;
        const currentUser = req.user;

        if (!cableInstalled || typeof cableInstalled !== 'object') {
            return res.status(400).json({
                ok: false,
                error: "Se requieren datos de cable instalado en formato correcto"
            });
        }

        // Validar campos del cable instalado
        const validatedCableData = {
            utp: parseFloat(cableInstalled.utp || 0),
            electrico: parseFloat(cableInstalled.electrico || 0),
            fibra: parseFloat(cableInstalled.fibra || 0)
        };

        // Metadatos para auditoría
        const metadata = {
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        };

        loggerx.info({
            action: "UPDATE_CABLE_INSTALLED_REQUEST",
            maintenanceId,
            cableData: validatedCableData,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        // Actualizar la tarea
        const updatedMaintenance = await MaintenanceService.updateMaintenance(
            maintenanceId,
            { cableInstalled: validatedCableData, updatedBy: currentUser._id },
            currentUser,
            metadata
        );

        return res.status(200).json({
            ok: true,
            message: "Cable instalado actualizado exitosamente",
            data: updatedMaintenance
        });
    } catch (error) {
        loggerx.error({
            action: "UPDATE_CABLE_INSTALLED_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id
        });

        console.error("Error detallado:", error);

        return res.status(500).json({
            ok: false,
            error: `Error al actualizar cable instalado: ${error.message}`
        });
    }
};

/**
 * Genera un PDF de la orden de servicio de mantenimiento
 */
export const generateServiceOrder = async (req, res) => {
    try {
        const maintenanceId = req.params.id;
        const currentUser = req.user;

        loggerx.info({
            action: "GENERATE_SERVICE_ORDER_REQUEST",
            maintenanceId,
            requestedBy: currentUser?._id.toString() || "anónimo"
        });

        // Obtener la tarea de mantenimiento completa
        const maintenance = await MaintenanceService.getMaintenanceById(maintenanceId);
        if (!maintenance) {
            return res.status(404).json({
                ok: false,
                error: "Tarea de mantenimiento no encontrada"
            });
        }

        // TODO: Implementar la generación real del PDF usando una biblioteca como PDFKit
        // Por ahora solo devolvemos un mensaje de éxito simulado

        // Actualizar la tarea con la URL del informe
        const reportURL = `/api/v1/maintenance/${maintenanceId}/report-pdf`;

        const updatedMaintenance = await MaintenanceService.registerReport(
            maintenanceId,
            reportURL,
            currentUser,
            { ipAddress: req.ip, userAgent: req.get('User-Agent') }
        );

        return res.status(200).json({
            ok: true,
            message: "Orden de servicio generada exitosamente",
            data: {
                maintenanceId,
                reportURL,
                maintenance: updatedMaintenance
            }
        });
    } catch (error) {
        loggerx.error({
            action: "GENERATE_SERVICE_ORDER_ERROR",
            error: {
                message: error.message,
                stack: error.stack
            },
            maintenanceId: req.params.id
        });

        console.error("Error detallado:", error);

        return res.status(500).json({
            ok: false,
            error: `Error al generar orden de servicio: ${error.message}`
        });
    }
}; 