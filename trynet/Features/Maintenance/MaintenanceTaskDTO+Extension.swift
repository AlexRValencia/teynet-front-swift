import Foundation
import SwiftUI

extension MaintenanceTaskDTO {
    // Función mejorada para extraer datos de cualquier tipo de la respuesta JSON
    func extractDataFromAnyJSON<T>(_ key: String, ofType: T.Type) -> T? {
        // Aquí implementamos la lógica real para extraer campos adicionales
        // Esta función sería llamada por toMaintenanceTask para cada tipo de dato
        
        // Para Arrays de Double como coordenadas
        if T.self == [Double].self {
            if key == "pointCoordinates", let coordinates = self.pointCoordinates as? [Double], coordinates.count == 2 {
                return coordinates as? T
            }
        }
        
        // Para Strings como IDs o nombres
        if T.self == String.self {
            switch key {
            case "projectId":
                return self.projectId as? T
            case "projectName":
                return self.projectName as? T
            case "pointId":
                return self.pointId as? T
            case "pointType":
                return self.pointType as? T
            default:
                break
            }
        }
        
        // Para Arrays de String como equipos dañados
        if T.self == [String].self {
            if key == "damagedEquipment", let equipment = self.damagedEquipment as? [String] {
                return equipment as? T
            }
        }
        
        // Para Diccionarios de String como cables instalados
        if T.self == [String: Any].self {
            if key == "cableInstalled", let cable = self.cableInstalled as? [String: Any] {
                return cable as? T
            }
        }
        
        return nil
    }
}

// Métodos auxiliares para procesar datos
extension MaintenanceTaskDTO {
    // Función auxiliar para extraer coordenadas de diferentes formatos
    func processCoordinates() -> [Double]? {
        if let coordinates = pointCoordinates, coordinates.count == 2 {
            return coordinates
        } else if let lat = pointLatitude, let lng = pointLongitude {
            return [lat, lng]
        }
        return nil
    }
    
    // Función para procesar cables instalados a formato string
    func processCableInstalled() -> [String: String]? {
        if let cableInstalled = cableInstalled {
            var cableInstalledMap: [String: String] = [:]
            for (key, value) in cableInstalled {
                cableInstalledMap[key] = String(Int(value))
            }
            return cableInstalledMap
        }
        return nil
    }
} 