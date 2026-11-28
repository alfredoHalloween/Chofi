# SPEC 07 — Rutas de producto bajo `/product`

> **Status:** Implementado
> **Depends on:** SPEC 03, SPEC 04
> **Date:** 2026-11-27
> **Objective:** Alinear `ProductsEndpoint` con la SPEC 12 de msvc-products, cambiando el listado de `GET /` a `GET /product` y fijando con pruebas la ruta y el método de cada caso del enum.

---

## Por qué esta spec

En msvc-products, la SPEC 12 (`specs/12-unificar-rutas-producto.md`) dejó todas las rutas de producto bajo `@RequestMapping("/product")`. Las rutas de la raíz (`GET /`, `GET /{id}`, `GET /barcode/{barcode}`) se eliminaron sin alias y ahora responden 404 `{"message":"Recurso no encontrado"}`.

Chofi sigue pidiendo el listado a `GET /`. Con el servicio actualizado, la app muestra "No se pudieron cargar los productos" al abrirse. `POST /product` y `PUT /product/{id}` ya usaban el prefijo y no cambian. `GET /brand` tampoco cambia.

SPEC 04 ya decía que el listado pasaba a `GET /product`, pero el código de `ProductsEndpoint.products` se quedó en `"/"`.

## Alcance

**Dentro:**

- `ProductsEndpoint.products` cambia su `path` de `"/"` a `"/product"`.
- Los comentarios de los casos de `ProductsEndpoint` se corrigen:
  - `.products` → `GET  /product`;
  - `.create` → `POST /product`;
  - `.update` → `PUT  /product/{id}`.
- Prueba nueva `ChofiTests/ProductsEndpointTests.swift`, que comprueba `path` y `method` de `.products`, `.create` y `.update`.
- Nota en `specs/03-product-list-web-service.md` que remite a SPEC 07. Su estado no cambia.

**Fuera de alcance (para futuras specs):**

- Casos nuevos en `ProductsEndpoint` para `GET /product/{id}`, `GET /product/barcode/{barcode}`, `GET /product/search`, `GET /product/deleted`, `DELETE /product/{id}` o `PATCH /product/{id}/restore`.
- Pruebas de `BrandsEndpoint`.
- Cambiar `APIConfig` (URL base o headers).
- Leer el header `Location` de `POST /product`. Chofi usa el cuerpo de la respuesta.
- Manejar de forma especial el 404 `{"message":"Recurso no encontrado"}`.
- Editar SPEC 04, 05 o 06. Ya documentan `/product`.
- Cambios en el gateway o en msvc-products.

---

## Modelo de datos

Esta feature no introduce estructuras de datos nuevas. Los cuerpos de petición y respuesta son los de SPEC 03 y SPEC 04. Solo cambia la ruta del listado.

Rutas finales de `ProductsEndpoint`:

| Caso | Método | Ruta |
| --- | --- | --- |
| `.products` | `GET` | `/product` |
| `.create(ProductRequest)` | `POST` | `/product` |
| `.update(id:request:)` | `PUT` | `/product/{id}` |

```swift
enum ProductsEndpoint: Endpoint {
    case products                                  // GET  /product
    case create(ProductRequest)                    // POST /product
    case update(id: Int, request: ProductRequest)  // PUT  /product/{id}
    // path de .products: "/product"
}
```

Convenciones:

- Archivo nuevo: `ChofiTests/ProductsEndpointTests.swift`.
- Las rutas siguen la convención de la SPEC 12 de msvc-products: prefijo en singular y el verbo HTTP como acción.

---

## Plan de implementación

Cada paso registra sus archivos nuevos en `project.pbxproj`, dentro del grupo de su carpeta y del target correcto.

1. Crear `ChofiTests/ProductsEndpointTests.swift`. Casos:
   - `.products` tiene `path == "/product"` y `method == .get`;
   - `.create(request)` tiene `path == "/product"` y `method == .post`;
   - `.update(id: 7, request: request)` tiene `path == "/product/7"` y `method == .put`.

   El caso de `.products` falla con el código actual. Es la prueba que guía el paso 2.
2. En `Chofi/Features/ProductList/Services/ProductsEndpoint.swift`, cambiar el `path` de `.products` a `"/product"` y corregir los tres comentarios de los casos. Las pruebas de `ProductsEndpointTests` pasan. Verificar en el simulador, contra el servicio con SPEC 12, que la lista carga.
3. Añadir a `specs/03-product-list-web-service.md`, debajo del encabezado, la nota `> **Nota:** Desde SPEC 07 el listado usa `GET /product`. Las menciones a `GET /` de esta spec quedan como registro histórico.`

