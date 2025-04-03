import mongoose from 'mongoose';

const pointSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'El nombre del punto es obligatorio'],
        trim: true
    },
    type: {
        type: String,
        enum: ['LPR', 'CCTV', 'ALARMA', 'RADIO_BASE', 'RELAY'],
        required: [true, 'El tipo de punto es obligatorio']
    },
    location: {
        type: {
            type: String,
            enum: ['Point'],
            required: true
        },
        coordinates: {
            type: [Number],
            required: true
        }
    },
    city: {
        type: String,
        required: [true, 'La ciudad es obligatoria'],
        trim: true
    },
    material: {
        type: mongoose.Schema.Types.Mixed,
        required: false,
        default: []
    },
    operational: {
        type: Boolean,
        default: true
    },
    project: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Project',
        required: [true, 'El proyecto es obligatorio']
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    }
}, {
    timestamps: true
});

// Índices para mejorar el rendimiento de las consultas
pointSchema.index({ project: 1 });
pointSchema.index({ type: 1 });
pointSchema.index({ city: 1 });
// Índice geoespacial para búsquedas por ubicación
pointSchema.index({ location: '2dsphere' });

const Point = mongoose.model('Point', pointSchema);

export default Point; 