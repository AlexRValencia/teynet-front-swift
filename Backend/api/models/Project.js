import mongoose from 'mongoose';

const projectSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'El nombre del proyecto es obligatorio'],
        trim: true
    },
    client: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Client',
        required: [true, 'El cliente es obligatorio']
    },
    status: {
        type: String,
        enum: ['Diseño', 'En desarrollo', 'Finalizado', 'Suspendido'],
        default: 'Diseño',
        required: true
    },
    health: {
        type: Number,
        min: 0,
        max: 1,
        default: 1.0
    },
    description: {
        type: String,
        trim: true,
        default: ''
    },
    startDate: {
        type: Date,
        required: [true, 'La fecha de inicio es obligatoria']
    },
    endDate: {
        type: Date
    },
    team: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    points: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Point'
    }],
    materials: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Material'
    }],
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
projectSchema.index({ client: 1 });
projectSchema.index({ status: 1 });
projectSchema.index({ 'team': 1 });

const Project = mongoose.model('Project', projectSchema);

export default Project; 