import { Schema, Types, model } from "mongoose";
import bcrypt from "bcrypt";
import { loggerx } from "../middleware/logger/logger.js";

const userSchema = new Schema({
  // Información básica
  username: {
    type: String,
    required: true,
    trim: true,
    unique: true,
    lowercase: true,
    index: true
  },
  fullName: {
    type: String,
    required: true,
    trim: true
  },

  // Autenticación y seguridad
  password: {
    type: String,
    required: [true, "La contraseña es obligatoria"],
    minlength: [8, "La contraseña debe tener al menos 8 caracteres"],
    validate: {
      validator: function (value) {
        // Al menos 8 caracteres, una letra y un número
        return /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$/.test(value);
      },
      message: "La contraseña debe contener al menos una letra y un número"
    },
    select: false // No incluir por defecto en consultas
  },

  // Control de acceso
  role: {
    type: String,
    required: true,
    enum: ["admin", "technician", "supervisor", "viewer"],
    default: "technician",
    index: true
  },

  // Estado
  status: {
    type: String,
    enum: ["active", "inactive", "deleted"],
    default: "active",
    index: true
  },

  // Datos de sesión
  lastLogin: Date,

  // Datos de auditoría
  createdBy: {
    type: Types.ObjectId,
    ref: "User",
    required: true,
    index: true
  },
  updatedBy: {
    type: Types.ObjectId,
    ref: "User",
    index: true
  }
}, {
  timestamps: true, // Crea automáticamente createdAt y updatedAt
  strict: true      // No permite campos no definidos
});

// Índices compuestos para consultas frecuentes
userSchema.index({ status: 1, role: 1 });
userSchema.index({ createdAt: -1 });

// Virtuals para compatibilidad con código existente
userSchema.virtual('name').get(function () {
  return this.fullName;
});

userSchema.virtual('rol').get(function () {
  return this.role;
});

userSchema.virtual('statusDB').get(function () {
  return this.status;
});

userSchema.virtual('created_by').get(function () {
  return this.createdBy;
});

userSchema.virtual('modified_by').get(function () {
  return this.updatedBy;
});

// Configurar para que los virtuals se incluyan en toJSON y toObject
userSchema.set('toJSON', {
  virtuals: true,
  transform: function (doc, ret) {
    delete ret.password;
    return ret;
  }
});

userSchema.set('toObject', {
  virtuals: true,
  transform: function (doc, ret) {
    delete ret.password;
    return ret;
  }
});

// Hook para encriptar contraseña
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();

  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    loggerx.error(`Error al encriptar contraseña: ${error.message}`);
    throw new Error("Fallo el hash del password");
  }
});

// Método para verificar contraseña
userSchema.methods.comparePassword = async function (candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    loggerx.error(`Error al comparar contraseñas: ${error.message}`);
    throw new Error("Error al verificar credenciales");
  }
};

export const User = model("User", userSchema);