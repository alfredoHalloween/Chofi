# SPEC 04 — Formulario para crear y editar un producto

> **Status:** Aprobado
> **Depends on:** SPEC 02, SPEC 03
> **Date:** 2026-11-26
> **Objective:** Crear un formulario en sheet que da de alta (`POST /`) o edita (`PUT /{id}`) un producto con código de barras opcional (escrito o escaneado), nombre, `brand_id` y precio `Decimal`, y actualizar en memoria el listado y el detalle con el producto que devuelve el servicio.

---

## Alcance

**Dentro:**

- `ProductFormView` con un solo modo de pantalla para crear y editar (`ProductFormMode.create` / `.edit(Product)`).
- Presentación en `.sheet` con su propio `NavigationStack`, "Cancelar" a la izquierda y "Guardar" a la derecha.
- Entrada para crear: un botón `+` (`plus`) en la toolbar de `ProductListView`.
- Entrada para editar: un botón "Editar" en la toolbar de `ProductDetailView`.
- Campos:
  - `barcode`: `TextField` opcional con un botón `barcode.viewfinder` que abre `BarcodeScannerView` (SPEC 02) en `.fullScreenCover`. El código leído reemplaza el texto. Cancelar el escáner no cambia el campo.
  - nombre (`product_name`): `TextField`, obligatorio.
  - `brand_id`: `TextField` con `.numberPad`, entero > 0, obligatorio.
  - precio: `TextField` con `.decimalPad`, se interpreta con el locale del dispositivo, es > 0, tiene como máximo 2 decimales y es obligatorio.
- En edición, los campos se precargan con el producto: `barcode ?? ""`, `name`, `brand.id` y `price`.
- "Guardar" solo se habilita si el formulario es válido, hay cambios (en edición) y no se está guardando.
- Mientras guarda: "Guardar" se cambia por un `ProgressView` y el formulario se deshabilita.
- Si el servicio falla: un alert "No se pudo guardar el producto" con el mensaje del error. El formulario conserva los datos.
- "Cancelar" con cambios pide confirmación ("Descartar cambios") y el swipe-down se bloquea (`interactiveDismissDisabled`). Sin cambios, cierra directo.
- `ProductsEndpoint` gana `.create(ProductRequest)` (`POST /`) y `.update(id:request:)` (`PUT /{id}`).
- `ProductsDataManagerProtocol` gana `createProduct(_:)` y `updateProduct(id:_:)`, que devuelven el `Product` de la respuesta.
- Migrar `Product.price` de `Double` a `Decimal`.
- `ProductListViewModel.upsert(_:)`: reemplaza el producto por `id` o lo agrega al final del listado cargado.
- `ProductDetailView` muestra el producto editado sin volver a la lista.
- Pruebas en `ChofiTests` del ViewModel del formulario, de `upsert`, de la codificación de `ProductRequest` y del precio `Decimal`.

**Fuera de alcance (para futuras specs):**

- Selector de marcas o endpoint `GET /brands`. `brand_id` se escribe a mano.
- Mostrar la marca o el código de barras en la fila o en el detalle.
- Eliminar productos (`DELETE`).
- Validar el formato del código de barras o su dígito de control.
- Verificar en la app que el código de barras no esté repetido. Si el servicio lo rechaza, se ve en el alert.
- Mostrar errores de validación del servidor por campo.
- Edición desde una swipe action en la lista.
- Imágenes de producto.
- Recargar todo el listado (`GET /`) después de guardar.
- Modo sin conexión o cola de guardados pendientes.
- Corregir la estructura de pestañas o migrar `BarcodeScannerViewModel`.

---

## Modelo de datos

Petición de `POST /` y de `PUT /{id}`:

```json
{
  "barcode": "7501040094422",
  "product_name": "Yoplait Disfruta Fresa 307g",
  "brand_id": 3,
  "price": 28.50
}
```

