const fs = require('fs');

// Leer el archivo data.json
const rawData = fs.readFileSync('data.json', 'utf8');
const points = JSON.parse(rawData);

// Valores por defecto para campos requeridos
const createdBy = "64881a2a1a5262f1a5ff254c"; // ID de usuario fijo para todos
const currentDate = new Date().toISOString();
const correctProjectId = "67ee57065d5604276fba5dec"; // ID correcto del proyecto

// Validar tipos de puntos según el esquema
const validTypes = ["LPR", "CCTV", "ALARMA", "RADIO_BASE", "RELAY"];
const typeMapping = {
    "ALARM": "ALARMA",
    "CCTV": "CCTV",
    "LPR": "LPR",
    "RADIO_BASE": "RADIO_BASE",
    "RELAY": "RELAY"
};

// Convertir cada punto al formato de MongoDB
const formattedPoints = points.map((point, index) => {
    // Validar que el objeto tenga las propiedades requeridas
    if (!point.name) {
        console.warn(`Advertencia: El punto ${index + 1} no tiene nombre. Asignando "Punto ${index + 1}"`);
        point.name = `Punto ${index + 1}`;
    }

    // Validar el tipo
    let pointType = typeMapping[point.type] || "CCTV"; // Valor por defecto
    if (!validTypes.includes(pointType)) {
        console.warn(`Advertencia: El punto ${point.name} tiene un tipo no válido (${point.type}). Cambiando a CCTV`);
        pointType = "CCTV";
    }

    // Convertir coordenadas a números
    const coordinates = [];
    if (point.location && Array.isArray(point.location.coordinates)) {
        // Asegurarse de que hay exactamente 2 coordenadas
        coordinates[0] = parseFloat(point.location.coordinates[0] || "0") || 0;
        coordinates[1] = parseFloat(point.location.coordinates[1] || "0") || 0;
    } else {
        console.warn(`Advertencia: El punto ${point.name} no tiene coordenadas válidas. Asignando [0, 0]`);
        coordinates[0] = 0;
        coordinates[1] = 0;
    }

    // Validar ciudad
    const city = point.city || "Ciudad no especificada";

    // Validar proyecto
    if (!point.project) {
        console.error(`Error: El punto ${point.name} no tiene un proyecto asignado.`);
        return null;
    }

    return {
        name: point.name,
        type: pointType,
        location: {
            type: "Point",
            coordinates: coordinates
        },
        city: city,
        material: [],
        operational: true,
        project: {
            $oid: correctProjectId
        },
        createdBy: {
            $oid: createdBy
        },
        createdAt: {
            $date: currentDate
        },
        updatedAt: {
            $date: currentDate
        },
        __v: 0
    };
}).filter(Boolean); // Filtrar los puntos nulos

// Guardar el resultado en un nuevo archivo
fs.writeFileSync('puntos_mongodb.json', JSON.stringify(formattedPoints, null, 2));
console.log(`Se ha convertido correctamente ${formattedPoints.length} puntos y guardado en puntos_mongodb.json`); 