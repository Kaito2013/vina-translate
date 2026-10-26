import AppKit
import Combine
import Foundation

@MainActor
public protocol PasteboardAdapter: AnyObject {
    var changeCount: Int { get }
    func readString() -> String?
    func writeString(_ text: String)
}

@MainActor
public final class SystemPasteboardAdapter: PasteboardAdapter {
    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public var changeCount: Int {
        pasteboard.changeCount
    }

    public func readString() -> String? {
        pasteboard.string(forType: .string)
    }

    public func writeString(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

@MainActor
public final class ClipboardMonitor: ObservableObject {
    @Published public var isAutoCaptureEnabled: Bool {
        didSet {
            if isAutoCaptureEnabled {
                lastObservedChangeCount = pasteboard.changeCount
                startTimerIfNeeded()
            } else {
                stopTimer()
            }
        }
    }

    public var onExternalCopy: ((String) -> Void)?

    private let pasteboard: PasteboardAdapter
    private var lastObservedChangeCount: Int
    private var lastInternalCopyChangeCount: Int?
    private var timer: Timer?

    public init(
        pasteboard: PasteboardAdapter? = nil,
        autoCaptureEnabled: Bool = false
    ) {
        let resolvedPasteboard = pasteboard ?? SystemPasteboardAdapter()
        self.pasteboard = resolvedPasteboard
        self.isAutoCaptureEnabled = autoCaptureEnabled
        self.lastObservedChangeCount = resolvedPasteboard.changeCount
    }

    public func startMonitoring() {
        lastObservedChangeCount = pasteboard.changeCount
        if isAutoCaptureEnabled {
            startTimerIfNeeded()
        }
    }

    public func stopMonitoring() {
        stopTimer()
    }

    public func readCurrentString() -> String? {
        guard let raw = pasteboard.readString() else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : raw
    }

    public func copyFromApp(_ text: String) {
        pasteboard.writeString(text)
        let newCount = pasteboard.changeCount
        lastInternalCopyChangeCount = newCount
        lastObservedChangeCount = newCount
    }

    public func checkOnce() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastObservedChangeCount else { return }
        lastObservedChangeCount = currentCount

        if let internalCount = lastInternalCopyChangeCount, internalCount == currentCount {
            return
        }

        guard isAutoCaptureEnabled else { return }
        guard let copiedText = readCurrentString() else { return }
        onExternalCopy?(copiedText)
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkOnce()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
