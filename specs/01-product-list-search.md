# SPEC 01 — Listado de productos con buscador por nombre

> **Status:** Aprobado
> **Depends on:** Ninguna
> **Date:** 2026-10-29
> **Objective:** Mostrar, dentro de un `TabView`, un listado MVVM de productos de una tienda de abarrotes con nombre, precio y placeholder de imagen, filtrable en vivo por nombre y con navegación push al tocar una celda.

---

## Alcance

**Dentro:**

- Modelo `Product` con `name`, `price` e `imageURL`.
- Catálogo local en memoria con datos de ejemplo (unos 15 productos de abarrotes).
- Pantalla `ProductListView` con una fila por producto: placeholder de imagen, nombre y precio.
- Buscador con `.searchable` que filtra en vivo por nombre, sin distinguir mayúsculas ni acentos, por subcadena.
- `ProductListViewModel` (`ObservableObject`) con `searchText` y `filteredProducts`.
- `MainTabView`: un `TabView` como pantalla raíz con una sola pestaña, "Productos" (ícono `cart`), que contiene el listado.
- Navegación tipo navigation controller: al tocar una celda se hace push (`NavigationStack` + `NavigationLink(value:)`) a `ProductDetailView`.
- `ProductDetailView` mínima: placeholder de imagen grande, nombre y precio, con botón de regreso nativo.
- Pruebas unitarias del filtrado en `ChofiTests`.
- Reemplazar `ContentView` por `MainTabView` como pantalla raíz en `ChofiApp`.

**Fuera de alcance (para futuras specs):**

- Cargar la imagen desde `imageURL` (por ahora solo se muestra el placeholder).
- Fuente de datos remota (API), JSON en el bundle o persistencia.
- Estados de carga, error, catálogo vacío o "sin resultados" (con un filtro sin coincidencias la lista queda vacía).
- Otras pestañas (carrito, perfil, etc.) y contenido enriquecido en el detalle (descripción, stock, acciones).
- Carrito, categorías, stock, ordenamiento.
- Altas, bajas o edición de productos.

---

## Modelo de datos

```swift
struct Product: Identifiable, Hashable {
    let id: UUID
    let name: String
    let price: Decimal      // en pesos mexicanos (MXN)
    let imageURL: URL?      // guardada pero aún no se usa para renderizar
}
```

Convenciones:

- El precio se muestra con `price.formatted(.currency(code: "MXN"))`, p. ej. `$32.50`.
- `imageURL` es opcional; la UI no la lee en esta spec.
- Datos de ejemplo en `Product.samples` (`static let`), definidos en `Chofi/Models/Product+Samples.swift`.

```swift
final class ProductListViewModel: ObservableObject {
    @Published var searchText = ""
    private let products: [Product]
    var filteredProducts: [Product] { /* filtra por name con searchText */ }
}
```

- Texto vacío o solo espacios devuelve todos los productos.
- La comparación usa `range(of:options:)` con `.caseInsensitive` y `.diacriticInsensitive`.

---

## Plan de implementación

1. Crear `Chofi/Models/Product.swift` con el struct `Product`.
2. Crear `Chofi/Models/Product+Samples.swift` con `Product.samples`.
3. Crear `Chofi/ViewModels/ProductListViewModel.swift` con `searchText` y `filteredProducts`. Prueba: `ChofiTests/ProductListViewModelTests.swift` con los casos de filtrado.
4. Crear `Chofi/Views/ProductRowView.swift` (placeholder, nombre, precio) con su `#Preview`.
5. Crear `Chofi/Views/ProductDetailView.swift` (placeholder grande, nombre, precio).
6. Crear `Chofi/Views/ProductListView.swift` con `NavigationStack`, `List` de `NavigationLink(value:)`, `.navigationDestination(for: Product.self)` hacia `ProductDetailView` y `.searchable(text:)` ligado al ViewModel.
7. Crear `Chofi/Views/MainTabView.swift` con un `TabView` y la pestaña "Productos" que aloja `ProductListView`.
8. Cambiar `ChofiApp` para mostrar `MainTabView` y eliminar `Chofi/ContentView.swift`.
9. Registrar todos los archivos nuevos en `Chofi.xcodeproj` (targets `Chofi` y `ChofiTests`) y verificar que compila y corre en simulador.

