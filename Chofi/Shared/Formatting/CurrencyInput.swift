//
//  CurrencyInput.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import Foundation

/// Entrada de dinero tipo caja registradora, en MXN / es_MX.
///
/// Cada dígito entra por los centavos: `2` → `$0.02`, `28` → `$0.28`, `2850` → `$28.50`.
enum CurrencyInput {
    /// $999,999.99
    static let maxCents = 99_999_999

    private static let maxDigits = String(maxCents).count

    private static let style = Decimal.FormatStyle.Currency(code: "MXN")
        .locale(Locale(identifier: "es_MX"))
        .precision(.fractionLength(2))

    /// Texto que se muestra: `""` si `cents == 0`, si no `"$1,250.50"`.
    static func text(fromCents cents: Int) -> String {
        guard cents > 0 else { return "" }
        return decimal(fromCents: cents).formatted(style)
    }

    /// Centavos a partir de lo que escribió o pegó el usuario.
    /// Descarta lo que no es dígito y los ceros a la izquierda.
    /// Regresa `nil` si excede `maxCents`, para que el campo conserve el valor anterior.
    static func cents(from text: String) -> Int? {
        let digits = text
            .filter(\.isASCIIDigit)
            .drop(while: { $0 == "0" })

        guard !digits.isEmpty else { return 0 }
        // Revisar la longitud antes de convertir evita desbordar `Int` con textos largos pegados.
        guard digits.count <= maxDigits, let cents = Int(digits), cents <= maxCents else { return nil }
        return cents
    }

    /// `2850` → `28.50`
    static func decimal(fromCents cents: Int) -> Decimal {
        Decimal(cents) / 100
    }

    /// `28.5` → `2850`. Redondea con `.plain` a 2 decimales.
    static func cents(from decimal: Decimal) -> Int {
        var scaled = decimal * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }
}

private extension Character {
    /// Solo `0`–`9`. `isNumber` también acepta dígitos de otros sistemas (p. ej. `٣`).
    var isASCIIDigit: Bool {
        isASCII && isNumber
    }
}
