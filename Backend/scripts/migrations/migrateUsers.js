import mongoose from 'mongoose';
import * as dotenv from 'dotenv';
import { loggerx } from '../../api/middleware/logger/logger.js';

// Cargar variables de entorno
dotenv.config({
    path: `.env/.env`
});

// Conectar a la base de datos
mongoose.connect(process.env.URI_MONGODB)
    .then(() => console.log('Conexión a MongoDB establecida para migración'))
    .catch(err => {
        console.error('Error al conectar a MongoDB:', err);
        process.exit(1);
    });

// Definir el esquema antiguo
const oldUserSchema = new mongoose.Schema({
    username: String,
    name: String,
    password: String,
    rol: String,
    statusDB: String,
    created_by: mongoose.Schema.Types.ObjectId,
    modified_by: mongoose.Schema.Types.ObjectId
}, {
    strict: false,
    collection: 'users'
});

// Definir el esquema nuevo
const newUserSchema = new mongoose.Schema({
    username: String,
    fullName: String,
    password: String,
    role: String,
    status: String,
    createdBy: mongoose.Schema.Types.ObjectId,
    updatedBy: mongoose.Schema.Types.ObjectId,
    createdAt: Date,
    updatedAt: Date
}, {
    strict: false,
    collection: 'users_new'
});

// Crear modelos
const OldUser = mongoose.model('OldUser', oldUserSchema);
const NewUser = mongoose.model('NewUser', newUserSchema);

// Función principal de migración
async function migrateUsers() {
    try {
        console.log('Iniciando migración de usuarios...');

        // Obtener todos los usuarios antiguos
        const oldUsers = await OldUser.find({}).lean();
        console.log(`Se encontraron ${oldUsers.length} usuarios para migrar`);

        // Crear colección temporal si no existe
        try {
            await mongoose.connection.db.createCollection('users_new');
            console.log('Colección temporal creada');
        } catch (error) {
            console.log('La colección temporal ya existe, continuando...');
        }

        // Migrar cada usuario
        for (const oldUser of oldUsers) {
            const newUser = {
                _id: oldUser._id,
                username: oldUser.username ? oldUser.username.toLowerCase() : 'usuario_' + Date.now(),
                fullName: oldUser.name || oldUser.fullName || 'Usuario sin nombre',
                password: oldUser.password,
                role: oldUser.rol || oldUser.role || 'technician',
                status: oldUser.statusDB === 'deleted' ? 'deleted' : (oldUser.statusDB || 'active'),
                createdBy: oldUser.created_by || oldUser.createdBy || mongoose.Types.ObjectId('000000000000000000000000'),
                updatedBy: oldUser.modified_by || oldUser.updatedBy || oldUser.created_by || oldUser.createdBy,
                createdAt: oldUser.createdAt || new Date(),
                updatedAt: oldUser.updatedAt || new Date()
            };

            // Guardar el nuevo usuario
            await NewUser.findOneAndUpdate(
                { _id: newUser._id },
                newUser,
                { upsert: true, new: true }
            );

            console.log(`Usuario migrado: ${newUser.username}`);
        }

        console.log('Migración completada con éxito');
        console.log('');
        console.log('IMPORTANTE: Para completar la migración, ejecute los siguientes comandos en MongoDB:');
        console.log('1. db.users.renameCollection("users_old")');
        console.log('2. db.users_new.renameCollection("users")');
        console.log('3. db.users_old.drop() // Solo después de verificar que todo está correcto');

    } catch (error) {
        console.error('Error durante la migración:', error);
    } finally {
        // Cerrar conexión
        await mongoose.connection.close();
        console.log('Conexión a MongoDB cerrada');
    }
}

// Ejecutar migración
migrateUsers(); 