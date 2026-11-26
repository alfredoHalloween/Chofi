# SPEC 03 — Listado de productos desde el servicio web

> **Status:** Implementado
> **Depends on:** SPEC 01
> **Date:** 2026-11-26
> **Objective:** Cargar el listado de productos desde el servicio web de Chofi con NetworkKit y el patrón Endpoint → DataManager → ViewModel con `LoaderState` de Free Games, mostrando estados de carga y de error con reintento.

---

## Alcance

**Dentro:**

- Subir `IPHONEOS_DEPLOYMENT_TARGET` de 16.0 a 17.0 en el proyecto y en los targets `Chofi`, `ChofiTests` y `ChofiUITests`, porque NetworkKit requiere iOS 17.
- `LoaderState<T>` en `Chofi/Shared/State/LoaderState.swift`, igual que en Free Games (`idle`/`loading`/`loaded(T)`/`error(String)`, con `isLoading`, `data` y `error`).
- Modelo `Product` decodificable desde el servicio: `id: Int`, `name` (de `product_name`), `price`, `barcode: String?` y `brand: Brand`.
- Modelo nuevo `Brand` (`id`, `name`).
- `ProductsEndpoint` (NetworkKit `Endpoint`) con `GET /` sobre la URL base de ngrok.
- `ProductsDataManagerProtocol` y `ProductsDataManager`, que recibe `any NetworkClient` (por defecto `NetworkManager()`).
- Migrar `ProductListViewModel` de `ObservableObject` a `@Observable` con `state: LoaderState<[Product]>` y `fetchProducts()`.
- El buscador sigue filtrando en local, sobre los productos ya cargados.
- `ProductListView` con `@State` para el ViewModel, carga en `.task` y un `switch` sobre el estado:
  - `ProgressView` en `idle` y `loading`;
  - la lista en `loaded`;
  - `ContentUnavailableView` con un botón "Reintentar" en `error`.
- `Product.samples` actualizados al nuevo modelo y usados solo en los `#Preview` y en las pruebas.
- Pruebas en `ChofiTests`:
  - el ViewModel con un doble de `ProductsDataManagerProtocol`;
  - la decodificación de un JSON con la forma real del servicio.

**Fuera de alcance (para futuras specs):**

- Mostrar la marca o el código de barras en la fila o en el detalle. `ProductDetailView` y `ProductRowView` no cambian.
- Imágenes de producto. El servicio no envía URL de imagen y `imageURL` se elimina del modelo.
- `create_at` y `update_at` (se ignoran al decodificar).
- Pull to refresh, estado vacío y mensaje de "sin resultados".
- URL base configurable por build setting o Info.plist.
- Detalle por id (`GET /{id}`), búsqueda por código de barras en el servicio, altas, bajas o edición.
- Caché, persistencia o modo sin conexión.
- Corregir la estructura de pestañas (`TabView` dentro de `ProductListView`, `MainTabView` sin `TabView`). Queda como está.
- Migrar `BarcodeScannerViewModel` a `@Observable`.

---

## Modelo de datos

Respuesta de `GET /` (arreglo; se muestra un elemento):

```json
{
  "id": 1,
  "product_name": "Yoplait Disfruta Fresa 307g",
  "price": 28.00,
  "barcode": "7501040094422",
  "brand": { "id": 3, "name": "Sigma" },
  "create_at": "2026-10-29T00:00:00",
  "update_at": "2026-11-14T14:37:21"
}
```

`barcode` puede llegar como `null`.

```swift
struct Brand: Codable, Hashable, Sendable {
    let id: Int
    let name: String
}

struct Product: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let name: String
    let price: Double        // MXN
    let barcode: String?
    let brand: Brand

    enum CodingKeys: String, CodingKey {
        case id, price, barcode, brand
        case name = "product_name"
    }

    var formattedPrice: String { /* sin cambios */ }
}
```

```swift
enum ProductsEndpoint: Endpoint {
    case products
    // baseURL: "https://805e-2806-2f0-a5c1-d7c7-604e-b8a2-7c5b-59a1.ngrok-free.app"
    // path:    "/"
    // headers: ["ngrok-skip-browser-warning": "true"]
}

protocol ProductsDataManagerProtocol {
    func fetchProducts() async throws -> [Product]
}

@MainActor
@Observable
final class ProductListViewModel {
    var searchText = ""
    private(set) var state: LoaderState<[Product]> = .idle
    init(dataManager: ProductsDataManagerProtocol = ProductsDataManager())
    var filteredProducts: [Product] { /* filtra state.data ?? [] con searchText */ }
    func fetchProducts() async   // regresa si ya está cargando; loading → loaded / error
}
```

Convenciones:

- Ubicación de los archivos nuevos:
  - `Chofi/Shared/Models/Brand.swift`;
  - `Chofi/Shared/State/LoaderState.swift`;
  - `Chofi/Features/ProductList/Services/ProductsEndpoint.swift`;
  - `Chofi/Features/ProductList/Services/ProductsDataManager.swift`.
