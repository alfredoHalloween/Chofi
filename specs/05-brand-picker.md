# SPEC 05 — Selector de marca para el formulario de producto

> **Status:** Aprobado
> **Depends on:** SPEC 03, SPEC 04
> **Date:** 2026-11-26
> **Objective:** Reemplazar el campo "ID de marca" de `ProductFormView` por una fila "Marca" que hace push a un listado buscable de las marcas de `GET /brand`, donde un toque selecciona la marca y regresa al formulario.

---

## Alcance

**Dentro:**

- `BrandPickerView`: un listado de marcas al que se llega con push dentro del `NavigationStack` del sheet de `ProductFormView`.
- La carga ocurre en `.task` cada vez que se abre el selector:
  - `ProgressView` en `idle` y `loading`;
  - la lista en `loaded`;
  - `ContentUnavailableView` con un botón "Reintentar" en `error`.
- Cada fila muestra `brand.name`. La marca seleccionada lleva un `checkmark`, comparando por `id`.
- Un toque selecciona la marca y regresa solo al formulario (`dismiss()`).
- `.searchable` con filtro local por nombre y las reglas de SPEC 01: subcadena, sin distinguir mayúsculas ni acentos, y un texto vacío o solo de espacios devuelve todo. Si no hay resultados, se muestra `ContentUnavailableView.search(text:)`.
- El orden es el del servicio, que ya devuelve las marcas ordenadas por nombre.
- `BrandsEndpoint` (`GET /brand`), `BrandsDataManagerProtocol`, `BrandsDataManager` y `BrandPickerViewModel` en `Chofi/Features/BrandPicker/`.
- `APIConfig` en `Chofi/Shared/Network/APIConfig.swift` con la URL de ngrok y el header `ngrok-skip-browser-warning`. `ProductsEndpoint` y `BrandsEndpoint` la usan.
- En `ProductFormView`, la sección "ID de marca" se convierte en "Marca": un `NavigationLink` con `LabeledContent("Marca")`, que muestra el nombre de la marca o "Seleccionar" en gris secundario.
- En `ProductFormViewModel`, `brandIdText: String` se reemplaza por `selectedBrand: Brand?`:
  - en edición se precarga con `product.brand`, sin pedir nada al servicio;
  - `request` usa `selectedBrand?.id`;
  - `hasChanges` compara el `id` de la marca.
- Pruebas en `ChofiTests` de `BrandPickerViewModel`, de la decodificación de `[Brand]`, y los ajustes de `ProductFormViewModelTests`.

**Fuera de alcance (para futuras specs):**

- Crear, editar o eliminar marcas (`POST`/`PUT`/`DELETE /brand`).
- Mostrar la marca en `ProductRowView` o en `ProductDetailView`.
- Una opción "Sin marca" o deseleccionar. La marca sigue siendo obligatoria.
- Pull to refresh en el listado de marcas.
- Guardar las marcas en caché entre aperturas o entre sesiones.
- Ordenar o agrupar las marcas en la app (secciones por letra, índice lateral).
- Cambiar las rutas de `ProductsEndpoint`.

---

## Modelo de datos

Respuesta de `GET /brand` (se muestran dos de los 21 elementos):

```json
[
  { "id": 18, "name": "Alen" },
  { "id": 4,  "name": "Bimbo" }
]
```

`Brand` (SPEC 03) ya tiene esta forma y no cambia.

```swift
enum APIConfig {
    static let baseURL = "https://8bd4-2806-2f0-a5c1-d7c7-604e-b8a2-7c5b-59a1.ngrok-free.app"
    static let headers = ["ngrok-skip-browser-warning": "true"]
}

enum BrandsEndpoint: Endpoint {
    case brands                       // GET /brand
    // baseURL: APIConfig.baseURL
    // headers: APIConfig.headers
}

protocol BrandsDataManagerProtocol {
    func fetchBrands() async throws -> [Brand]
}

final class BrandsDataManager: BrandsDataManagerProtocol {
    init(client: any NetworkClient = NetworkManager())
}

@MainActor
@Observable
final class BrandPickerViewModel {
    var searchText = ""
    private(set) var state: LoaderState<[Brand]> = .idle
    init(dataManager: BrandsDataManagerProtocol = BrandsDataManager())
    var filteredBrands: [Brand]   // filtra state.data ?? [] con searchText
    func fetchBrands() async      // regresa si ya está cargando; loading → loaded / error
}

struct BrandPickerView: View {
    init(selection: Binding<Brand?>,
         dataManager: BrandsDataManagerProtocol = BrandsDataManager())
}
```

En `ProductFormViewModel`:

```swift
var selectedBrand: Brand?        // reemplaza brandIdText
// Values guarda selectedBrandId: Int? en lugar de brandIdText
```

Convenciones:

