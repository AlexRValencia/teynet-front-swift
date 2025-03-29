import SwiftUI

// Enumeration para representar las orientaciones del dispositivo
enum DeviceOrientation {
    case portrait
    case landscape
}

// Clase para detectar la rotación del dispositivo
class DeviceOrientationInfo: ObservableObject {
    @Published var orientation: DeviceOrientation = .portrait
    
    init() {
        // Inicialmente detectamos la orientación actual
        updateOrientation()
        
        // Configuramos para escuchar cambios de orientación
        NotificationCenter.default.addObserver(self, selector: #selector(updateOnRotation), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func updateOnRotation() {
        updateOrientation()
    }
    
    private func updateOrientation() {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        if let windowScene = windowScene {
            let size = windowScene.coordinateSpace.bounds.size
            self.orientation = size.width > size.height ? .landscape : .portrait
        }
    }
}

// ViewModifier para adaptar vistas a la orientación
struct AdaptToDeviceOrientation: ViewModifier {
    @ObservedObject private var orientationInfo = DeviceOrientationInfo()
    
    func body(content: Content) -> some View {
        content
            .environment(\.isLandscape, orientationInfo.orientation == .landscape)
    }
}

// Environment Key para acceder a la orientación
private struct IsLandscapeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isLandscape: Bool {
        get { self[IsLandscapeKey.self] }
        set { self[IsLandscapeKey.self] = newValue }
    }
}

// Extensión para View que facilita el uso del modificador
extension View {
    func adaptToDeviceOrientation() -> some View {
        self.modifier(AdaptToDeviceOrientation())
    }
} 