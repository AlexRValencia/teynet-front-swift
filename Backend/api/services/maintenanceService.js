import Maintenance from '../models/Maintenance.js';
import Project from '../models/Project.js';
import Point from '../models/Point.js';
import { User } from '../models/User.js';
import { AuditTrail } from '../models/AuditTrail.js';
import mongoose from 'mongoose';
import { loggerx } from '../middleware/logger/logger.js';

export class MaintenanceService {
    /**
     * Crea una nueva tarea de mantenimiento
     * @param {Object} maintenanceData - Datos para la tarea de mantenimiento
     * @param {Object} currentUser - Usuario que realiza la operación
     * @param {Object} metadata - Metadatos adicionales para auditoría
     * @returns {Promise<Object>} La tarea de mantenimiento creada
     */
    static async createMaintenance(maintenanceData, currentUser, metadata = {}) {
        if (!maintenanceData || !currentUser) {
            throw new Error("Datos de mantenimiento o usuario incompletos");
        }

        try {
            // Validar los datos de la tarea de mantenimiento
            if (!maintenanceData.taskType || !maintenanceData.maintenanceType ||
                !maintenanceData.description || !maintenanceData.scheduledDate ||
                !maintenanceData.assignedTo || !maintenanceData.priority ||
                !maintenanceData.location || !maintenanceData.siteName) {
                throw new Error('Faltan campos requeridos para crear la tarea de mantenimiento');
            }

            // Si se proporciona un punto, verificar que exista y usar su información
            if (maintenanceData.point) {
                const point = await Point.findById(maintenanceData.point);
                if (!point) {
                    throw new Error(`No se encontró el punto con ID ${maintenanceData.point}`);
                }
                // Guardar el tipo de punto
                maintenanceData.pointType = point.type;

                // Si hay coordenadas del punto, usarlas
                if (point.location && point.location.coordinates) {
                    maintenanceData.pointCoordinates = [
                        point.location.coordinates[1], // latitud
                        point.location.coordinates[0]  // longitud
                    ];
                }
            }

            // Validar proyecto si se proporciona
            if (maintenanceData.project) {
                const project = await Project.findById(maintenanceData.project);
                if (!project) {
                    throw new Error(`No se encontró el proyecto con ID ${maintenanceData.project}`);
                }
                maintenanceData.projectName = project.name;
            }

            // Formatear fechas
            if (maintenanceData.scheduledDate && typeof maintenanceData.scheduledDate === 'string') {
                maintenanceData.scheduledDate = new Date(maintenanceData.scheduledDate);
            }

            if (maintenanceData.completedDate && typeof maintenanceData.completedDate === 'string') {
                maintenanceData.completedDate = new Date(maintenanceData.completedDate);
            }

            if (maintenanceData.serviceDate && typeof maintenanceData.serviceDate === 'string') {
                maintenanceData.serviceDate = new Date(maintenanceData.serviceDate);
            }

            // Manejar el objeto cableInstalled si viene en formato antiguo
            if (maintenanceData.cableInstalled && typeof maintenanceData.cableInstalled === 'object' && !(maintenanceData.cableInstalled instanceof Array)) {
                const oldCableInstalled = maintenanceData.cableInstalled;

                // Convertir al nuevo formato
                maintenanceData.cableInstalled = {
                    utp: parseFloat(oldCableInstalled.utp || 0),
                    electrico: parseFloat(oldCableInstalled.electrico || 0),
                    fibra: parseFloat(oldCableInstalled.fibra || 0)
                };
            }

            // Asignar usuario creador
            maintenanceData.createdBy = currentUser._id;

            // Crear nueva tarea de mantenimiento
            const newMaintenance = new Maintenance(maintenanceData);
            await newMaintenance.save();

            // Registrar auditoría
            await AuditTrail.create({
                entityId: newMaintenance._id,
                entityType: 'maintenance',
                action: 'create',
                changes: {
                    before: null,
                    after: { ...maintenanceData }
                },
                performedBy: currentUser._id,
                ipAddress: metadata.ipAddress,
                userAgent: metadata.userAgent,
                notes: metadata.notes
            });

            // Devolver la tarea creada formateada
            return this.formatMaintenanceData(newMaintenance);
        } catch (error) {
            loggerx.error(`Error al crear tarea de mantenimiento: ${error.message}`);
            throw error;
        }
    }

