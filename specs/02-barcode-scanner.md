# SPEC 02 — Lector de código de barras con la cámara

> **Status:** Implementado
> **Depends on:** Ninguna
> **Date:** 2026-11-24
> **Objective:** Crear una pantalla SwiftUI reutilizable que lea un código de barras de producto con la cámara y entregue su valor a quien la presenta mediante un `Binding<String?>`.

---

## Alcance

**Dentro:**

- `BarcodeScannerView` (SwiftUI) que recibe `@Binding var scannedCode: String?`.
- Lectura con AVFoundation (`AVCaptureSession` + `AVCaptureMetadataOutput`) envuelta en `UIViewControllerRepresentable`.
- Tipos soportados: EAN-13, EAN-8 y UPC-E.
- Con el primer código leído: se escribe el valor en el binding, vibra con feedback de éxito y la pantalla se cierra sola.
- El valor se devuelve tal cual lo entrega AVFoundation. Un UPC-A llega como EAN-13 de 13 dígitos con `0` inicial.
- Recuadro guía centrado que además limita el área de lectura (`rectOfInterest`).
- Botón "Cancelar" que cierra sin leer y deja el binding en `nil`.
- Botón de linterna para encenderla y apagarla. Se oculta si el dispositivo no tiene linterna.
- Estado "permiso denegado": mensaje, botón "Abrir Ajustes" y botón "Cerrar".
- Estado "Cámara no disponible" (p. ej. simulador): mensaje y botón "Cerrar", sin crashear.
- Solicitud del permiso la primera vez, con `NSCameraUsageDescription` en el Info.plist generado.
- `BarcodeScannerViewModel` (`ObservableObject`) con la máquina de estados, probado en `ChofiTests`.
- `#Preview` con un botón que presenta el escáner en `.fullScreenCover` y muestra el valor leído, para probar en un iPhone real.

**Fuera de alcance (para futuras specs):**

- Integrar el escáner en algún flujo de la app (listado, carrito, búsqueda por código). Ninguna pantalla existente cambia.
- Buscar el producto por código, o añadir `barcode` al modelo `Product`.
- QR, Code128, Code39 u otras simbologías.
- Normalizar UPC-A a 12 dígitos o validar dígitos de control.
- Escaneo continuo o de varios códigos.
- Captura manual del código con teclado.
- Zoom, enfoque manual o elección de cámara frontal.
- Historial de códigos leídos o persistencia.

---

## Modelo de datos

No se agregan datos de dominio ni se toca `Product`. Solo hay estado de UI:

```swift
enum BarcodeScannerState: Equatable {
    case checkingPermission   // estado inicial, mientras se consulta o solicita el permiso
    case scanning             // cámara activa, esperando un código
    case permissionDenied     // .denied o .restricted
    case cameraUnavailable    // no hay dispositivo de video (simulador)
}

protocol CameraAuthorizing {
    var status: AVAuthorizationStatus { get }
    var isCameraAvailable: Bool { get }
    func requestAccess() async -> Bool
}

final class BarcodeScannerViewModel: ObservableObject {
    @Published private(set) var state: BarcodeScannerState = .checkingPermission
    @Published private(set) var scannedCode: String?   // se asigna una sola vez
    @Published var isTorchOn = false
    init(camera: CameraAuthorizing = SystemCameraAuthorizer())
    func start() async          // resuelve el estado inicial
    func handle(code: String)   // ignora vacíos y lecturas después de la primera
}
```

Convenciones:

- Tipos de metadata: `[.ean13, .ean8, .upce]`.
- `SystemCameraAuthorizer` es la implementación real sobre `AVCaptureDevice`. Las pruebas usan un doble que implementa `CameraAuthorizing`.
- Texto de `NSCameraUsageDescription`: "Chofi usa la cámara para leer el código de barras de los productos."
- La vista observa `viewModel.scannedCode`. Cuando cambia a un valor, lo copia al binding y llama `dismiss()`.