- Archivos nuevos:
  - `Chofi/Shared/Network/APIConfig.swift`;
  - `Chofi/Features/BrandPicker/Services/BrandsEndpoint.swift`;
  - `Chofi/Features/BrandPicker/Services/BrandsDataManager.swift`;
  - `Chofi/Features/BrandPicker/ViewModels/BrandPickerViewModel.swift`;
  - `Chofi/Features/BrandPicker/Views/BrandPickerView.swift`;
  - `ChofiTests/BrandPickerViewModelTests.swift`;
  - `ChofiTests/BrandDecodingTests.swift`.
- El estado `error` guarda `error.localizedDescription`, como en SPEC 03.
- Textos:
  - el título del selector es "Marca";
  - el placeholder del buscador es "Buscar marca";
  - la fila del formulario dice "Marca" con el valor "Seleccionar" o el nombre de la marca;
  - el error tiene el título "No se pudieron cargar las marcas", el ícono `wifi.exclamationmark`, el mensaje del error como descripción y el botón "Reintentar".

---

## Plan de implementación

Cada paso registra sus archivos nuevos en `project.pbxproj`, dentro del grupo de su carpeta y del target correcto.

1. Crear `Chofi/Shared/Network/APIConfig.swift`. Hacer que `ProductsEndpoint` use `APIConfig.baseURL` y `APIConfig.headers` sin cambiar sus rutas ni sus métodos. Verificar que la lista sigue cargando.
2. Crear `BrandsEndpoint.swift` y `BrandsDataManager.swift` en `Chofi/Features/BrandPicker/Services/`. Prueba: `ChofiTests/BrandDecodingTests.swift` decodifica el JSON de ejemplo de `GET /brand` y comprueba la cantidad, `id` y `name`.
3. Crear `BrandPickerViewModel.swift`. Prueba: `ChofiTests/BrandPickerViewModelTests.swift` con un `FakeBrandsDataManager` que devuelve marcas o lanza un error. Casos:
   - el estado inicial es `idle`;
   - tras `fetchBrands()` exitoso, el estado es `loaded` con las marcas del doble, en el mismo orden;
   - si el doble lanza un error, el estado es `error`;
   - una segunda llamada mientras carga no vuelve a llamar al doble;
   - "nestle" encuentra "Nestlé", "COCA" encuentra "Coca Cola" y un texto de solo espacios devuelve todo;
   - antes de cargar, `filteredBrands` está vacío.
4. Crear `BrandPickerView.swift`:
   - `.task` que llama a `fetchBrands()`;
   - un `switch` sobre el estado;
   - `List` con un checkmark en la marca de `selection`;
   - un toque asigna `selection` y llama `dismiss()`;
   - `.searchable` y `ContentUnavailableView.search` cuando no hay resultados;
   - `#Preview` con un doble del DataManager.
5. En `ProductFormViewModel`, reemplazar `brandIdText` por `selectedBrand` (precarga, `request`, `Values` y `hasChanges`). Ajustar `ProductFormViewModelTests`:
   - en `.create`, `selectedBrand` es nil y `request` es nil aunque el nombre y el precio sean válidos;
   - en `.edit`, `selectedBrand == product.brand`;
   - al elegir otra marca, `hasChanges` es verdadero y `request.brandId` es el `id` nuevo;
   - al volver a la marca original, `hasChanges` es falso;
   - se eliminan los casos de `brandIdText` ("0", "abc" o vacío).
6. En `ProductFormView`, reemplazar la sección "ID de marca" por la sección "Marca", con un `NavigationLink { BrandPickerView(selection: $viewModel.selectedBrand) } label: { LabeledContent("Marca") { … } }`. Ajustar `PreviewProductsDataManager` si hace falta.

Cada paso deja el proyecto compilando.

---

## Criterios de aceptación

- [ ] El proyecto compila sin errores ni warnings nuevos fuera de `BarcodeScanner`.
- [ ] La URL de ngrok aparece una sola vez en el código, en `APIConfig`.
- [ ] En "Nuevo producto", ya no existe el campo "ID de marca". La fila "Marca" muestra "Seleccionar" en gris.
- [ ] Con nombre y precio válidos y sin marca, "Guardar" está deshabilitado.
- [ ] Tocar "Marca" hace push a "Marca" y muestra un `ProgressView` y después las marcas de `GET /brand`, en el orden del servicio ("Alen" primero).
- [ ] Escribir "nestle" en el buscador deja solo "Nestlé". Escribir "xyz" muestra el estado de sin resultados.
- [ ] Al tocar "Bimbo", se regresa solo al formulario y la fila "Marca" muestra "Bimbo".
- [ ] Al volver a entrar, "Bimbo" tiene el checkmark.
- [ ] Al guardar un producto nuevo con "Bimbo", el servicio recibe `POST /product` con `"brand_id": 4`.
- [ ] En "Editar producto", la fila "Marca" muestra la marca actual del producto sin que se vea un `ProgressView`. Al entrar al selector, esa marca tiene el checkmark.
- [ ] En edición, al elegir otra marca se habilita "Guardar". El servicio recibe `PUT /product/{id}` con el `brand_id` nuevo.
- [ ] En edición, al elegir de nuevo la marca original, "Guardar" vuelve a deshabilitarse.
- [ ] Con el túnel de ngrok apagado, el selector muestra "No se pudieron cargar las marcas" con el botón "Reintentar". Al encender el túnel y tocar "Reintentar", aparecen las marcas.
- [ ] Al regresar del selector sin tocar ninguna marca, la selección no cambia.
- [ ] Las pruebas de `BrandPickerViewModelTests`, `BrandDecodingTests`, `ProductFormViewModelTests`, `ProductListViewModelTests`, `ProductRequestEncodingTests` y `ProductDecodingTests` pasan con `Cmd+U`.
- [ ] Las pruebas de `BarcodeScannerViewModelTests` siguen pasando.
- [ ] Los archivos de `BarcodeScanner`, `MainTabView`, `ProductRowView` y `ProductDetailView` no cambian.