    /**
     * Obtiene una tarea de mantenimiento por su ID
     * @param {string} maintenanceId - ID de la tarea de mantenimiento
     * @returns {Promise<Object>} La tarea de mantenimiento
     */
    static async getMaintenanceById(maintenanceId) {
        try {
            if (!mongoose.Types.ObjectId.isValid(maintenanceId)) {
                throw new Error("ID de mantenimiento inválido");
            }

            const maintenance = await Maintenance.findById(maintenanceId)
                .populate('createdBy', 'username fullName')
                .populate('updatedBy', 'username fullName')
                .populate('project', 'name')
                .populate('point', 'name type');

            if (!maintenance) {
                throw new Error(`Mantenimiento con ID ${maintenanceId} no encontrado`);
            }

            // No devolver mantenimientos con estado "Cancelado" (eliminados lógicamente)
            if (maintenance.status === 'Cancelado') {
                throw new Error(`Mantenimiento con ID ${maintenanceId} no encontrado o ha sido eliminado`);
            }

            return this.formatMaintenanceData(maintenance);
        } catch (error) {
            loggerx.error(`Error al obtener tarea de mantenimiento: ${error.message}`);
            throw error;
        }
    }

    /**
     * Obtiene todas las tareas de mantenimiento con filtros y paginación
     * @param {Object} filters - Filtros a aplicar
     * @param {Object} pagination - Configuración de paginación
     * @param {Object} sort - Configuración de ordenamiento
     * @returns {Promise<Object>} Tareas de mantenimiento y datos de paginación
     */
    static async getMaintenance(filters = {}, pagination = {}, sort = {}) {
        try {
            const query = {};

            // Aplicar filtros de búsqueda
            if (filters.search) {
                const searchRegex = new RegExp(filters.search, 'i');
                query.$or = [
                    { deviceName: searchRegex },
                    { description: searchRegex },
                    { assignedTo: searchRegex },
                    { siteName: searchRegex },
                    { projectName: searchRegex }
                ];
            }

            // Filtrar por estado
            if (filters.status) {
                query.status = filters.status;
            } else {
                // Por defecto, excluir tareas con estado "Cancelado" (eliminadas lógicamente)
                query.status = { $ne: 'Cancelado' };
            }

            // Filtrar por tipo de tarea
            if (filters.taskType) {
                query.taskType = filters.taskType;
            }

            // Filtrar por tipo de mantenimiento
            if (filters.maintenanceType) {
                query.maintenanceType = filters.maintenanceType;
            }

            // Filtrar por prioridad
            if (filters.priority) {
                query.priority = filters.priority;
            }

            // Filtrar por localidad
            if (filters.location) {
                query.location = filters.location;
            }

            // Filtrar por persona asignada
            if (filters.assignedTo) {
                query.assignedTo = new RegExp(filters.assignedTo, 'i');
            }

            // Filtrar por proyecto
            if (filters.project) {
                query.project = filters.project;
            }

            // Filtrar por punto
            if (filters.point) {
                query.point = filters.point;
            }

            // Filtrar por rango de fechas programadas
            if (filters.scheduledFrom || filters.scheduledTo) {
                query.scheduledDate = {};
                if (filters.scheduledFrom) {
                    query.scheduledDate.$gte = new Date(filters.scheduledFrom);
                }
                if (filters.scheduledTo) {
                    query.scheduledDate.$lte = new Date(filters.scheduledTo);
                }
            }

            // Configurar paginación
            const page = pagination.page || 1;
            const limit = pagination.limit || 10;
            const skip = (page - 1) * limit;

            // Configurar ordenamiento
            const sortOptions = {};
            if (sort.field && sort.order) {
                sortOptions[sort.field] = sort.order === 'asc' ? 1 : -1;
            } else {
                // Ordenamiento por defecto: fecha de creación descendente
                sortOptions.createdAt = -1;
            }

            // Ejecutar consulta con paginación y contador total
            const [maintenance, total] = await Promise.all([
                Maintenance.find(query)
                    .populate('createdBy', 'username fullName')
                    .populate('updatedBy', 'username fullName')
                    .populate('project', 'name')
                    .populate('point', 'name type')
                    .sort(sortOptions)
                    .skip(skip)
                    .limit(limit),
                Maintenance.countDocuments(query)
            ]);

            // Formatear resultados
            const formattedMaintenance = maintenance.map(task => this.formatMaintenanceData(task));

            // Calcular datos de paginación
            const totalPages = Math.ceil(total / limit);

            return {
                maintenance: formattedMaintenance,
                pagination: {
                    total,
                    page,
                    limit,
                    totalPages
                }
            };
        } catch (error) {
            loggerx.error(`Error al obtener tareas de mantenimiento: ${error.message}`);
            throw error;
        }
    }

