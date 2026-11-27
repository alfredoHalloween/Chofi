# SPEC 06 — Campo de precio con formato de moneda

> **Status:** Implementado
> **Depends on:** SPEC 04, SPEC 05
> **Date:** 2026-11-26
> **Objective:** Cambiar el campo "Precio" de `ProductFormView` a una entrada tipo caja registradora que solo acepta dígitos y muestra el monto formateado en MXN (`$1,250.50`), con un máximo de $999,999.99.

---

## Alcance

**Dentro:**

- Entrada tipo caja registradora. Cada dígito entra por los centavos: `2` → `$0.02`, `28` → `$0.28`, `2850` → `$28.50`.
- Borrar quita el último dígito: `$28.50` → `$2.85`.
- El campo muestra el monto con símbolo `$`, separador de miles y siempre 2 decimales, en MXN / `es_MX` fijo (el mismo formato que `formattedPrice`).
- Sin dígitos, el texto queda vacío y se ve el placeholder `$0.00`. El precio es inválido y "Guardar" se deshabilita.
- Los caracteres que no son dígitos se descartan, al escribir y al pegar. Pegar `$28.50` da `$28.50`. Pegar `abc` no cambia el campo.
- Máximo 8 dígitos ($999,999.99). Una tecla que lo excedería se ignora y el campo conserva el valor anterior.
- Los ceros a la izquierda no cuentan: con el campo vacío, escribir `0` lo deja vacío.
- El teclado cambia de `.decimalPad` a `.numberPad`.
- La utilidad pura `CurrencyInput` en `Chofi/Shared/Formatting/CurrencyInput.swift` convierte texto ↔ centavos ↔ `Decimal`.
- En `ProductFormViewModel`, `priceText: String` se reemplaza por `priceCents: Int`:
  - `0` significa vacío;
  - en edición se precarga desde `product.price`;
  - `request` usa `Decimal` a partir de los centavos;
  - `hasChanges` compara centavos.
- Se eliminan el regex de `parsedPrice` y el parámetro `locale` del `init` de `ProductFormViewModel`.
- Pruebas en `ChofiTests` de `CurrencyInput` y los ajustes de `ProductFormViewModelTests`.

**Fuera de alcance (para futuras specs):**

- Interpretar un texto pegado como monto (`28.5` → `$28.50`). Pegar `28.5` da `$2.85`.
- Formatear según el locale del dispositivo o con otras monedas.
- Montos negativos o cero como precio válido.
- Usar `CurrencyInput` en otras pantallas.
- Cambiar `formattedPrice`, `ProductRowView` o `ProductDetailView`.
- Mover el cursor dentro del campo para editar dígitos intermedios.
- Cambiar los campos de código de barras, nombre o marca.

---

## Modelo de datos

```swift
/// Entrada de dinero tipo caja registradora, en MXN / es_MX.
enum CurrencyInput {
    static let maxCents = 99_999_999                 // $999,999.99

    /// Texto que se muestra: "" si cents == 0, si no "$1,250.50".
    static func text(fromCents cents: Int) -> String

    /// Centavos a partir de lo que escribió o pegó el usuario.
    /// Descarta lo que no es dígito y los ceros a la izquierda.
    /// Regresa nil si excede maxCents, para que el campo conserve el valor anterior.
    static func cents(from text: String) -> Int?

    static func decimal(fromCents cents: Int) -> Decimal   // 2850 → 28.50
    static func cents(from decimal: Decimal) -> Int        // 28.5 → 2850, redondeo .plain a 2 decimales
}
```

En `ProductFormViewModel`:

```swift
var priceCents = 0               // reemplaza priceText; 0 = vacío
// Values guarda priceCents: Int en lugar de priceText
init(mode: ProductFormMode,
     dataManager: ProductsDataManagerProtocol = ProductsDataManager())   // sin locale
// parsedPrice: priceCents > 0 ? CurrencyInput.decimal(fromCents:) : nil
```

En `ProductFormView`, el campo usa un `@State private var priceText: String` con `.onChange`:

- `priceText` se inicializa con `CurrencyInput.text(fromCents: viewModel.priceCents)`;
- en `.onChange(of: priceText)`, los centavos son `CurrencyInput.cents(from:)`, o el valor anterior si es nil;
- se asignan a `viewModel.priceCents` y `priceText` se reescribe con el texto formateado.

Convenciones:

- Archivos nuevos:
  - `Chofi/Shared/Formatting/CurrencyInput.swift`;
  - `ChofiTests/CurrencyInputTests.swift`.
- El formato usa `.currency(code: "MXN").locale(Locale(identifier: "es_MX"))` con `precision(.fractionLength(2))`.
- Textos: el placeholder es `$0.00` y la sección sigue llamándose "Precio".

---

## Plan de implementación

Cada paso registra sus archivos nuevos en `project.pbxproj`, dentro del grupo de su carpeta y del target correcto.

1. Crear `Chofi/Shared/Formatting/CurrencyInput.swift`. Prueba: `ChofiTests/CurrencyInputTests.swift`. Casos:
   - `text(fromCents: 0)` es `""`, `2` es `"$0.02"`, `2850` es `"$28.50"`, `125050` es `"$1,250.50"` y `99_999_999` es `"$999,999.99"`;
   - `cents(from: "$28.50")` es `2850`, `"abc"` es `0` y `""` es `0`;
   - `cents(from: "$0.005")` es `5`, por los ceros a la izquierda;
   - `cents(from: "$999,999.990")` es nil, porque excede el máximo;
   - `decimal(fromCents: 2850) == Decimal(string: "28.50")`;
   - `cents(from: Decimal(string: "28.5")!)` es `2850`;
   - `cents(from: Decimal(string: "28.555")!)` es `2856`.
2. En `ProductFormViewModel`:
   - reemplazar `priceText` por `priceCents` (precarga, `Values`, `currentValues` y `parsedPrice`);
   - quitar el parámetro `locale` y el regex.

   Ajustar `ProductFormViewModelTests`:
   - se quita `locale: mexico` de la fábrica;
   - los `priceText = "28.50"` pasan a `priceCents = 2850`;
   - en `.create`, `priceCents` es `0`;
   - en `.edit`, con un producto de precio `32.5`, `priceCents` es `3250`;
   - con `priceCents = 0`, `request` es nil;
   - con `priceCents = 2850`, `request.price == Decimal(string: "28.50")`;
   - en edición, cambiar el precio y regresar a los centavos originales deja `hasChanges` en falso;
   - se eliminan los casos de `priceText` "0", "12.345" y "12a", y el de locale `es_MX`.
3. En `ProductFormView`, cambiar el `TextField` de "Precio":
   - el placeholder pasa a `"$0.00"`;
   - el texto usa el `Binding<String>` calculado;
   - el teclado pasa a `.numberPad`.

   Verificar en el simulador con los criterios de aceptación.

Cada paso deja el proyecto compilando.

---

## Criterios de aceptación

- [ ] El proyecto compila sin errores ni warnings nuevos fuera de `BarcodeScanner`.
- [ ] En "Nuevo producto", el campo "Precio" está vacío y muestra el placeholder `$0.00`. El teclado no tiene punto decimal.
- [ ] Escribir `2`, `8`, `5`, `0` muestra en orden `$0.02`, `$0.28`, `$2.85` y `$28.50`.
- [ ] Escribir `125050` muestra `$1,250.50`.
- [ ] Con `$28.50`, borrar un carácter muestra `$2.85`. Borrar hasta el final deja el campo vacío con el placeholder.
- [ ] Con el campo vacío, escribir `0` lo deja vacío.
- [ ] Con `$999,999.99`, escribir otro dígito no cambia el campo.
- [ ] Pegar `$28.50` muestra `$28.50`. Pegar `abc` no cambia el campo.
- [ ] Con nombre y marca válidos y el precio vacío, "Guardar" está deshabilitado. Con `$28.50`, se habilita.
- [ ] Al guardar un producto nuevo con `$28.50`, el servicio recibe `POST /product` con `"price": 28.5`. La lista muestra `$28.50`.
- [ ] En "Editar producto" con un producto de precio `32.5`, el campo muestra `$32.50` y "Guardar" está deshabilitado.
- [ ] En edición, cambiar el precio habilita "Guardar". Regresar al precio original lo deshabilita otra vez.
- [ ] `priceText` y el parámetro `locale` ya no existen en `ProductFormViewModel`.
- [ ] Las pruebas de `CurrencyInputTests`, `ProductFormViewModelTests`, `ProductRequestEncodingTests`, `ProductDecodingTests`, `ProductListViewModelTests`, `BrandPickerViewModelTests` y `BrandDecodingTests` pasan con `Cmd+U`.
- [ ] Las pruebas de `BarcodeScannerViewModelTests` siguen pasando.
- [ ] Los archivos de `BarcodeScanner`, `BrandPicker`, `MainTabView`, `ProductRowView`, `ProductDetailView` y `Product.swift` no cambian.

