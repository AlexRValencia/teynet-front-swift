import { Schema, Types, model } from "mongoose";

const auditTrailSchema = new Schema({
    // Entidad afectada
    entityType: {
        type: String,
        required: true,
        enum: ["user", "inventory", "maintenance", "project", "client"],
        index: true
    },
    entityId: {
        type: Schema.Types.ObjectId,
        required: true,
        index: true
    },

    // Tipo de acción
    action: {
        type: String,
        required: true,
        enum: ["create", "update", "delete", "status_change", "password_change"],
        index: true
    },

    // Cambios realizados
    changes: {
        type: Object,
        required: true
    },

    // Datos anteriores (para poder revertir cambios si es necesario)
    previousData: {
        type: Object
    },

    // Quién realizó el cambio
    performedBy: {
        type: Schema.Types.ObjectId,
        ref: "User",
        required: true,
        index: true
    },

    // Metadatos adicionales
    ipAddress: String,
    userAgent: String,

    // Notas o comentarios sobre el cambio
    notes: String
}, {
    timestamps: true,
    toJSON: {
        transform: function (doc, ret) {
            ret.id = ret._id.toString();
            delete ret._id;
        }
    }
});

// Índices para consultas frecuentes
auditTrailSchema.index({ entityType: 1, entityId: 1, createdAt: -1 });
auditTrailSchema.index({ performedBy: 1, createdAt: -1 });

export const AuditTrail = model("AuditTrail", auditTrailSchema); 