    /**
     * Actualiza una tarea de mantenimiento existente
     * @param {string} maintenanceId - ID de la tarea a actualizar
     * @param {Object} updateData - Datos para actualizar
     * @param {Object} currentUser - Usuario que realiza la operación
     * @param {Object} metadata - Metadatos adicionales para auditoría
     * @returns {Promise<Object>} La tarea de mantenimiento actualizada
     */
    static async updateMaintenance(maintenanceId, updateData, currentUser, metadata = {}) {
        try {
            if (!mongoose.Types.ObjectId.isValid(maintenanceId)) {
                throw new Error("ID de mantenimiento inválido");
            }

            // Buscar la tarea existente
            const existingMaintenance = await Maintenance.findById(maintenanceId);
            if (!existingMaintenance) {
                throw new Error(`Mantenimiento con ID ${maintenanceId} no encontrado`);
            }

            // Verificar si el proyecto existe (si se cambia)
            if (updateData.project && String(existingMaintenance.project) !== String(updateData.project)) {
                const projectExists = await Project.findById(updateData.project);
                if (!projectExists) {
                    throw new Error(`El proyecto con ID ${updateData.project} no existe`);
                }
                // Actualizar el nombre del proyecto
                updateData.projectName = projectExists.name;
            }

            // Verificar si el punto existe (si se cambia)
            if (updateData.point && String(existingMaintenance.point) !== String(updateData.point)) {
                const pointExists = await Point.findById(updateData.point);
                if (!pointExists) {
                    throw new Error(`El punto con ID ${updateData.point} no existe`);
                }
                // Actualizar el tipo de punto
                updateData.pointType = pointExists.type;

                // Si hay coordenadas del punto, usarlas
                if (pointExists.location && pointExists.location.coordinates) {
                    updateData.pointCoordinates = [
                        pointExists.location.coordinates[1], // latitud
                        pointExists.location.coordinates[0]  // longitud
                    ];
                }
            }

            // Formatear las fechas
            if (updateData.scheduledDate && typeof updateData.scheduledDate === 'string') {
                updateData.scheduledDate = new Date(updateData.scheduledDate);
            }

            if (updateData.completedDate && typeof updateData.completedDate === 'string') {
                updateData.completedDate = new Date(updateData.completedDate);
            }

            if (updateData.serviceDate && typeof updateData.serviceDate === 'string') {
                updateData.serviceDate = new Date(updateData.serviceDate);
            }

            // Asignar usuario que actualiza
            updateData.updatedBy = currentUser._id;

            // Guardar estado anterior para auditoría
            const previousState = existingMaintenance.toObject();

            // Actualizar tarea
            const updatedMaintenance = await Maintenance.findByIdAndUpdate(
                maintenanceId,
                { $set: updateData },
                { new: true, runValidators: true }
            ).populate('createdBy', 'username fullName')
                .populate('updatedBy', 'username fullName')
                .populate('project', 'name')
                .populate('point', 'name type');

            // Registrar auditoría
            await AuditTrail.create({
                entityId: maintenanceId,
                entityType: 'maintenance',
                action: 'update',
                changes: {
                    before: previousState,
                    after: updatedMaintenance.toObject()
                },
                performedBy: currentUser._id,
                ipAddress: metadata.ipAddress,
                userAgent: metadata.userAgent,
                notes: metadata.notes
            });

            return this.formatMaintenanceData(updatedMaintenance);
        } catch (error) {
            loggerx.error(`Error al actualizar tarea de mantenimiento: ${error.message}`);
            throw error;
        }
    }

