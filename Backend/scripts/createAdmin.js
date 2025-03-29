import mongoose from 'mongoose';
import { User } from '../api/models/User.js';
import * as dotenv from 'dotenv';

dotenv.config({
    path: '.env/.env'
});

const createAdminUser = async () => {
    try {
        await mongoose.connect(process.env.URI_MONGODB);
        console.log('Conectado a MongoDB');

        const adminUser = {
            username: 'admin',
            fullName: 'Administrador',
            password: 'Admin123!',
            role: 'admin',
            status: 'active'
        };

        const existingUser = await User.findOne({ username: adminUser.username });
        if (existingUser) {
            console.log('El usuario administrador ya existe');
            process.exit(0);
        }

        const user = new User(adminUser);
        await user.save();
        console.log('Usuario administrador creado exitosamente');
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

createAdminUser(); 