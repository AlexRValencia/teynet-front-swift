import './dbConnection.js';
import Maintenance from './api/models/Maintenance.js';
import { User } from './api/models/User.js';
import mongoose from 'mongoose';

const createTestData = async () => {
    try {
        console.log('Iniciando creación de datos de prueba...');

        // Buscar un usuario para asignar como creador
        let user = await User.findOne({ role: 'admin' });

        if (!user) {
            // Si no hay un usuario admin, crear uno temporal
            console.log('No se encontró un usuario admin, creando uno temporal...');
            const userId = new mongoose.Types.ObjectId();
            user = { _id: userId };
        }

        // Crear un mantenimiento de prueba
        const testMaintenance = {
            siteName: 'A1-CCTV',
            location: 'ACUÑA',
            serviceDate: new Date(),
            serviceType: 'Preventivo',
            deviceName: 'Cámara IP exterior',
            taskType: 'Revisión',
            maintenanceType: 'Preventivo',
            observations: 'REVISION ELECTRICA DE EQUIPOS, SOPLETEADO DE GABINETES Y REVISION DE CONEXIONES, LIMPIEZA DE CAMARAS Y EQUIPOS, AJUSTES NECESARIOS DE CAMARAS Y AJUSTE DE TORNILLERIA.',
            description: 'Mantenimiento de prueba',
            status: 'Pendiente',
            scheduledDate: new Date(),
            assignedTo: 'Técnico de Prueba',
            priority: 'Media',
            initialPhotos: [],
            finalPhotos: [],
            pointCoordinates: [27.5248, -100.5153], // Coordenadas para Acuña
            cableInstalled: {
                utp: 20,
                electrico: 15,
                fibra: 0
            },
            createdBy: user._id
        };

        // Insertar en la base de datos
        const result = await Maintenance.create(testMaintenance);
        console.log('Mantenimiento de prueba creado con ID:', result._id);

        // Crear un segundo mantenimiento con estado Finalizado
        const testMaintenance2 = {
            ...testMaintenance,
            siteName: 'T1-SISTEMA',
            location: 'TORREÓN',
            deviceName: 'DVR 16 canales',
            status: 'Finalizado',
            completedDate: new Date(),
            pointCoordinates: [25.5428, -103.4068], // Coordenadas para Torreón
            observations: 'Mantenimiento completo de DVR, limpieza de polvo y revisión de configuración',
            createdBy: user._id
        };

        const result2 = await Maintenance.create(testMaintenance2);
        console.log('Segundo mantenimiento de prueba creado con ID:', result2._id);

        console.log('Datos de prueba creados exitosamente!');
    } catch (error) {
        console.error('Error al crear datos de prueba:', error);
    } finally {
        // Cerrar la conexión después de terminar
        mongoose.connection.close();
    }
};

createTestData(); 