# Autenticación Biométrica en TryNet

Este documento explica cómo se ha implementado la autenticación biométrica (Face ID / Touch ID) en la aplicación TryNet.

## Características Implementadas

- Detección automática del tipo de biometría disponible (Face ID o Touch ID)
- Opción para habilitar/deshabilitar la autenticación biométrica
- Almacenamiento seguro de credenciales en el Keychain
- Flujo de autenticación biométrica completo
- Manejo de errores y estados de autenticación

## Archivos Principales

1. **BiometricAuthService.swift**: Servicio que maneja toda la lógica de autenticación biométrica.
2. **AuthViewModel.swift**: Actualizado para incluir métodos de autenticación biométrica.
3. **LoginView.swift**: Actualizado para mostrar opciones de autenticación biométrica en la UI.
4. **Info.plist**: Configurado con los permisos necesarios para Face ID (ubicado en la raíz del proyecto).
5. **trynet.entitlements**: Configurado para permitir el acceso al Keychain (ubicado en la raíz del proyecto).

## Flujo de Autenticación Biométrica

1. Al iniciar la aplicación, se verifica si el dispositivo tiene capacidades biométricas.
2. En la pantalla de login, se muestra un botón para iniciar sesión con biometría si está disponible.
3. El usuario puede habilitar/deshabilitar la autenticación biométrica mediante una opción en la pantalla de login.
4. Cuando el usuario inicia sesión con credenciales y tiene habilitada la biometría, las credenciales se guardan de forma segura en el Keychain.
5. En futuros inicios de sesión, el usuario puede usar Face ID/Touch ID para autenticarse sin ingresar credenciales.

## Seguridad

- Las credenciales se almacenan de forma segura en el Keychain de iOS.
- Solo se puede acceder a las credenciales después de una autenticación biométrica exitosa.
- Las credenciales están protegidas por el enclave seguro del dispositivo.
- Se utiliza `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` para asegurar que las credenciales solo sean accesibles cuando el dispositivo está desbloqueado y solo en el dispositivo actual.

## Configuración del Proyecto

Para evitar conflictos con múltiples archivos Info.plist, hemos:
1. Colocado el archivo Info.plist en la raíz del proyecto
2. Añadido la clave NSFaceIDUsageDescription para solicitar permiso para usar Face ID/Touch ID
3. Colocado el archivo trynet.entitlements en la raíz del proyecto para configurar el acceso al Keychain

## Consideraciones para el Desarrollo

- La autenticación biométrica es una característica opcional y siempre debe haber un método alternativo de autenticación.
- Se debe manejar adecuadamente los casos en que la biometría no está disponible o falla.
- Es importante proporcionar mensajes claros al usuario sobre el estado de la autenticación.

## Pruebas

Para probar la autenticación biométrica en el simulador:

1. Ejecutar la aplicación en el simulador.
2. En el simulador, ir a Features > Face ID/Touch ID > Enrolled.
3. Cuando la aplicación solicite autenticación biométrica, usar Hardware > Face ID/Touch ID > Matching Face/Fingerprint.

Para simular fallos:
- Hardware > Face ID/Touch ID > Non-matching Face/Fingerprint
- Hardware > Face ID/Touch ID > Locked Out 