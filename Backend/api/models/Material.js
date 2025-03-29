import mongoose from 'mongoose';

const materialSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'El nombre del material es obligatorio'],
        trim: true
    },
    quantity: {
        type: Number,
        required: [true, 'La cantidad es obligatoria'],
        min: 0
    },
    description: {
        type: String,
        trim: true,
        default: ''
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
materialSchema.index({ project: 1 });
materialSchema.index({ name: 1 });

const Material = mongoose.model('Material', materialSchema);

export default Material; 