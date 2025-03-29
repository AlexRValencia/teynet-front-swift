import winston from "winston";
import chalk from "chalk";

// Formato personalizado para la consola con colores y estructura mejorada
const consoleFormat = winston.format.printf(({ level, message, timestamp, requestId, type, method, url, statusCode, responseTime, action, user, changes, error }) => {
    // Determinar color según el nivel del log
    let logColor = chalk.white;
    if (level.includes('info')) logColor = chalk.blue;
    if (level.includes('warn')) logColor = chalk.yellow;
    if (level.includes('error')) logColor = chalk.red;

    // Formatear fecha/hora de forma más legible
    const formattedTime = new Date(timestamp).toLocaleTimeString();

    // Formatear según el tipo de mensaje
    if (type === 'REQUEST') {
        return `${chalk.gray(formattedTime)} ${logColor(`[${level.toUpperCase()}]`)} ${chalk.green(`${method}`)} ${chalk.cyan(`${url}`)} ${requestId ? chalk.gray(`(ID: ${requestId})`) : ''}`;
    }
    else if (type === 'RESPONSE') {
        const statusColor = statusCode < 400 ? chalk.green : chalk.red;
        return `${chalk.gray(formattedTime)} ${logColor(`[${level.toUpperCase()}]`)} ${chalk.green(`${method}`)} ${chalk.cyan(`${url}`)} ${statusColor(`${statusCode}`)} ${chalk.yellow(`${responseTime}`)} ${requestId ? chalk.gray(`(ID: ${requestId})`) : ''}`;
    }
    else if (action) {
        return `${chalk.gray(formattedTime)} ${logColor(`[${level.toUpperCase()}]`)} ${chalk.magenta(`[${action}]`)} ${user ? `Usuario: ${user}` : ''} ${changes ? `Cambios: ${JSON.stringify(changes, null, 2)}` : ''}`;
    }
    else if (error) {
        return `${chalk.gray(formattedTime)} ${logColor(`[${level.toUpperCase()}]`)} ${chalk.red(error.message)} \n${chalk.gray(error.stack)}`;
    }
    else if (typeof message === 'object') {
        return `${chalk.gray(formattedTime)} ${logColor(`[${level.toUpperCase()}]`)} ${JSON.stringify(message, null, 2)}`;
    }
    else {
        return `${chalk.gray(formattedTime)} ${logColor(`[${level.toUpperCase()}]`)} ${message}`;
    }
});

export const loggerx = winston.createLogger({
    level: process.env.LOG_LEVEL || 'http',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({
            filename: 'logs/logs.log',
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.json()
            )
        }),
        // Añadir logging a la consola en desarrollo con formato mejorado
        ...(process.env.NODE_ENV !== 'production' ? [
            new winston.transports.Console({
                format: winston.format.combine(
                    winston.format.timestamp(),
                    consoleFormat
                )
            })
        ] : [])
    ],
    exceptionHandlers: [
        new winston.transports.File({ filename: 'logs/exceptions.log' })
    ]
});

// Middleware mejorado para logging de peticiones
export const logReq = (req, res, next) => {
    const start = Date.now();
    const requestId = Math.random().toString(36).substring(2, 15);

    // Registrar información de la petición entrante
    loggerx.info({
        requestId,
        type: 'REQUEST',
        method: req.method,
        url: req.originalUrl || req.url,
        ip: req.ip,
        userAgent: req.get('user-agent'),
        body: sanitizeBody(req.body),
        query: req.query,
        params: req.params
    });

    // Capturar la respuesta
    const originalSend = res.send;
    res.send = function (body) {
        const responseTime = Date.now() - start;

        // Registrar información de la respuesta
        loggerx.info({
            requestId,
            type: 'RESPONSE',
            method: req.method,
            url: req.originalUrl || req.url,
            statusCode: res.statusCode,
            responseTime: `${responseTime}ms`,
            contentLength: body ? body.length : 0
        });

        return originalSend.call(this, body);
    };

    next();
};

// Función para sanitizar datos sensibles en el body
function sanitizeBody(body) {
    if (!body) return {};

    const sanitized = { ...body };

    // Ocultar campos sensibles
    const sensitiveFields = ['password', 'token', 'secret', 'apiKey', 'credit_card'];
    sensitiveFields.forEach(field => {
        if (sanitized[field]) {
            sanitized[field] = '********';
        }
    });

    return sanitized;
}

export default logReq;