`barcode` se envía como `null` explícito cuando el campo queda vacío. Ambas respuestas tienen la misma forma que un elemento de `GET /` (SPEC 03), con `brand` anidado.

```swift
struct ProductRequest: Encodable, Equatable, Sendable {
    let barcode: String?     // nil → "barcode": null (encode explícito, no encodeIfPresent)
    let name: String
    let brandId: Int         // Long en el servicio
    let price: Decimal       // BigDecimal en el servicio

    enum CodingKeys: String, CodingKey {
        case barcode, price
        case name = "product_name"
        case brandId = "brand_id"
    }
}

struct Product: Identifiable, Codable, Hashable, Sendable {
    // ...igual que en SPEC 03, salvo:
    let price: Decimal       // antes Double
}

enum ProductsEndpoint: Endpoint {
    case products                                  // GET  /
    case create(ProductRequest)                    // POST /
    case update(id: Int, request: ProductRequest)  // PUT  /{id}
}

protocol ProductsDataManagerProtocol {
    func fetchProducts() async throws -> [Product]
    func createProduct(_ request: ProductRequest) async throws -> Product
    func updateProduct(id: Int, _ request: ProductRequest) async throws -> Product
}

enum ProductFormMode {
    case create
    case edit(Product)
}

@MainActor
@Observable
final class ProductFormViewModel {
    var barcode = ""
    var name = ""
    var brandIdText = ""
    var priceText = ""
    private(set) var saveState: LoaderState<Product> = .idle
    init(mode: ProductFormMode,
         dataManager: ProductsDataManagerProtocol = ProductsDataManager(),
         locale: Locale = .current)
    var title: String          // "Nuevo producto" / "Editar producto"
    var request: ProductRequest? { /* nil si algún campo es inválido */ }
    var hasChanges: Bool       // compara contra los valores iniciales
    var canSave: Bool          // request != nil && !saveState.isLoading && (create || hasChanges)
    func save() async -> Product?   // regresa si ya guarda; loading → loaded / error
    func dismissError()             // error → idle
}
```

En `ProductListViewModel`:

```swift
func upsert(_ product: Product)   // solo actúa si state es .loaded
```

En `ProductDetailView`:

```swift
init(product: Product, onProductSaved: @escaping (Product) -> Void = { _ in })
@State private var product: Product   // se reemplaza con el producto guardado
```

Convenciones:

- Archivos nuevos:
  - `Chofi/Shared/Models/ProductRequest.swift`;
  - `Chofi/Features/ProductForm/ViewModels/ProductFormViewModel.swift` (incluye `ProductFormMode`);
  - `Chofi/Features/ProductForm/Views/ProductFormView.swift`;
  - `ChofiTests/ProductFormViewModelTests.swift`;
  - `ChofiTests/ProductRequestEncodingTests.swift`.
- Normalización al construir `request`:
  - `barcode` y nombre se recortan con `trimmingCharacters(in: .whitespacesAndNewlines)`;
  - un `barcode` vacío se convierte en `nil`.
- `brandIdText` es válido si `Int(text)` existe y es > 0.
- `priceText` se interpreta con `Decimal(string:locale:)`. Es válido si es > 0, no tiene más de 2 decimales y todo el texto es numérico (no se ignora texto sobrante).
- En edición, `priceText` se precarga con el precio en formato de número del locale, sin símbolo de moneda.
- El error guarda `error.localizedDescription`, como en SPEC 03.
- Textos:
  - títulos "Nuevo producto" / "Editar producto";
  - etiquetas "Código de barras", "Nombre", "ID de marca", "Precio";
  - botones "Cancelar", "Guardar", "Editar";
  - el diálogo de descarte tiene el botón destructivo "Descartar cambios" y el botón "Seguir editando";
  - el alert dice "No se pudo guardar el producto", con el botón "OK".
- `formattedPrice` sigue con moneda MXN y locale `es_MX`, ahora sobre `Decimal`.

---

## Plan de implementación

Cada paso registra sus archivos nuevos en `project.pbxproj`, dentro del grupo de su carpeta y del target correcto.

