import mongoose from 'mongoose';
import { User } from './api/models/User.js';
import { loggerx } from './api/middleware/logger/logger.js';
import bcrypt from 'bcrypt';

// Conectar a MongoDB
mongoose.connect('mongodb://localhost:27017/trynet')
    .then(() => console.log('Conexión exitosa a MongoDB'))
    .catch(err => {
        console.error('Error de conexión a MongoDB:', err);
        process.exit(1);
    });

async function listUsers() {
    try {
        const users = await User.find({});
        console.log('Usuarios existentes:');
        users.forEach(user => {
            console.log(`- ID: ${user._id}`);
            console.log(`  Username: ${user.username}`);
            console.log(`  Nombre: ${user.fullName}`);
            console.log(`  Rol: ${user.role}`);
            console.log(`  Estado: ${user.status}`);
            console.log('-------------------');
        });

        if (users.length === 0) {
            console.log('No hay usuarios en la base de datos.');
        }
    } catch (err) {
        console.error('Error al listar usuarios:', err);
    } finally {
        mongoose.connection.close();
    }
}

async function updateAdminWithMongoDB() {
    try {
        // Obtener conexión nativa de MongoDB
        const db = mongoose.connection.db;
        const usersCollection = db.collection('users');

        // Buscar usuario admin
        const admin = await usersCollection.findOne({ username: 'admin' });

        if (!admin) {
            console.log('No se encontró el usuario admin.');
            return;
        }

        // Crear un hash de la nueva contraseña
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('Admin123x', salt);

        // Actualizar directamente en MongoDB
        const result = await usersCollection.updateOne(
            { _id: admin._id },
            { $set: { password: hashedPassword } }
        );

        if (result.modifiedCount === 1) {
            console.log('Contraseña actualizada exitosamente');
            console.log('Username: admin');
            console.log('Nueva contraseña: Admin123x');
        } else {
            console.log('No se pudo actualizar la contraseña');
        }
    } catch (err) {
        console.error('Error al actualizar la contraseña:', err);
    } finally {
        mongoose.connection.close();
    }
}

async function createNewAdmin() {
    try {
        // Crear un usuario administrador completamente nuevo
        const adminData = {
            username: 'superadmin',
            fullName: 'Super Administrador',
            password: 'Admin123x', // Debe contener al menos una letra y un número
            role: 'admin',
            status: 'active',
            createdBy: new mongoose.Types.ObjectId() // ID temporal para el primer usuario
        };

        // Crear el usuario
        const admin = new User(adminData);
        await admin.save();

        // Actualizar el createdBy para que sea él mismo
        admin.createdBy = admin._id;
        await admin.save();

        console.log('Usuario administrador creado exitosamente');
        console.log('Username:', adminData.username);
        console.log('Password:', adminData.password);
    } catch (err) {
        console.error('Error al crear nuevo administrador:', err);
    } finally {
        mongoose.connection.close();
    }
}

// Ejecutar la función
// listUsers();
// updateAdminWithMongoDB();
updateAdminWithMongoDB(); 