---

## Decisiones tomadas y descartadas

- **Sí:** entrada tipo caja registradora. Es imposible escribir un valor inválido, y siempre hay 2 decimales. Es el patrón de las apps bancarias.
- **No:** escritura libre con formato en vivo. Hay que manejar el separador decimal, el tercer decimal y el cursor.
- **No:** formatear solo al salir del campo. Mientras se escribe, el texto sigue siendo ambiguo.
- **Sí:** `$` y separador de miles dentro del campo, con MXN / `es_MX` fijo. El usuario ve lo mismo que en la lista. Reemplaza la decisión de SPEC 04 de interpretar el precio con el locale del dispositivo.
- **No:** el locale del dispositivo. El símbolo y los separadores no coincidirían con `formattedPrice`.
- **Sí:** máximo de $999,999.99 (8 dígitos). Sobra para productos de tienda y evita desbordes. Una tecla extra se ignora.
- **Sí:** vacío con placeholder `$0.00`. **No:** el texto `$0.00` fijo. Así un campo sin precio se distingue de uno con precio.
- **Sí:** descartar lo que no es dígito, también al pegar. Es simple y predecible.
- **No:** interpretar el texto pegado como monto. Agrega lógica y casos para un uso poco común.
- **Sí:** `priceCents: Int` en el ViewModel. Separa el estado (centavos) de la presentación (texto), y `hasChanges` compara enteros.
- **No:** mantener `priceText` formateado con `didSet`. Mezcla presentación y estado.
- **Sí:** `CurrencyInput` como `enum` puro en `Chofi/Shared/Formatting/`, con pruebas propias. Se puede reutilizar sin acoplarlo al formulario.
- **No:** dejar la lógica dentro de `ProductFormViewModel`.
- **Sí:** un `@State` de texto en la vista que se reescribe formateado desde `.onChange`. Así SwiftUI actualiza el campo mientras se escribe.
- **No:** un `Binding<String>` calculado (`get` formatea desde `priceCents`). Era la decisión original, pero en el simulador el campo solo se formateaba al salir de él. SwiftUI no reemplaza el texto de un `TextField` en edición cuando el `get` regresa otro valor.
- **No:** un `FormatStyle` con `TextField(value:format:)`. Ese solo confirma el valor al salir del campo, como ya se descartó en SPEC 04.
- **Sí:** quitar `locale` del `init` de `ProductFormViewModel`. Ya no se interpreta texto con locale.
- **Sí:** en edición, un precio con más de 2 decimales se redondea con `.plain` a centavos. El servicio usa centavos de MXN.
- **Sí:** `.numberPad`. Sin punto decimal, el teclado solo ofrece lo que el campo acepta.

---

## Riesgos identificados

| Riesgo | Mitigación |
| --- | --- |
| Al reformatear el texto, SwiftUI deja el cursor en una posición rara o el `TextField` no refleja el valor corregido cuando se ignora una tecla | Ocurrió con el `Binding` calculado. Se resolvió reescribiendo un `@State` desde `.onChange`, que siempre deja el texto formateado de `priceCents`, también cuando se rechaza una tecla. Se verifica en el simulador con los criterios de "máximo" y "pegar `abc`". |
| El borrado elimina un carácter de formato (`,` o `$`) en lugar de un dígito | `cents(from:)` reextrae los dígitos del texto completo. Borrar `$` o `,` deja los mismos dígitos, y el campo se ve igual. Se verifica en el simulador. Si molesta, se trata en otra spec. |
| `Decimal` → centavos con un precio del servidor que tiene más de 2 decimales | Redondeo `.plain`, cubierto por la prueba `28.555` → `2856`. |
| `objectVersion = 56`: los archivos nuevos no se detectan solos | Cada paso registra sus archivos en `project.pbxproj`. |

---

## Qué **no** está en esta spec

- Interpretar el texto pegado como monto.
- Locale del dispositivo u otras monedas.
- Precios negativos o en cero.
- `CurrencyInput` en otras pantallas.
- Cambios en `formattedPrice`, la fila o el detalle.
- Edición de dígitos intermedios con el cursor.

Cada uno, si se hace, va en su propia spec.