1. Migrar `Product.price` a `Decimal`. Ajustar `formattedPrice`, `Product+Samples.swift` (literales `Decimal`) y `ProductDecodingTests`. Agregar a `ProductDecodingTests` un caso con `"price": 28.10` que compruebe `price == Decimal(string: "28.10")`. Verificar que la lista sigue mostrando `$28.00`.
2. Crear `Chofi/Shared/Models/ProductRequest.swift` con `encode(to:)` explícito para que `barcode` nil salga como `null`. Prueba: `ChofiTests/ProductRequestEncodingTests.swift` comprueba:
   - las llaves `barcode`, `product_name`, `brand_id` y `price`;
   - `"barcode": null` cuando es nil;
   - `28.5` se codifica como `28.5` sin errores de redondeo.
3. Agregar `.create` y `.update` a `ProductsEndpoint` (`method`, `path` y `body`). Agregar `createProduct` y `updateProduct` a `ProductsDataManagerProtocol` y `ProductsDataManager`. Actualizar el doble `FakeProductsDataManager` de `ProductListViewModelTests` para que siga compilando.
4. Agregar `upsert(_:)` a `ProductListViewModel`. Pruebas en `ProductListViewModelTests`:
   - con un `id` existente, se reemplaza el producto en su misma posición;
   - con un `id` nuevo, se agrega al final;
   - en `idle`, no cambia el estado.
5. Crear `ProductFormViewModel.swift` con `ProductFormMode`. Prueba: `ChofiTests/ProductFormViewModelTests.swift` con un doble que registra los requests. Casos:
   - en `.create`, los campos empiezan vacíos y `canSave` es falso;
   - en `.edit`, se precargan los campos y `canSave` es falso sin cambios;
   - con nombre vacío o solo de espacios, `brandIdText` "0", "abc" o vacío, o `priceText` "0", "12.345" o "12a", `request` es nil;
   - con `barcode` "  " se envía `nil`;
   - en `.create`, `save()` llama `createProduct` con el request esperado y regresa el producto;
   - en `.edit`, `save()` llama `updateProduct` con el `id` del producto;
   - si el doble lanza un error, `saveState` es `error` y los campos no cambian;
   - una segunda llamada mientras guarda no vuelve a llamar al doble;
   - con locale `es_MX`, el texto "28.50" se convierte en `Decimal(string: "28.50")`.
6. Crear `ProductFormView.swift`. La vista tiene:
   - un `Form` con los cuatro campos y el botón del escáner (`.fullScreenCover` con `BarcodeScannerView(scannedCode:)`, que copia el valor a `barcode` cuando deja de ser nil);
   - la toolbar con Cancelar y Guardar/`ProgressView`;
   - el alert de error;
   - el `confirmationDialog` de descarte;
   - `interactiveDismissDisabled(viewModel.hasChanges)`;
   - el formulario deshabilitado mientras guarda;
   - `#Preview` en los dos modos con un doble del DataManager.

   La vista recibe `mode` y `onSaved: (Product) -> Void`. Al guardar con éxito, llama `onSaved` y `dismiss()`.
7. En `ProductListView`, agregar el botón `+` en la toolbar, que presenta `ProductFormView(mode: .create)` en `.sheet`, con `onSaved: viewModel.upsert`. El botón solo aparece en el estado `loaded`.
8. En `ProductDetailView`, cambiar `let product` por `@State` con `init(product:onProductSaved:)`. Agregar el botón "Editar", que presenta `ProductFormView(mode: .edit(product))` en `.sheet`. Al guardar, reemplaza `product` y llama `onProductSaved`. En `ProductListView`, pasar `onProductSaved: viewModel.upsert` en el `navigationDestination`.

Cada paso deja el proyecto compilando.

---

## Criterios de aceptación