    /**
     * Actualiza una etapa específica de una tarea de mantenimiento
     * @param {string} maintenanceId - ID de la tarea
     * @param {string} stageId - ID de la etapa
     * @param {Object} stageData - Datos para actualizar la etapa
     * @param {Object} currentUser - Usuario que realiza la operación
     * @param {Object} metadata - Metadatos adicionales para auditoría
     * @returns {Promise<Object>} La tarea de mantenimiento actualizada
     */
    static async updateMaintenanceStage(maintenanceId, stageId, stageData, currentUser, metadata = {}) {
        try {
            if (!mongoose.Types.ObjectId.isValid(maintenanceId)) {
                throw new Error("ID de mantenimiento inválido");
            }

            // Buscar la tarea existente
            const maintenance = await Maintenance.findById(maintenanceId);
            if (!maintenance) {
                throw new Error(`Mantenimiento con ID ${maintenanceId} no encontrado`);
            }

            // Buscar la etapa
            const stageIndex = maintenance.stages.findIndex(stage => String(stage._id) === String(stageId));
            if (stageIndex === -1) {
                throw new Error(`Etapa con ID ${stageId} no encontrada en la tarea de mantenimiento`);
            }

            // Guardar estado anterior para auditoría
            const previousState = maintenance.toObject();

            // Actualizar la etapa
            if (stageData.name) maintenance.stages[stageIndex].name = stageData.name;
            if (stageData.description) maintenance.stages[stageIndex].description = stageData.description;
            if (stageData.percentageValue !== undefined) maintenance.stages[stageIndex].percentageValue = stageData.percentageValue;
            if (stageData.isCompleted !== undefined) maintenance.stages[stageIndex].isCompleted = stageData.isCompleted;

            // Actualizar fotos si se proporcionan
            if (stageData.photos) {
                // Si se envía un array vacío, eliminar todas las fotos
                if (Array.isArray(stageData.photos) && stageData.photos.length === 0) {
                    maintenance.stages[stageIndex].photos = [];
                }
                // Si se envía una nueva foto para agregar
                else if (stageData.newPhoto) {
                    maintenance.stages[stageIndex].photos.push({
                        imageName: stageData.newPhoto.imageName || `foto_${Date.now()}`,
                        imageData: stageData.newPhoto.imageData,
                        caption: stageData.newPhoto.caption || '',
                        timestamp: new Date()
                    });
                }
            }

            // Actualizar usuario que modifica
            maintenance.updatedBy = currentUser._id;

            // Guardar cambios
            await maintenance.save();

            // Obtener la tarea actualizada con relaciones
            const updatedMaintenance = await Maintenance.findById(maintenanceId)
                .populate('createdBy', 'username fullName')
                .populate('updatedBy', 'username fullName')
                .populate('project', 'name')
                .populate('point', 'name type');

            // Registrar auditoría
            await AuditTrail.create({
                entityId: maintenanceId,
                entityType: 'maintenance',
                action: 'update',
                changes: {
                    before: previousState,
                    after: updatedMaintenance.toObject(),
                    stageId: stageId
                },
                performedBy: currentUser._id,
                ipAddress: metadata.ipAddress,
                userAgent: metadata.userAgent,
                notes: metadata.notes
            });

            return this.formatMaintenanceData(updatedMaintenance);
        } catch (error) {
            loggerx.error(`Error al actualizar etapa de mantenimiento: ${error.message}`);
            throw error;
        }
    }