---

## Decisiones tomadas y descartadas

- **Sí:** push a `BrandPickerView` dentro del `NavigationStack` del sheet. Es el patrón de Ajustes de iOS y permite estados de carga, error y búsqueda propios.
- **No:** `Picker(.navigationLink)` nativo. No tiene lugar para la carga, el error y la búsqueda.
- **No:** un segundo `.sheet` sobre el formulario.
- **Sí:** un toque selecciona la marca y regresa solo. **No:** marcar el checkmark y quedarse en el listado.
- **Sí:** `.searchable` con filtro local y las reglas de SPEC 01. Ya hay 21 marcas y el servicio no expone búsqueda.
- **Sí:** el orden del servicio, que ya viene ordenado por nombre. **No:** reordenar en la app.
- **Sí:** cargar cada vez que se abre el selector. Siempre se ven las marcas actuales, y el estado vive en el selector sin acoplarlo al formulario.
- **No:** caché por formulario ni precarga al abrir el sheet.
- **Sí:** en edición, la fila "Marca" usa `product.brand` del producto, sin llamar al servicio.
- **Sí:** feature propia `Features/BrandPicker` con `BrandsEndpoint` y `BrandsDataManager`. Un recurso tiene un solo DataManager (SPEC 04), y la marca es un recurso distinto del producto.
- **No:** agregar `.brands` a `ProductsEndpoint`.
- **Sí:** `APIConfig` compartida para la URL de ngrok y su header. Con dos endpoints, cambiar de túnel sigue siendo editar una línea. Reemplaza la constante en `ProductsEndpoint` de SPEC 03.
- **No:** duplicar la URL en cada endpoint.
- **Sí:** `selectedBrand: Brand?` en lugar de `brandIdText`. La fila necesita el nombre, y el `id` sale del mismo valor. Reemplaza la decisión de SPEC 04 de usar un campo numérico libre.
- **Sí:** `hasChanges` compara el `id` de la marca, igual que `Product` y `Brand` se identifican por `id`.
- **Sí:** `BrandPickerView` recibe un `Binding<Brand?>`. Es la forma mínima de devolver la selección sin compartir ViewModels.
- **Sí:** `LabeledContent` con "Seleccionar" en gris cuando no hay marca, como las filas de Ajustes.
- **Sí:** la marca sigue siendo obligatoria. **No:** opción "Sin marca".
- **Sí:** `ContentUnavailableView.search` cuando el buscador no encuentra nada. Es el estado vacío estándar de `.searchable` y no requiere textos propios.
- **No:** pull to refresh. El error ya tiene "Reintentar", y cada apertura recarga.
- **Sí:** `@MainActor` explícito en `BrandPickerViewModel`, como en SPEC 03 y 04.

---

## Riesgos identificados

| Riesgo | Mitigación |
| --- | --- |
| El `.task` de `BrandPickerView` vuelve a correr si la vista reaparece | Cada apertura crea un `BrandPickerView` nuevo desde el `NavigationLink`, así que recargar es el comportamiento esperado. `fetchBrands()` no repite la llamada si ya está cargando. |
| `.searchable` dentro de un push en un sheet cambia la barra de navegación del formulario | El `.searchable` se aplica solo a `BrandPickerView`. Se verifica en simulador según los criterios. |
| La marca de un producto en edición ya no existe en `GET /brand` | La fila muestra `product.brand.name` y ninguna fila del selector tiene checkmark. Al guardar sin cambiarla, se envía su `id` y el servicio responde. Un error se ve en el alert de SPEC 04. |
| Mover la URL a `APIConfig` rompe `ProductsEndpoint` | El paso 1 hace solo ese cambio y verifica que la lista carga antes de seguir. |
| `objectVersion = 56`: los archivos nuevos no se detectan solos | Cada paso registra sus archivos en `project.pbxproj`. |

---

## Qué **no** está en esta spec

- Crear, editar o eliminar marcas.
- Marca en la fila o en el detalle.
- Opción "Sin marca".
- Pull to refresh o caché de marcas.
- Orden o agrupación propios en la app.
- Cambios de rutas en `ProductsEndpoint`.

Cada uno, si se hace, va en su propia spec.
