import mongoose from 'mongoose';

// Schema para fotos de mantenimiento
const maintenancePhotoSchema = new mongoose.Schema({
    imageName: {
        type: String,
        required: true
    },
    imageData: {
        type: String, // Base64 de la imagen o URL
        required: false
    },
    caption: {
        type: String,
        default: ''
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
}, { _id: true });

// Schema para cables instalados
const cableInstalledSchema = new mongoose.Schema({
    utp: {
        type: Number,
        default: 0,
        min: 0
    },
    electrico: {
        type: Number,
        default: 0,
        min: 0
    },
    fibra: {
        type: Number,
        default: 0,
        min: 0
    }
}, { _id: false });

// Schema para etapas de mantenimiento
const maintenanceStageSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    description: {
        type: String,
        default: ''
    },
    percentageValue: {
        type: Number,
        required: true,
        min: 0,
        max: 1
    },
    isCompleted: {
        type: Boolean,
        default: false
    },
    photos: [maintenancePhotoSchema]
}, { _id: true });

// Schema principal para tareas de mantenimiento
const maintenanceSchema = new mongoose.Schema({
    // Datos de cabecera (Basados en la imagen del formato)
    siteName: {
        type: String,
        required: [true, 'El nombre del sitio es obligatorio'],
        trim: true
    },
    location: {
        type: String,
        required: [true, 'La ciudad/localidad es obligatoria'],
        trim: true
    },
    serviceDate: {
        type: Date,
        required: [true, 'La fecha de servicio es obligatoria'],
        default: Date.now
    },
    serviceType: {
        type: String,
        required: [true, 'El tipo de servicio es obligatorio'],
        enum: ['Correctivo', 'Preventivo', 'Instalación', 'Actualización', 'Revisión'],
        default: 'Preventivo'
    },

    // Campos originales adaptados
    deviceName: {
        type: String,
        required: [true, 'El nombre del dispositivo es obligatorio'],
        trim: true
    },
    taskType: {
        type: String,
        required: [true, 'El tipo de tarea es obligatorio'],
        enum: ['Revisión', 'Actualización', 'Limpieza', 'Reparación', 'Instalación'],
        default: 'Revisión'
    },
    maintenanceType: {
        type: String,
        required: [true, 'El tipo de mantenimiento es obligatorio'],
        enum: ['Preventivo', 'Correctivo'],
        default: 'Preventivo'
    },

    // Campos específicos del formato de la imagen
    observations: {
        type: String,
        required: [true, 'Las observaciones son obligatorias'],
        trim: true
    },
    damagedEquipment: {
        type: [String],
        default: []
    },
    cableInstalled: {
        type: cableInstalledSchema,
        default: () => ({})
    },

    // Campos adicionales y estado
    description: {
        type: String,
        trim: true
    },
    status: {
        type: String,
        required: [true, 'El estado es obligatorio'],
        enum: ['Pendiente', 'En desarrollo', 'Finalizado', 'Cancelado'],
        default: 'Pendiente'
    },
    scheduledDate: {
        type: Date,
        required: [true, 'La fecha programada es obligatoria']
    },
    completedDate: {
        type: Date
    },
    assignedTo: {
        type: String,
        required: [true, 'El responsable es obligatorio'],
        trim: true
    },
    priority: {
        type: String,
        required: [true, 'La prioridad es obligatoria'],
        enum: ['Alta', 'Media', 'Baja'],
        default: 'Media'
    },

    // Campos para fotos iniciales y finales (según formato)
    initialPhotos: [maintenancePhotoSchema],
    finalPhotos: [maintenancePhotoSchema],

    // Relaciones con otros modelos
    project: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Project'
    },
    projectName: {
        type: String
    },
    point: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Point'
    },
    pointType: {
        type: String
    },
    pointCoordinates: {
        type: [Number],
        validate: {
            validator: function (v) {
                return v.length === 2;
            },
            message: props => `${props.value} debe ser un array con dos valores (latitud, longitud)`
        }
    },

    // Etapas del mantenimiento
    stages: {
        type: [maintenanceStageSchema],
        default: [
            {
                name: "Llegada",
                description: "Foto para validar que se llegó al sitio",
                percentageValue: 0.10,
                isCompleted: false
            },
            {
                name: "Diagnóstico",
                description: "Identificar el problema y solicitar apoyo de ser necesario",
                percentageValue: 0.10,
                isCompleted: false
            },
            {
                name: "Materiales",
                description: "Verificar si se cuenta con los materiales o si hay que esperar a reunirlos",
                percentageValue: 0.50,
                isCompleted: false
            },
            {
                name: "Conclusión",
                description: "Foto de conclusión del servicio",
                percentageValue: 0.30,
                isCompleted: false
            }
        ]
    },

    // Información de soporte
    supportRequested: {
        type: Boolean,
        default: false
    },
    supportRequestDetails: {
        type: String
    },

    // Informes generados
    hasGeneratedReport: {
        type: Boolean,
        default: false
    },
    reportURL: {
        type: String
    },

    // Campos para auditoría
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    updatedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }
}, {
    timestamps: true,
    versionKey: false
});

// Índices para mejorar el rendimiento de las consultas
maintenanceSchema.index({ status: 1 });
maintenanceSchema.index({ scheduledDate: 1 });
maintenanceSchema.index({ priority: 1 });
maintenanceSchema.index({ location: 1 });
maintenanceSchema.index({ assignedTo: 1 });
maintenanceSchema.index({ project: 1 });
maintenanceSchema.index({ point: 1 });
maintenanceSchema.index({ siteName: 1 });
maintenanceSchema.index({ serviceDate: 1 });

// Método virtual para calcular el progreso general
maintenanceSchema.virtual('progress').get(function () {
    if (!this.stages || this.stages.length === 0) return 0;

    let completedPercentage = 0;
    for (const stage of this.stages) {
        if (stage.isCompleted) {
            completedPercentage += stage.percentageValue;
        }
    }

    return completedPercentage;
});

// Método virtual para verificar si cumple con el requisito mínimo de fotos
maintenanceSchema.virtual('hasMinimumRequiredPhotos').get(function () {
    let initialCount = this.initialPhotos ? this.initialPhotos.length : 0;
    let finalCount = this.finalPhotos ? this.finalPhotos.length : 0;

    // También contar fotos en las etapas
    let stagePhotoCount = 0;
    if (this.stages && this.stages.length > 0) {
        for (const stage of this.stages) {
            stagePhotoCount += stage.photos.length;
        }
    }

    // Requerimiento mínimo: al menos 3 fotos iniciales y 3 finales
    return (initialCount + finalCount + stagePhotoCount) >= 6;
});

const Maintenance = mongoose.model('Maintenance', maintenanceSchema);

export default Maintenance; 