    /**
     * Elimina una tarea de mantenimiento (eliminación lógica)
     * @param {string} maintenanceId - ID de la tarea a eliminar
     * @param {Object} currentUser - Usuario que realiza la operación
     * @param {Object} metadata - Metadatos adicionales para auditoría
     * @returns {Promise<boolean>} True si se eliminó correctamente
     */
    static async deleteMaintenance(maintenanceId, currentUser = { _id: "000000000000000000000000" }, metadata = {}) {
        try {
            if (!mongoose.Types.ObjectId.isValid(maintenanceId)) {
                throw new Error("ID de mantenimiento inválido");
            }

            // Buscar la tarea existente
            const maintenance = await Maintenance.findById(maintenanceId);
            if (!maintenance) {
                throw new Error(`Mantenimiento con ID ${maintenanceId} no encontrado`);
            }

            // Guardar estado anterior para auditoría
            const previousState = maintenance.toObject();

            // Realizar eliminación lógica cambiando el estado a "Cancelado"
            maintenance.status = 'Cancelado';

            // Verificar si currentUser tiene _id antes de asignarlo
            if (currentUser && currentUser._id) {
                maintenance.updatedBy = currentUser._id;
            }

            await maintenance.save();

            // Registrar auditoría
            await AuditTrail.create({
                entityId: maintenanceId,
                entityType: 'maintenance',
                action: 'delete',
                changes: {
                    before: previousState,
                    after: maintenance.toObject()
                },
                performedBy: currentUser._id || "000000000000000000000000",
                ipAddress: metadata.ipAddress,
                userAgent: metadata.userAgent,
                notes: metadata.notes
            });

            return true;
        } catch (error) {
            loggerx.error(`Error al eliminar tarea de mantenimiento: ${error.message}`);
            throw error;
        }
    }

    /**
     * Solicita apoyo para una tarea de mantenimiento
     * @param {string} maintenanceId - ID de la tarea
     * @param {string} requestDetails - Detalles de la solicitud de apoyo
     * @param {Object} currentUser - Usuario que realiza la operación
     * @param {Object} metadata - Metadatos adicionales para auditoría
     * @returns {Promise<Object>} La tarea de mantenimiento actualizada
     */
    static async requestSupport(maintenanceId, requestDetails, currentUser, metadata = {}) {
        try {
            if (!mongoose.Types.ObjectId.isValid(maintenanceId)) {
                throw new Error("ID de mantenimiento inválido");
            }

            // Buscar la tarea existente
            const maintenance = await Maintenance.findById(maintenanceId);
            if (!maintenance) {
                throw new Error(`Mantenimiento con ID ${maintenanceId} no encontrado`);
            }

            if (maintenance.supportRequested) {
                throw new Error("Ya se ha solicitado apoyo para esta tarea de mantenimiento");
            }

            // Guardar estado anterior para auditoría
            const previousState = maintenance.toObject();

            // Actualizar estado de solicitud de apoyo
            maintenance.supportRequested = true;
            maintenance.supportRequestDetails = requestDetails;
            maintenance.updatedBy = currentUser._id;

            await maintenance.save();

            // Obtener la tarea actualizada con relaciones
            const updatedMaintenance = await Maintenance.findById(maintenanceId)
                .populate('createdBy', 'username fullName')
                .populate('updatedBy', 'username fullName')
                .populate('project', 'name')
                .populate('point', 'name type');

            // Registrar auditoría
            await AuditTrail.create({
                entityId: maintenanceId,
                entityType: 'maintenance',
                action: 'update',
                changes: {
                    before: previousState,
                    after: updatedMaintenance.toObject()
                },
                performedBy: currentUser._id,
                ipAddress: metadata.ipAddress,
                userAgent: metadata.userAgent,
                notes: metadata.notes
            });

            return this.formatMaintenanceData(updatedMaintenance);
        } catch (error) {
            loggerx.error(`Error al solicitar apoyo para tarea de mantenimiento: ${error.message}`);
            throw error;
        }
    }