- El filtro conserva las reglas de SPEC 01: subcadena, sin distinguir mayúsculas ni acentos, y un texto vacío o solo de espacios devuelve todo.
- El estado `error` guarda `error.localizedDescription`, como en Free Games.
- Textos del error:
  - título "No se pudieron cargar los productos" con el ícono `wifi.exclamationmark`;
  - la descripción es el mensaje del error;
  - el botón dice "Reintentar".
- El ViewModel es `@MainActor` explícito porque Chofi no usa `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.

---

## Plan de implementación

Cada paso registra sus archivos nuevos en `project.pbxproj`, dentro del grupo de su carpeta y del target correcto.

1. Cambiar `IPHONEOS_DEPLOYMENT_TARGET` a `17.0` en todas las configuraciones de `project.pbxproj`. Verificar que compila con NetworkKit ya enlazado.
2. Crear `Chofi/Shared/State/LoaderState.swift`, copiado de Free Games.
3. Crear `Chofi/Shared/Models/Brand.swift`. En `Product`:
   - cambiar `id` a `Int`;
   - agregar `barcode` y `brand`;
   - quitar `imageURL`;
   - conformar a `Codable` y `Sendable` con sus `CodingKeys`.

   Actualizar `Product+Samples.swift` con ids fijos, marcas y algunos `barcode: nil`. Prueba: `ChofiTests/ProductDecodingTests.swift` decodifica un JSON de dos elementos, uno con `barcode: null`, y comprueba `name`, `price`, `barcode` y `brand.name`.
4. Crear `ProductsEndpoint.swift` y `ProductsDataManager.swift` en `Chofi/Features/ProductList/Services/`.
5. Migrar `ProductListViewModel` a `@Observable` + `@MainActor` con `state`, `fetchProducts()` y el `init(dataManager:)`. En `ProductListView`, cambiar `@StateObject` por `@State` y usar `@Bindable` para el `.searchable`. Reescribir `ChofiTests/ProductListViewModelTests.swift` con un `FakeProductsDataManager` que devuelve `Product.samples` o lanza un error. Casos:
   - el estado inicial es `idle`;
   - tras `fetchProducts()` exitoso el estado es `loaded` con los productos del doble;
   - si el doble lanza un error, el estado es `error`;
   - una segunda llamada mientras carga no vuelve a llamar al doble;
   - los casos de filtrado de SPEC 01 se ejecutan sobre los productos cargados;
   - antes de cargar, `filteredProducts` está vacío.
6. En `ProductListView`, agregar un `.task` que llama a `fetchProducts()` solo si el estado es `idle`, y el `switch` sobre `viewModel.state`: `ProgressView`, la lista con `.searchable`, o `ContentUnavailableView` con "Reintentar".

Cada paso deja el proyecto compilando.

---

## Criterios de aceptación

- [ ] El proyecto compila sin errores ni warnings nuevos fuera de `BarcodeScanner` con deployment target iOS 17.0.
- [ ] Al abrir la app se ve un `ProgressView` y después la lista con los productos que devuelve `GET /` del servicio.
- [ ] La primera fila es "Yoplait Disfruta Fresa 307g" con el precio `$28.00`, o el producto con `id` 1 que devuelva el servicio en ese momento.
- [ ] Un producto con `barcode: null` se decodifica y aparece en la lista.
- [ ] Ningún producto de `Product.samples` aparece en la app en ejecución.
- [ ] Escribir "coca" en el buscador deja solo los productos cuyo nombre contiene "Coca".
- [ ] Tocar una fila hace push a `ProductDetailView` con el nombre y el precio de ese producto.
- [ ] Con el modo avión activo (o con el túnel de ngrok apagado), se ve "No se pudieron cargar los productos" con el botón "Reintentar".
- [ ] Al desactivar el modo avión y tocar "Reintentar", se ve el `ProgressView` y después la lista.
- [ ] Volver del detalle no recarga la lista: no aparece el `ProgressView`.
- [ ] `ProductDetailView`, `ProductRowView`, `MainTabView` y los archivos de `BarcodeScanner` no cambian.
- [ ] `Product` ya no tiene `imageURL`.
- [ ] Las pruebas de `ProductListViewModelTests` y `ProductDecodingTests` pasan con `Cmd+U`.
- [ ] Las pruebas de `BarcodeScannerViewModelTests` siguen pasando.

---

## Decisiones tomadas y descartadas

- **Sí:** subir a iOS 17. NetworkKit declara `.iOS(.v17)` y era la condición para reutilizarlo como en Free Games.
- **No:** quedarse en iOS 16 con un cliente `URLSession` propio. Duplica NetworkKit y se aleja del proyecto de referencia.
- **Sí:** migrar `ProductListViewModel` a `@Observable` con `LoaderState`, igual que `GamesViewModel`. Con iOS 17 ya está disponible. Esto reemplaza la decisión de SPEC 01 de usar `ObservableObject` por estar en iOS 16.
- **No:** migrar `BarcodeScannerViewModel`. No forma parte de esta feature.
- **Sí:** aceptar los 6 warnings de deprecación que aparecen en `BarcodeScanner` al subir a iOS 17 (`videoOrientation`, `isVideoOrientationSupported`, `onChange(of:perform:)`). Decidido el 2026-11-26 durante el paso 1. **No:** corregirlos aquí, porque cambiar la rotación de la cámara requiere verificar en un iPhone real y va en su propia spec.
- **Sí:** `LoaderState` en `Shared/State`, como en Free Games, para reutilizarlo en futuras pantallas con carga.
- **Sí:** `Product` con `id: Int`, `barcode` y `brand`. El `id` del servicio es estable y reemplaza el `UUID` local. `barcode` y `brand` quedan listos para futuras specs aunque la UI no los muestre.
- **No:** `create_at` y `update_at`. Usan un formato ISO sin zona horaria que obliga a una estrategia de fechas propia, y nada los usa.
- **Sí:** eliminar `imageURL`. El servicio no la envía y solo la usaban los datos de ejemplo.
- **Sí:** `Brand` en `Shared/Models` junto a `Product`, porque es parte del modelo compartido.
- **Sí:** URL base como constante en `ProductsEndpoint`, igual que `GamesEndpoint`. Cuando cambie el túnel de ngrok se edita una línea.
- **No:** build setting o Info.plist para la URL. Agrega configuración que el usuario no pidió.
- **Sí:** header `ngrok-skip-browser-warning`. Evita que ngrok responda con su página HTML de advertencia en lugar del JSON. No afecta a un servidor que no sea ngrok.
- **Sí:** estados de carga y de error con "Reintentar", como `GamesPageView`.
- **Sí:** el `.task` solo carga si el estado es `idle`. En Free Games el `.task` está sobre el `NavigationStack`, que nunca desaparece. En Chofi la lista desaparece al hacer push y su `.task` vuelve a correr al regresar.
- **No:** pull to refresh ni estado vacío. Se dejan para otra spec.
- **Sí:** filtrado local sobre lo cargado. El servicio no expone búsqueda y el catálogo es pequeño.
- **Sí:** `Product.samples` solo para previews y pruebas. Las previews no dependen del túnel.
- **Sí:** probar el ViewModel con un doble de `ProductsDataManagerProtocol`, que es la costura que define Free Games.
- **No:** `MockNetworkClient` en las pruebas. Obligaría a enlazar `NetworkKitMocks` a `ChofiTests`. La decodificación se cubre con `ProductDecodingTests`.
- **Sí:** `@MainActor` explícito en el ViewModel. Chofi no tiene `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` como Free Games.
- **Sí:** no tocar la estructura de pestañas. Son cambios del usuario en curso y no forman parte de esta feature.
- **Sí:** los modelos del dominio no se marcan `nonisolated`. Sin aislamiento por defecto en `MainActor`, no hace falta.

---

## Riesgos identificados

| Riesgo | Mitigación |
| --- | --- |
| La URL de ngrok cambia al reiniciar el túnel y la app deja de cargar | Se muestra el estado de error con "Reintentar". La URL vive en una sola constante de `ProductsEndpoint`. |
| ngrok gratuito responde con una página HTML de advertencia | Header `ngrok-skip-browser-warning`. Si aun así llega HTML, la decodificación falla y se ve el estado de error. |
| Subir a iOS 17 cambia el comportamiento de `.searchable` o de `NavigationStack` | Los criterios de aceptación verifican la búsqueda y el push en simulador. |
| `.task` vuelve a correr al regresar del detalle, porque el `NavigationStack` vive en `MainTabView` y no en `ProductListView` | El `.task` solo carga si el estado es `idle`. "Reintentar" llama a `fetchProducts()` directamente. Un criterio verifica que no aparece el `ProgressView` al volver. |
| `price` llega como entero (`28` en vez de `28.00`) | `JSONDecoder` decodifica enteros JSON como `Double` sin problema. |
| `objectVersion = 56`: los archivos nuevos no se detectan solos | Cada paso registra sus archivos en `project.pbxproj`. |
| NetworkKit está enlazado al target `Chofi` en cambios sin commit | Se incluye en el mismo trabajo. El paso 1 verifica que compila con el paquete resuelto. |

---

## Qué **no** está en esta spec

- Marca o código de barras en la fila o el detalle.
- Imágenes de producto.
- Pull to refresh, estado vacío o "sin resultados".
- URL base configurable.
- Detalle por id, búsqueda por código en el servicio o edición del catálogo.
- Caché, persistencia o modo sin conexión.
- Cambios en la estructura de pestañas.
- Migración de `BarcodeScannerViewModel`.
- Migración del escáner a las APIs de iOS 17 (`videoRotationAngle`, `onChange` nuevo).

Cada uno, si se hace, va en su propia spec.