Cada paso deja el proyecto compilando.

---

## Criterios de aceptación

- [ ] El proyecto compila sin errores ni warnings nuevos fuera de `BarcodeScanner`.
- [ ] Con msvc-products en la versión de SPEC 12, al abrir la app se ve un `ProgressView` y después la lista de productos.
- [ ] El servicio recibe `GET /product` al cargar el listado, y no `GET /`.
- [ ] Al guardar un producto nuevo, el servicio recibe `POST /product`. Al guardar una edición, recibe `PUT /product/{id}`.
- [ ] El selector de marcas sigue cargando desde `GET /brand`.
- [ ] Con el túnel de ngrok apagado, se ve "No se pudieron cargar los productos" con "Reintentar".
- [ ] `ProductsEndpoint.swift` no contiene `return "/"` ni comentarios con `GET  /` o `PUT  /{id}` sin el prefijo `/product`.
- [ ] Las pruebas de `ProductsEndpointTests`, `ProductListViewModelTests`, `ProductDecodingTests`, `ProductFormViewModelTests`, `ProductRequestEncodingTests`, `CurrencyInputTests`, `BrandPickerViewModelTests` y `BrandDecodingTests` pasan con `Cmd+U`.
- [ ] Las pruebas de `BarcodeScannerViewModelTests` siguen pasando.
- [ ] `specs/03-product-list-web-service.md` tiene la nota que remite a SPEC 07 y conserva el estado `Implementado`.
- [ ] `BrandsEndpoint.swift`, `APIConfig`, `ProductsDataManager.swift` y los archivos de `BarcodeScanner` no cambian.

---

## Decisiones tomadas y descartadas

- **Sí:** solo migrar la ruta del listado. Es lo único que se rompió con la SPEC 12 del servicio.
- **No:** agregar ahora `.product(id:)` o `.byBarcode(_:)`. Ninguna pantalla los usa todavía, y un caso sin uso no tiene criterio de aceptación verificable. Irán en la spec que los necesite.
- **Sí:** `ProductsEndpointTests` con `path` y `method` de cada caso. La ruta del listado divergió del servicio sin que ninguna prueba lo notara. La prueba fija el contrato en un solo lugar.
- **No:** probar `BrandsEndpoint`. `GET /brand` no cambió y no forma parte de esta feature.
- **No:** `MockNetworkClient` para verificar la URL completa. Obligaría a enlazar `NetworkKitMocks` a `ChofiTests`, como ya descartó SPEC 03. Basta con probar `path` y `method`.
- **Sí:** escribir la prueba antes del cambio. El caso de `.products` falla primero y demuestra que la prueba detecta el problema.
- **Sí:** nota en SPEC 03 sin cambiar su estado, como hizo la SPEC 12 de msvc-products con sus SPEC 01, 02 y 05. Conserva el historial y avisa a quien la lea.
- **No:** editar SPEC 04. Ya documenta `GET /product` y registra el cambio de ruta del 2026-11-26.
- **No:** tratar el 404 `"Recurso no encontrado"` aparte. El estado de error con "Reintentar" de SPEC 03 ya lo cubre.

---

## Riesgos identificados

| Riesgo | Mitigación |
| --- | --- |
| Se despliega la app antes que msvc-products con SPEC 12, y `GET /product` no existe | En el servicio anterior, `/product` solo acepta `POST` y `GET /product` responde 405. Se ve el estado de error con "Reintentar". Hay que desplegar primero el servicio. |
| El gateway sigue enrutando solo la raíz | Fuera de este repo. Chofi llama a la URL de ngrok configurada en `APIConfig`. Si apunta al gateway, este debe aceptar `/product`. |
| `objectVersion = 56`: el archivo de prueba nuevo no se detecta solo | El paso 1 lo registra en `project.pbxproj` dentro del target `ChofiTests`. |

---

## Qué **no** está en esta spec

- Casos de detalle, barcode, búsqueda, eliminados, baja o restauración en `ProductsEndpoint`.
- Pruebas de `BrandsEndpoint`.
- Cambios en `APIConfig`.
- Uso del header `Location`.
- Manejo especial del 404.
- Cambios en SPEC 04, 05 o 06, en el gateway o en msvc-products.

Cada uno, si se hace, va en su propia spec.
