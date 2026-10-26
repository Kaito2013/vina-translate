import Foundation

public struct ParagraphBatcher {
    /// Splits multiline text into lines so non-empty lines can be batch-translated
    /// while preserving exact blank lines and whitespace lines upon reassembly.
    public static func splitPreservingStructure(
        _ text: String
    ) -> (nonEmptySegments: [String], reassemble: ([String]) -> String) {
        let rawLines = text.components(separatedBy: "\n")
        var nonEmptyIndices: [Int] = []
        var nonEmptySegments: [String] = []

        for (index, line) in rawLines.enumerated() {
            if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                nonEmptyIndices.append(index)
                nonEmptySegments.append(line)
            }
        }

        let reassemble: ([String]) -> String = { translatedSegments in
            var outputLines = rawLines
            for (offset, originalLineIndex) in nonEmptyIndices.enumerated() {
                if offset < translatedSegments.count {
                    outputLines[originalLineIndex] = translatedSegments[offset]
                }
            }
            return outputLines.joined(separator: "\n")
        }

        return (nonEmptySegments, reassemble)
    }
}
