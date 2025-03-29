import Foundation
import Combine

// Enum para definir los diferentes entornos de la API
enum APIEnvironment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            // Opciones para conexión local
            // Prueba con estas alternativas si tienes problemas de conexión
            let url = "http://192.168.100.70:42067/api/v1"  // Opción 1: IP específica IPv4
            // let url = "http://localhost:42067/api/v1"    // Opción 2: localhost (original)
            // let url = "http://0.0.0.0:42067/api/v1"      // Opción 3: Todas las interfaces
            // let url = "http://[::1]:42067/api/v1"        // Opción 4: IPv6 localhost
            print("📡 Usando URL de desarrollo: \(url)")
            return url
        case .staging:
            return "https://staging-api.trynet.org/api/v1"
        case .production:
            return "https://api.trynet.org/api/v1"
        }
    }
    
    var timeoutInterval: TimeInterval {
        switch self {
        case .development:
            return 30.0  // Timeout más largo para desarrollo local
        case .staging, .production:
            return 15.0
        }
    }
}

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error, Data?)
    case serverError(statusCode: Int, message: String)
    case unauthorized
    case unknown
    
    var message: String {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .decodingError(let error, let data):
            var message = "Error al procesar la respuesta: \(error.localizedDescription)"
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                message += "\nRespuesta recibida: \(responseString)"
            }
            return message
        case .serverError(let statusCode, let message):
            return "Error del servidor (\(statusCode)): \(message)"
        case .unauthorized:
            return "Credenciales inválidas o sesión expirada"
        case .unknown:
            return "Error desconocido"
        }
    }
    
    var detailedDescription: String? {
        switch self {
        case .networkError(let error):
            return "Error de conexión: \(error.localizedDescription)\nVerifique su conexión a internet y que el servidor esté disponible."
        case .decodingError(let error, let data):
            var detail = "Error de decodificación: \(error)\n"
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                detail += "Datos recibidos: \(responseString)"
            }
            return detail
        case .serverError(let statusCode, let message):
            return "Código de estado HTTP: \(statusCode)\nMensaje del servidor: \(message)"
        case .unauthorized:
            return "El servidor rechazó las credenciales proporcionadas. Verifique su nombre de usuario y contraseña."
        default:
            return nil
        }
    }
    
    var isConnectionError: Bool {
        switch self {
        case .networkError:
            return true
        default:
            return false
        }
    }
}

class APIClient {
    static let shared = APIClient()
    
    // Configura el entorno actual aquí
    #if DEBUG
    private let environment: APIEnvironment = .development
    #else
    private let environment: APIEnvironment = .production
    #endif
    
    // Hacemos que baseURL sea accesible para pruebas de conexión rápidas
    var baseURL: String {
        return environment.baseURL
    }
    
    private init() {
        print("📡 APIClient configurado para entorno: \(environment), usando URL: \(baseURL)")
        
        // Optimizamos la configuración de URLSession para mejores tiempos de respuesta
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = environment.timeoutInterval
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 10
    }
    
    // Para guardar y obtener el token de autenticación
    var authToken: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }
    
    // Método genérico para realizar peticiones
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = environment.timeoutInterval
        
        // Configurar headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Añadir token si es necesario
        if requiresAuth {
            // Verificar si el token ha expirado antes de usarlo
            guard let token = authToken, !token.isEmpty else {
                print("❌ Error: No hay token de autenticación disponible y es requerido")
                return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
            }
            
            // Verificar si el token está expirado
            if let expirationTime = UserDefaults.standard.object(forKey: "tokenExpiration") as? Int {
                let currentTime = Int(Date().timeIntervalSince1970)
                if currentTime >= expirationTime {
                    print("❌ Token expirado. No se puede realizar la petición.")
                    
                    // Notificar a la aplicación que la sesión expiró
                    NotificationCenter.default.post(
                        name: Notification.Name("SessionExpired"),
                        object: nil
                    )
                    
                    return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
                }
            }
            
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 Token incluido en la petición: \(token.prefix(15))...")
        } else {
            print("🔓 Petición sin autenticación (no requiere token)")
        }
        
        // Añadir cuerpo de la petición si existe
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
            }
        }
        
        print("📤 Request: \(method) \(url)")
        if let body = body {
            print("Body: \(body)")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown
                }
                
                print("📥 Response: \(httpResponse.statusCode) \(url)")
                
                // Imprimir la respuesta para depuración
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response body: \(responseString)")
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                default:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
                    print("❌ Error: \(httpResponse.statusCode) \(errorMessage)")
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
                }
            }
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                }
                print("❌ Network Error: \(error.localizedDescription)")
                return APIError.networkError(error)
            }
            .flatMap { (data: Data) -> AnyPublisher<T, APIError> in
                // Intentamos decodificar la respuesta
                let decoder = JSONDecoder()
                
                // Configurar el decodificador para ser más flexible
                // Cambiamos la estrategia de decodificación para que no falle
                // si hay campos que no coinciden exactamente
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
                
                do {
                    print("⏳ Intentando decodificar respuesta...")
                    let decoded = try decoder.decode(T.self, from: data)
                    print("✅ Decodificación exitosa")
                    return Just(decoded)
                        .setFailureType(to: APIError.self)
                        .eraseToAnyPublisher()
                } catch {
                    print("❌ Decoding Error: \(error.localizedDescription)")
                    
                    // Imprimir la respuesta para depuración
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Failed to decode: \(responseString)")
                    }
                    
                    // Imprimir información detallada del error de decodificación
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("🔑 Clave no encontrada: \(key.stringValue) en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                            // Añadir información adicional sobre el índice si es un array
                            if let lastPathComponent = context.codingPath.last, 
                               let index = lastPathComponent.intValue {
                                print("📊 Índice: \(index)")
                            }
                        case .valueNotFound(let type, let context):
                            print("📭 Valor no encontrado para tipo \(type) en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        case .typeMismatch(let type, let context):
                            print("❌ Tipo incorrecto: esperaba \(type) en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                            // Añadir información sobre qué tipo se encontró si está disponible
                            if let underlyingError = context.underlyingError {
                                print("💥 Error subyacente: \(underlyingError)")
                            }
                        case .dataCorrupted(let context):
                            print("⚠️ Datos corruptos en \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                            if let underlyingError = context.underlyingError {
                                print("💥 Error subyacente: \(underlyingError)")
                            }
                        @unknown default:
                            print("🔍 Error de decodificación desconocido: \(decodingError)")
                        }
                    }
                    
                    return Fail(error: APIError.decodingError(error, data))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
} 
