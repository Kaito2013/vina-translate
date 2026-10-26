import XCTest
@testable import VinaTranslateCore

@MainActor
final class MockPasteboard: PasteboardAdapter {
    var changeCount: Int = 1
    var currentString: String?

    func readString() -> String? {
        return currentString
    }

    func writeString(_ text: String) {
        currentString = text
        changeCount += 1
    }
}

@MainActor
final class ClipboardMonitorTests: XCTestCase {
    func testExternalCopyTriggersCallbackWhenEnabled() {
        let mock = MockPasteboard()
        mock.currentString = "Initial"
        let monitor = ClipboardMonitor(pasteboard: mock, autoCaptureEnabled: true)

        var capturedTexts: [String] = []
        monitor.onExternalCopy = { text in
            capturedTexts.append(text)
        }

        // Simulate user copying text in Chrome/Word
        mock.writeString("Hello from external app")
        monitor.checkOnce()

        XCTAssertEqual(capturedTexts, ["Hello from external app"])
    }

    func testInternalCopyFromAppDoesNotTriggerExternalCallback() {
        let mock = MockPasteboard()
        let monitor = ClipboardMonitor(pasteboard: mock, autoCaptureEnabled: true)

        var capturedTexts: [String] = []
        monitor.onExternalCopy = { text in
            capturedTexts.append(text)
        }

        // User clicks "Copy Translation" inside VinaTranslate
        monitor.copyFromApp("Xin chào từ ứng dụng")
        monitor.checkOnce()

        XCTAssertTrue(capturedTexts.isEmpty, "Internal copy must not re-trigger translation")
        XCTAssertEqual(mock.readString(), "Xin chào từ ứng dụng")
    }

    func testDisabledAutoCaptureIgnoresExternalCopy() {
        let mock = MockPasteboard()
        let monitor = ClipboardMonitor(pasteboard: mock, autoCaptureEnabled: false)

        var capturedTexts: [String] = []
        monitor.onExternalCopy = { text in
            capturedTexts.append(text)
        }

        mock.writeString("Should be ignored while disabled")
        monitor.checkOnce()

        XCTAssertTrue(capturedTexts.isEmpty)
    }
}
