import AppKit
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    var isPinned: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            applyWindowSettings(to: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            applyWindowSettings(to: nsView.window)
        }
    }

    @MainActor
    private func applyWindowSettings(to window: NSWindow?) {
        guard let window else { return }
        let targetLevel: NSWindow.Level = isPinned ? .floating : .normal
        if window.level != targetLevel {
            window.level = targetLevel
        }
        if isPinned {
            window.collectionBehavior.insert(.canJoinAllSpaces)
            window.collectionBehavior.insert(.fullScreenAuxiliary)
        } else {
            window.collectionBehavior.remove(.canJoinAllSpaces)
            window.collectionBehavior.remove(.fullScreenAuxiliary)
        }
    }
}
