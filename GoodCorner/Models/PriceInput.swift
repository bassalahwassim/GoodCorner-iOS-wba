import Foundation

/// Nettoie la saisie d'un prix : chiffres uniquement, un seul séparateur décimal,
/// 2 décimales maximum. Fonctionne aussi pour un texte collé ou un clavier physique.
enum PriceInput {
    static let maxIntegerDigits = 9
    static let maxFractionDigits = 2

    /// Séparateurs acceptés : point, virgule (clavier FR) et virgule décimale arabe.
    private static let separators: Set<Character> = [".", ",", "\u{066B}"]

    static func sanitize(_ input: String) -> String {
        var integerPart = ""
        var fractionPart = ""
        var separator: Character?

        for character in input {
            if let digit = asciiDigit(character) {
                if separator == nil {
                    if integerPart.count < maxIntegerDigits { integerPart.append(digit) }
                } else if fractionPart.count < maxFractionDigits {
                    fractionPart.append(digit)
                }
            } else if separators.contains(character), separator == nil {
                separator = character
            }
            // Tout le reste (lettres, espaces, symboles, signe "-") est ignoré.
        }

        // Pas de zéros inutiles en tête : "007" -> "7".
        while integerPart.count > 1, integerPart.first == "0" {
            integerPart.removeFirst()
        }

        guard let separator else { return integerPart }
        if integerPart.isEmpty { integerPart = "0" }   // "." -> "0."
        return integerPart + String(separator) + fractionPart
    }

    /// Convertit aussi les chiffres arabes-indiens (٠١٢…) en chiffres 0-9.
    private static func asciiDigit(_ character: Character) -> Character? {
        guard
            let value = character.wholeNumberValue,
            character.unicodeScalars.allSatisfy({ $0.properties.generalCategory == .decimalNumber })
        else { return nil }
        return Character(String(value))
    }
}