---

## Plan de implementación

1. Agregar `INFOPLIST_KEY_NSCameraUsageDescription` a las configuraciones Debug y Release del target `Chofi` en `project.pbxproj`. Verificar que compila.
2. Crear `Chofi/Models/BarcodeScannerState.swift` con el enum `BarcodeScannerState`.
3. Crear `Chofi/ViewModels/BarcodeScannerViewModel.swift` con `CameraAuthorizing`, `SystemCameraAuthorizer` y `BarcodeScannerViewModel`. Prueba: `ChofiTests/BarcodeScannerViewModelTests.swift` cubre:
   - permiso autorizado → `.scanning`;
   - `.notDetermined` aceptado → `.scanning`, rechazado → `.permissionDenied`;
   - `.denied`/`.restricted` → `.permissionDenied`;
   - sin cámara → `.cameraUnavailable`;
   - `handle(code:)` asigna el primer código, ignora los siguientes y los vacíos.
4. Crear `Chofi/Views/BarcodeCaptureViewController.swift`: `UIViewController` con `AVCaptureSession` y `AVCaptureVideoPreviewLayer`. El controlador:
   - arranca y detiene la sesión en una cola en segundo plano;
   - configura `rectOfInterest` con `metadataOutputRectConverted(fromLayerRect:)` a partir del recuadro;
   - entrega el primer código mediante un closure `onCode`;
   - expone `setTorch(_:)`.
5. Crear `Chofi/Views/CameraPreviewView.swift`: `UIViewControllerRepresentable` que aloja el controlador y propaga `isTorchOn` y `onCode`.
6. Crear `Chofi/Views/BarcodeScannerView.swift`. La vista:
   - muestra `CameraPreviewView` con el recuadro guía en `.scanning`;
   - muestra los mensajes de `.permissionDenied` (con "Abrir Ajustes" vía `UIApplication.openSettingsURLString`) y de `.cameraUnavailable`;
   - tiene los botones Cancelar y linterna;
   - lanza `UINotificationFeedbackGenerator().notificationOccurred(.success)` al leer;
   - escribe en el binding y llama `dismiss()`.
7. Agregar en `BarcodeScannerView.swift` el `#Preview` host: un botón "Escanear" que abre `.fullScreenCover` y un `Text` con el último valor leído.
8. Registrar los archivos nuevos en `Chofi.xcodeproj` (targets `Chofi` y `ChofiTests`) y verificar que compila para simulador y dispositivo.

Cada paso deja el proyecto compilando.

---

## Criterios de aceptación

- [X] El proyecto compila sin errores ni warnings nuevos para iOS 16.
- [X] La primera vez que se abre el escáner, iOS pide permiso de cámara con el texto de `NSCameraUsageDescription`.
- [X] Con el permiso concedido, se ve la imagen de la cámara con un recuadro guía centrado.
- [X] Al apuntar a un EAN-13 de un producto, el binding recibe exactamente esos 13 dígitos.
- [X] Un EAN-8 y un UPC-E también se leen y se devuelven.
- [X] Un código QR no se lee.
- [X] Un código que está fuera del recuadro guía no se lee.
- [X] Al leer, el teléfono vibra una vez y la pantalla se cierra sola.
- [X] Tras leer, el host del `#Preview` muestra el valor recibido.
- [X] "Cancelar" cierra la pantalla y el binding queda en `nil`.
- [X] El botón de linterna la enciende y la apaga.
- [X] El botón de linterna no aparece en dispositivos sin linterna.
- [X] Con el permiso denegado, se ve el mensaje con "Abrir Ajustes" y "Cerrar".
- [X] "Abrir Ajustes" abre la página de Chofi en Ajustes.
- [X] En el simulador se muestra "Cámara no disponible" con "Cerrar" y la app no crashea.
- [X] La sesión de cámara se detiene al cerrar la pantalla (el indicador verde de cámara se apaga).
- [X] Las pruebas de `BarcodeScannerViewModelTests` pasan con `Cmd+U`.
- [X] Ningún archivo de SPEC 01 (`MainTabView`, `ProductListView`, `Product`) cambia.