- [ ] El proyecto compila sin errores ni warnings nuevos fuera de `BarcodeScanner`.
- [ ] Con la lista cargada, la toolbar muestra un botón `+`. Al tocarlo, se abre un sheet "Nuevo producto" con los cuatro campos vacíos.
- [ ] "Guardar" está deshabilitado hasta que nombre, ID de marca y precio son válidos.
- [ ] Con precio "12.345", "0" o "abc", "Guardar" sigue deshabilitado.
- [ ] Con ID de marca "0" o vacío, "Guardar" sigue deshabilitado.
- [ ] Tocar el ícono `barcode.viewfinder` abre el escáner en pantalla completa. En un iPhone real, al leer un EAN-13 el campo muestra esos 13 dígitos.
- [ ] Cancelar el escáner deja el campo de código como estaba.
- [ ] El código se puede escribir a mano, y también se puede dejar vacío.
- [ ] Al guardar un producto nuevo sin código, el servicio recibe `POST /` con `"barcode": null`. El sheet se cierra y el producto aparece al final de la lista sin que se vea el `ProgressView` de carga.
- [ ] El precio "28.10" se guarda y se muestra como `$28.10`.
- [ ] En el detalle de un producto, la toolbar muestra "Editar". Al tocarlo, se abre "Editar producto" con los datos del producto precargados.
- [ ] En edición, "Guardar" está deshabilitado mientras no haya cambios.
- [ ] Al guardar una edición, el servicio recibe `PUT /{id}` con el `id` del producto. El detalle muestra el nombre y el precio nuevos. Al volver, la fila de la lista también los muestra.
- [ ] Mientras guarda, se ve un `ProgressView` en lugar de "Guardar" y los campos no se pueden editar.
- [ ] Con el túnel de ngrok apagado, al guardar aparece el alert "No se pudo guardar el producto". Al cerrarlo, los datos escritos siguen en el formulario.
- [ ] Con cambios sin guardar, "Cancelar" muestra "Descartar cambios". El sheet no se cierra con swipe-down.
- [ ] Sin cambios, "Cancelar" cierra el sheet directamente.
- [ ] `Product.price` es `Decimal`.
- [ ] Las pruebas de `ProductFormViewModelTests`, `ProductRequestEncodingTests`, `ProductListViewModelTests` y `ProductDecodingTests` pasan con `Cmd+U`.
- [ ] Las pruebas de `BarcodeScannerViewModelTests` siguen pasando.
- [ ] Los archivos de `BarcodeScanner`, `MainTabView` y `ProductRowView` no cambian.

---

## Decisiones tomadas y descartadas

