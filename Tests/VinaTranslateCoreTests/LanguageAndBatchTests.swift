import XCTest
@testable import VinaTranslateCore

final class LanguageAndBatchTests: XCTestCase {
    func testDetectsVietnameseWithDiacriticsEvenForShortWords() {
        XCTAssertEqual(LanguageDetector.detectDirection(for: "Xin chào"), .viToEn)
        XCTAssertEqual(LanguageDetector.detectDirection(for: "Cảm ơn bạn rất nhiều"), .viToEn)
        XCTAssertEqual(LanguageDetector.detectDirection(for: "Ứng dụng dịch thuật nội bộ"), .viToEn)
    }

    func testDetectsEnglishSentenceAsEnToVi() {
        XCTAssertEqual(
            LanguageDetector.detectDirection(for: "Hello, how are you doing today?"),
            .enToVi
        )
        XCTAssertEqual(
            LanguageDetector.detectDirection(for: "Copy content into the app to translate immediately."),
            .enToVi
        )
    }

    func testEmptyOrWhitespaceDefaultsToEnToVi() {
        XCTAssertEqual(LanguageDetector.detectDirection(for: ""), .enToVi)
        XCTAssertEqual(LanguageDetector.detectDirection(for: "   \n\t  "), .enToVi)
    }

    func testParagraphBatcherPreservesBlankLinesAndSpacing() {
        let input = "First paragraph.\n\nSecond paragraph.\n   \nThird paragraph."
        let batch = ParagraphBatcher.splitPreservingStructure(input)
        XCTAssertEqual(batch.nonEmptySegments, [
            "First paragraph.",
            "Second paragraph.",
            "Third paragraph."
        ])

        let translated = batch.reassemble([
            "Đoạn thứ nhất.",
            "Đoạn thứ hai.",
            "Đoạn thứ ba."
        ])
        XCTAssertEqual(translated, "Đoạn thứ nhất.\n\nĐoạn thứ hai.\n   \nĐoạn thứ ba.")
    }
}