---

## Decisiones tomadas y descartadas

- **Sí:** AVFoundation con `AVCaptureMetadataOutput`. Funciona en cualquier iPhone con cámara que tenga iOS 16.
- **No:** VisionKit `DataScannerViewController`. Exige chip A12+ y no corre en el simulador.
- **Sí:** contrato `Binding<String?>`. Lo eligió el usuario: quien presenta la pantalla observa el cambio del valor.
- **No:** closure `onScan`, ni escaneo continuo.
- **Sí:** se cierra sola tras la primera lectura. La pantalla devuelve un único valor.
- **Sí:** solo EAN-13, EAN-8 y UPC-E. Son los códigos de productos de abarrotes, y así se evitan lecturas accidentales.
- **No:** QR ni Code128/Code39.
- **Sí:** devolver el valor sin transformar. Un formato estable, y la normalización se decide en la spec que lo consuma.
- **No:** quitar el `0` inicial de UPC-A. Confundiría EAN-13 mexicanos que empiezan en `0`.
- **Sí:** el recuadro limita el área de lectura con `rectOfInterest`. Evita leer otro producto que aparezca en el borde.
- **Sí:** el permiso denegado lleva a Ajustes. iOS no vuelve a mostrar el diálogo de permiso, así que es la única forma de recuperarse.
- **Sí:** estado "Cámara no disponible" en lugar de una captura manual. La captura manual añade alcance.
- **Sí:** vibración, linterna y botón Cancelar. Los pidió el usuario.
- **Sí:** MVVM con `ObservableObject` (iOS 16), igual que SPEC 01. La autorización se inyecta mediante `CameraAuthorizing` para poder probar los estados sin cámara.
- **Sí:** solo el componente, con un `#Preview` host para la verificación manual. Ningún flujo existente cambia.
- **No:** pestaña de depuración en `MainTabView`.
- **Sí:** la presentación (`.sheet` o `.fullScreenCover`) la decide quien llama. El componente solo usa `dismiss()`.

---

## Riesgos identificados

| Riesgo | Mitigación |
| --- | --- |
| `GENERATE_INFOPLIST_FILE = YES`: falta `NSCameraUsageDescription` y la app crashea al pedir la cámara | El paso 1 agrega `INFOPLIST_KEY_NSCameraUsageDescription` antes de tocar la cámara. |
| `startRunning()` bloquea el hilo principal | La sesión arranca y se detiene en una cola serial en segundo plano. |
| `rectOfInterest` calculado antes de que la capa tenga tamaño, y la lectura falla | Se recalcula en `viewDidLayoutSubviews` o cuando la sesión empieza a correr (`AVCaptureSessionDidStartRunning`). |
| Varias detecciones del mismo código llegan antes del cierre | El controlador y `handle(code:)` ignoran todo después de la primera lectura. |
| La cámara no corre en el simulador ni en previews de Xcode en Mac | Estado `.cameraUnavailable`. La verificación con cámara se hace en un iPhone real. |
| `objectVersion = 56`: los archivos nuevos no se detectan solos | El paso 8 los registra en `project.pbxproj`. |
| La linterna queda encendida al cerrar | Se apaga en `viewWillDisappear` del controlador. |

---

## Qué **no** está en esta spec

- Integración del escáner en el listado, el carrito o cualquier flujo.
- Búsqueda de producto por código ni campo `barcode` en `Product`.
- QR u otras simbologías.
- Normalización de UPC-A o validación del dígito de control.
- Escaneo continuo, captura manual, zoom o cámara frontal.
- Historial o persistencia de lecturas.

Cada uno, si se hace, va en su propia spec.