- **Sí:** `POST /` y `PUT /{id}`, que responden el `Product` completo. Es el contrato que confirmó el usuario y permite actualizar en memoria sin otro `GET`.
- **No:** `PATCH`. Siempre se envían los cuatro campos.
- **No:** recargar el listado tras guardar. El producto devuelto basta, y así se evita un `ProgressView` y una petición extra.
- **Sí:** el mismo `ProductFormView` y `ProductFormViewModel` para los dos modos, con `ProductFormMode`. Los campos y las reglas son idénticos.
- **Sí:** un `.sheet` con `NavigationStack` propio. Es el patrón estándar de iOS para altas y ediciones, y no interfiere con el `NavigationStack` de `MainTabView`.
- **No:** push en el `NavigationStack`.
- **Sí:** `+` en la lista y "Editar" en el detalle. **No:** swipe action para editar.
- **Sí:** `brand_id` como campo numérico libre. No existe un endpoint de marcas, y un selector va en otra spec.
- **No:** un picker con las marcas de los productos cargados. No permitiría usar una marca que todavía no tiene productos.
- **Sí:** nombre, marca y precio obligatorios. El código de barras es opcional y vacío se envía como `null`.
- **Sí:** enviar `"barcode": null` explícito en lugar de omitir la llave. En un `PUT`, así queda claro que el código se borra.
- **Sí:** migrar `Product.price` a `Decimal`. Coincide con `BigDecimal` y evita enviar `28.099999999999998` en lugar de `28.1`. Reemplaza el `Double` de SPEC 03.
- **No:** usar `Decimal` solo en el request. Habría dos tipos para el mismo dato.
- **Sí:** el precio en un `TextField` de texto con `.decimalPad` y `Decimal(string:locale:)`. Permite validar en vivo.
- **No:** `TextField(value:format: .currency)`. Solo confirma el valor al salir del campo.
- **Sí:** máximo 2 decimales en el precio. Son centavos de MXN.
- **Sí:** las llamadas nuevas viven en `ProductsEndpoint` y `ProductsDataManager`. Un recurso tiene un solo DataManager, que comparte `baseURL` y el header de ngrok.
- **No:** `ProductFormEndpoint` ni `ProductFormDataManager` separados.
- **Sí:** `ProductRequest` en `Shared/Models`, junto a `Product`, porque es parte del modelo del recurso.
- **Sí:** el escáner de SPEC 02 en `.fullScreenCover`, abierto con un ícono junto al campo. El código leído reemplaza el texto. Es la primera integración del escáner en un flujo.
- **Sí:** un `ProgressView` en la toolbar y un alert para los errores. El formulario conserva los datos para reintentar.
- **No:** un mensaje de error dentro del formulario.
- **Sí:** confirmar el descarte e `interactiveDismissDisabled` cuando hay cambios. Evita perder lo escrito por accidente.
- **Sí:** `ProductDetailView` con `@State product` y un callback `onProductSaved`. Es el cambio mínimo para que el detalle refleje la edición sin compartir el ViewModel de la lista.
- **Sí:** `upsert` agrega los productos nuevos al final. Coincide con el orden por `id` que devuelve `GET /`.
- **Sí:** el botón `+` solo aparece con la lista cargada. `upsert` no tiene sobre qué actuar en `idle`, `loading` o `error`.
- **Sí:** `@MainActor` explícito en `ProductFormViewModel`, como en SPEC 03.

---

## Riesgos identificados

| Riesgo | Mitigación |
| --- | --- |
| `JSONDecoder` decodifica `Decimal` pasando por `Double` y `28.10` llega como `28.099999…` | Una prueba del paso 1 lo verifica. Si falla, `Product` decodifica `price` con un `init(from:)` propio, a partir de la representación textual. |
| El servicio responde algo distinto del `Product` completo en `POST`/`PUT` (p. ej. `201` sin body) | La decodificación falla y se ve el alert. El contrato se valida contra el servicio en el paso 3, y si cambia se actualiza esta spec. |
| Un `brand_id` inexistente o un `barcode` repetido devuelven un 4xx | Se ve el alert con el mensaje de `NetworkError`. La validación por campo queda fuera de alcance. |
| El locale del dispositivo usa coma decimal y el usuario escribe punto (o al revés) | `Decimal(string:locale:)` con el locale del dispositivo, y `.decimalPad` muestra el separador correcto. Hay una prueba con `es_MX`. |
| `.fullScreenCover` del escáner sobre un `.sheet` | SwiftUI lo soporta. Se verifica en un iPhone real según los criterios. |
| `ProductDetailView` con `@State` inicializado en `init` ignora un `product` nuevo si la vista se reutiliza | El detalle se crea en cada push desde `navigationDestination`, así que no se reutiliza con otro producto. |
| `objectVersion = 56`: los archivos nuevos no se detectan solos | Cada paso registra sus archivos en `project.pbxproj`. |

---

## Qué **no** está en esta spec

- Selector de marcas o `GET /brands`.
- Marca o código de barras en la fila o el detalle.
- Eliminar productos.
- Validación del código de barras o de duplicados en la app.
- Errores de validación del servidor por campo.
- Edición con swipe action.
- Imágenes de producto.
- Recargar el listado tras guardar.
- Modo sin conexión.
- Cambios en las pestañas o en `BarcodeScannerViewModel`.

Cada uno, si se hace, va en su propia spec.