Cada paso deja el proyecto compilando.

---

## Criterios de aceptación

- [ ] El proyecto compila sin errores ni warnings nuevos para iOS 16 en simulador.
- [ ] Al abrir la app se muestra la lista completa de `Product.samples`.
- [ ] Al abrir la app se ve una barra de pestañas con una pestaña "Productos" que contiene el listado.
- [ ] Tocar una celda hace push a `ProductDetailView` con el nombre y el precio de ese producto.
- [ ] El botón "atrás" de la barra de navegación regresa al listado conservando el texto de búsqueda.
- [ ] La barra de pestañas sigue visible en el detalle.
- [ ] Cada fila muestra un placeholder de imagen, el nombre y el precio con formato MXN (`$32.50`).
- [ ] Ninguna fila intenta cargar `imageURL` (no hay tráfico de red).
- [ ] Escribir "arroz" en el buscador deja solo los productos cuyo nombre contiene "arroz".
- [ ] Escribir "JABON" encuentra "Jabón" (insensible a mayúsculas y acentos).
- [ ] Una subcadena intermedia (p. ej. "ech" para "Leche") encuentra el producto.
- [ ] Borrar el texto de búsqueda restaura la lista completa.
- [ ] Un texto sin coincidencias deja la lista vacía sin crashear.
- [ ] Las pruebas de `ProductListViewModelTests` pasan con `Cmd+U`.
- [ ] `Chofi/ContentView.swift` ya no existe.

---

## Decisiones tomadas y descartadas

- **Sí:** catálogo local en memoria. Es lo mínimo para validar la pantalla sin red ni persistencia.
- **No:** API remota o JSON en el bundle. Añaden estados de carga y error; van en otra spec.
- **Sí:** `price` como `Decimal` con formato MXN. Evita imprecisión de `Double` en dinero.
- **No:** `Double` ni `String` ya formateado para el precio.
- **Sí:** `imageURL` en el modelo aunque no se use. El contrato de datos queda listo para la spec de imágenes.
- **Sí:** arquitectura MVVM (el usuario escribió "MMVM"; se interpreta como MVVM) con `ObservableObject`, porque el target es iOS 16 y no admite `@Observable`.
- **Sí:** filtro en vivo, insensible a mayúsculas y acentos, por subcadena. Es lo esperado en un buscador de tienda.
- **No:** búsqueda por prefijo ni al presionar "buscar".
- **Sí:** solo el estado "lista con productos". El usuario no pidió estado vacío ni "sin resultados".
- **Sí:** `TabView` raíz con una sola pestaña. El usuario pidió el listado embebido en un tab view y no definió otras pestañas.
- **Sí:** push con `NavigationStack` (equivalente SwiftUI de navigation controller) y `NavigationLink(value:)`, que aprovecha que `Product` es `Hashable`.
- **Sí:** `ProductDetailView` mínima, porque el push necesita un destino. El usuario no definió su contenido; se limita a lo que ya existe en el modelo.
- **No:** `NavigationView` (obsoleto) ni `UINavigationController` vía UIKit.
- **Sí:** `NavigationStack` dentro de la pestaña, no alrededor del `TabView`, para que la barra de pestañas permanezca visible al hacer push.
- **Sí:** `.searchable` nativo. Evita construir una barra de búsqueda propia.

---

## Riesgos identificados

| Riesgo | Mitigación |
| --- | --- |
| `objectVersion = 56` en el proyecto: los archivos nuevos no se detectan solos | El paso 7 los registra en `project.pbxproj`, o se crean desde Xcode con los targets marcados. |
| `Product.samples` con `UUID()` genera ids nuevos en cada acceso | Declararlo como `static let` para que los ids sean estables. |
| `.searchable` requiere un contenedor de navegación para verse en iOS 16 | Envolver la lista en `NavigationStack`. |

---

## Qué **no** está en esta spec

- Carga real de imágenes desde `imageURL`.
- API, JSON o persistencia de productos.
- Estados de carga, error, vacío o "sin resultados".
- Otras pestañas ni contenido enriquecido en el detalle.
- Carrito, categorías, stock u ordenamiento.
- Edición del catálogo.

Cada uno, si se hace, va en su propia spec.