    /**
     * Registra la generación de un informe para una tarea de mantenimiento
     * @param {string} maintenanceId - ID de la tarea
     * @param {string} reportURL - URL del informe generado
     * @param {Object} currentUser - Usuario que realiza la operación
     * @param {Object} metadata - Metadatos adicionales para auditoría
     * @returns {Promise<Object>} La tarea de mantenimiento actualizada
     */
    static async registerReport(maintenanceId, reportURL, currentUser, metadata = {}) {
        try {
            if (!mongoose.Types.ObjectId.isValid(maintenanceId)) {
                throw new Error("ID de mantenimiento inválido");
            }

            // Buscar la tarea existente
            const maintenance = await Maintenance.findById(maintenanceId);
            if (!maintenance) {
                throw new Error(`Mantenimiento con ID ${maintenanceId} no encontrado`);
            }

            // Guardar estado anterior para auditoría
            const previousState = maintenance.toObject();

            // Actualizar información del informe
            maintenance.hasGeneratedReport = true;
            maintenance.reportURL = reportURL;
            maintenance.updatedBy = currentUser._id;

            await maintenance.save();

            // Obtener la tarea actualizada con relaciones
            const updatedMaintenance = await Maintenance.findById(maintenanceId)
                .populate('createdBy', 'username fullName')
                .populate('updatedBy', 'username fullName')
                .populate('project', 'name')
                .populate('point', 'name type');

            // Registrar auditoría
            await AuditTrail.create({
                entityId: maintenanceId,
                entityType: 'maintenance',
                action: 'update',
                changes: {
                    before: previousState,
                    after: updatedMaintenance.toObject()
                },
                performedBy: currentUser._id,
                ipAddress: metadata.ipAddress,
                userAgent: metadata.userAgent,
                notes: metadata.notes
            });

            return this.formatMaintenanceData(updatedMaintenance);
        } catch (error) {
            loggerx.error(`Error al registrar informe para tarea de mantenimiento: ${error.message}`);
            throw error;
        }
    }

    /**
     * Formatea los datos de una tarea de mantenimiento para su envío al cliente
     * @param {Object} maintenance - Tarea de mantenimiento a formatear
     * @returns {Object} Datos formateados
     */
    static formatMaintenanceData(maintenance) {
        if (!maintenance) return null;

        const formattedData = maintenance.toObject();

        // Formatear ID de MongoDB a string simple
        formattedData.id = formattedData._id.toString();
        delete formattedData._id;

        // Calcular propiedades virtuales
        formattedData.progress = maintenance.progress;
        formattedData.hasMinimumRequiredPhotos = maintenance.hasMinimumRequiredPhotos;

        // Formatear fechas para mayor legibilidad
        if (formattedData.scheduledDate) {
            formattedData.scheduledDateFormatted = new Date(formattedData.scheduledDate).toLocaleDateString('es-ES');
        }

        if (formattedData.completedDate) {
            formattedData.completedDateFormatted = new Date(formattedData.completedDate).toLocaleDateString('es-ES');
        }

        if (formattedData.serviceDate) {
            formattedData.serviceDateFormatted = new Date(formattedData.serviceDate).toLocaleDateString('es-ES');
        }

        // Formatear fechas de auditoría
        if (formattedData.createdAt) {
            formattedData.createdAtFormatted = new Date(formattedData.createdAt).toLocaleString('es-ES');
        }

        if (formattedData.updatedAt) {
            formattedData.updatedAtFormatted = new Date(formattedData.updatedAt).toLocaleString('es-ES');
        }

        // Contar fotos por categoría
        formattedData.initialPhotoCount = formattedData.initialPhotos ? formattedData.initialPhotos.length : 0;
        formattedData.finalPhotoCount = formattedData.finalPhotos ? formattedData.finalPhotos.length : 0;

        // Calcular el total de metros de cable instalado
        let totalCable = 0;
        if (formattedData.cableInstalled) {
            totalCable = (formattedData.cableInstalled.utp || 0) +
                (formattedData.cableInstalled.electrico || 0) +
                (formattedData.cableInstalled.fibra || 0);
        }
        formattedData.totalCableInstalled = totalCable;

        // Si hay referencias populadas, formatearlas
        if (formattedData.createdBy && typeof formattedData.createdBy === 'object') {
            formattedData.createdByName = formattedData.createdBy.fullName || formattedData.createdBy.username;
        }

        if (formattedData.updatedBy && typeof formattedData.updatedBy === 'object') {
            formattedData.updatedByName = formattedData.updatedBy.fullName || formattedData.updatedBy.username;
        }

        if (formattedData.project && typeof formattedData.project === 'object') {
            formattedData.projectName = formattedData.project.name;
            formattedData.project = formattedData.project._id.toString();
        }

        if (formattedData.point && typeof formattedData.point === 'object') {
            formattedData.pointName = formattedData.point.name;
            formattedData.pointType = formattedData.point.type;
            formattedData.point = formattedData.point._id.toString();
        }

        return formattedData;
    }
} 