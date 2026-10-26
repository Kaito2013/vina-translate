import Foundation
import NaturalLanguage

public enum TranslationDirection: String, CaseIterable, Sendable, Equatable {
    case enToVi
    case viToEn

    public var sourceLanguage: Locale.Language {
        switch self {
        case .enToVi:
            return Locale.Language(identifier: "en")
        case .viToEn:
            return Locale.Language(identifier: "vi")
        }
    }

    public var targetLanguage: Locale.Language {
        switch self {
        case .enToVi:
            return Locale.Language(identifier: "vi")
        case .viToEn:
            return Locale.Language(identifier: "en")
        }
    }

    public var sourceTitle: String {
        switch self {
        case .enToVi:
            return "Tiếng Anh (English)"
        case .viToEn:
            return "Tiếng Việt (Vietnamese)"
        }
    }

    public var targetTitle: String {
        switch self {
        case .enToVi:
            return "Tiếng Việt (Vietnamese)"
        case .viToEn:
            return "Tiếng Anh (English)"
        }
    }

    public var shortLabel: String {
        switch self {
        case .enToVi:
            return "EN → VI"
        case .viToEn:
            return "VI → EN"
        }
    }

    public var reversed: TranslationDirection {
        switch self {
        case .enToVi:
            return .viToEn
        case .viToEn:
            return .enToVi
        }
    }
}

public enum LanguageMode: String, CaseIterable, Sendable, Identifiable {
    case auto
    case enToVi
    case viToEn

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .auto:
            return "Tự động (Auto)"
        case .enToVi:
            return "Anh → Việt (EN → VI)"
        case .viToEn:
            return "Việt → Anh (VI → EN)"
        }
    }
}

public struct LanguageDetector {
    private static let vietnameseSpecificCharacters = CharacterSet(
        charactersIn: "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ" +
                      "ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ"
    )

    public static func detectDirection(for text: String) -> TranslationDirection {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .enToVi
        }

        // Fast & reliable check for Vietnamese-specific diacritics on short or mixed strings
        let viCharCount = trimmed.unicodeScalars.filter { vietnameseSpecificCharacters.contains($0) }.count
        if viCharCount >= 1 {
            let recognizer = NLLanguageRecognizer()
            recognizer.languageConstraints = [.english, .vietnamese]
            recognizer.processString(trimmed)
            let hypotheses = recognizer.languageHypotheses(withMaximum: 2)
            let viScore = hypotheses[.vietnamese] ?? 0
            let enScore = hypotheses[.english] ?? 0
            // Even if short phrase has low NLLanguageRecognizer confidence, presence of Vietnamese diacritics strongly indicates VI
            if viScore >= enScore * 0.6 || trimmed.count <= 40 {
                return .viToEn
            }
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = [.english, .vietnamese]
        recognizer.processString(trimmed)

        if let dominant = recognizer.dominantLanguage, dominant == .vietnamese {
            let hypotheses = recognizer.languageHypotheses(withMaximum: 2)
            let viScore = hypotheses[.vietnamese] ?? 0
            let enScore = hypotheses[.english] ?? 0
            if viScore > enScore {
                return .viToEn
            }
        }

        return .enToVi
    }
}
