import mongoose from 'mongoose';

const clientSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'El nombre del cliente es obligatorio'],
        trim: true
    },
    legalName: {
        type: String,
        trim: true,
        default: ''
    },
    rfc: {
        type: String,
        trim: true,
        sparse: true,
        default: null
    },
    contactPerson: {
        type: String,
        trim: true,
        default: ''
    },
    email: {
        type: String,
        trim: true,
        default: '',
        match: [/^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/, 'Proporcione un correo electrónico válido']
    },
    phone: {
        type: String,
        trim: true,
        default: ''
    },
    address: {
        type: String,
        trim: true,
        default: ''
    },
    notes: {
        type: String,
        trim: true,
        default: ''
    },
    active: {
        type: Boolean,
        default: true
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    updatedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }
}, {
    timestamps: true,
    versionKey: false,
    toJSON: {
        transform: function (doc, ret) {
            ret.id = ret._id.toString();
            delete ret._id;
        }
    }
});

// Crear índice único en rfc solo si no es nulo
clientSchema.index({ rfc: 1 }, { unique: true, sparse: true });

const Client = mongoose.model('Client', clientSchema);

export default Client; 