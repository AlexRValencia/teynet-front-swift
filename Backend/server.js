// Dependencias
import express from "express";
import helmet from "helmet";
import cors from "cors";
import bodyParser from "body-parser";
import cookieParser from "cookie-parser";
import methodOverride from "method-override";
import morgan from "morgan";

// Rutas
import User from "./api/routes/user/user.js";
import Authn from "./api/routes/authn/authn.js";
import Client from "./api/routes/client/index.js";
import Project from "./api/routes/projectRoutes.js";
import Points from "./api/routes/points/points.js";
import Materials from "./api/routes/materials/materials.js";
import Maintenance from "./api/routes/maintenance/index.js";

// Configuracion
import "./dbConnection.js";
import { loggerx, logReq } from "./api/middleware/logger/logger.js";

const app = express();

app.enable('trust proxy');

app.use(methodOverride("_method"));

// Implementar middleware de seguridad
app.use(helmet());

const allowedOrigins = [
    "http://example.com",
    "http://localhost:3000",
    "http://192.168.1.69:3000",
    "*",
];

// Implementar middleware de CORS con función personalizada
// Allow cors
app.use(
    cors({
        origin: function (origin, callback) {
            if (!origin || allowedOrigins.includes(origin)) {
                return callback(null, origin);
            }
            return callback("Error de CORS origin:" + origin + " no autorizado");
        },
        credentials: true,
    })
);

// Parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: true }));

// Parse application/json
app.use(bodyParser.json());

// Parse cookies
app.use(cookieParser());

// Aplicar middleware de logging para todas las peticiones
app.use(logReq);

app.use(morgan(
    ':remote-addr - :remote-user ":method :url HTTP/:http-version" :status :res[content-length] ":user-agent"',
    {
        stream: {
            // Configure Morgan to use our custom logger with the http severity
            write: (message) => loggerx.http(message.trim()),
        },
    }))

//app.use(logReq)
app.use("/api/v1/authn", Authn);

// Ruta de status original para verificar disponibilidad
app.get("/api/v1/status", (req, res) => {
    res.status(200).json({
        status: "ok",
        message: "El servidor está funcionando correctamente",
        timestamp: new Date().toISOString(),
        service: "trynet API Backend",
    });
});

// Ruta de status compatible con el cliente iOS
app.get("/status", (req, res) => {
    // También respondemos a solicitudes HEAD para optimización
    if (req.method === 'HEAD') {
        return res.status(200).end();
    }

    res.status(200).json({
        status: "ok",
        version: "1.0.0",
    });
});

app.use("/api/v1/users", User);
app.use("/api/v1/clients", Client);
app.use("/api/v1/projects", Project);
app.use("/api/v1/points", Points);
app.use("/api/v1/materials", Materials);
app.use("/api/v1/maintenance", Maintenance);

// Middleware para manejar rutas no encontradas
app.use((req, res, next) => {
    loggerx.warn({
        type: 'NOT_FOUND',
        method: req.method,
        url: req.originalUrl || req.url,
        ip: req.ip
    });

    res.status(404).json({
        status: "error",
        message: "Ruta no encontrada",
        path: req.originalUrl
    });
});

// Middleware para capturar y registrar errores
app.use((err, req, res, next) => {
    const statusCode = err.statusCode || 500;

    loggerx.error({
        type: 'ERROR',
        method: req.method,
        url: req.originalUrl || req.url,
        statusCode: statusCode,
        error: {
            message: err.message,
            stack: process.env.NODE_ENV === 'production' ? '🥞' : err.stack
        }
    });

    res.status(statusCode).json({
        status: "error",
        message: err.message || "Error interno del servidor",
        ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
    });
});

console.log('NODE_ENV:', process.env.NODE_ENV || 'no definido');
// Si NODE_ENV no está definido, configurarlo como development
if (!process.env.NODE_ENV) {
    process.env.NODE_ENV = 'development';
    console.log('NODE_ENV configurado automáticamente como "development"');
}

const port = process.env.PORT || 42067;
app.listen(port, () => {
    console.log(`Server listening on http://localhost:${port}`);
    console.log('NODE_ENV:', process.env.NODE_ENV);
});