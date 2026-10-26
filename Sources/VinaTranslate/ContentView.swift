import AppKit
import SwiftUI
@preconcurrency import Translation
import VinaTranslateCore

struct ContentView: View {
    @StateObject private var clipboardMonitor = ClipboardMonitor(autoCaptureEnabled: true)

    @State private var sourceText: String = ""
    @State private var translatedText: String = ""
    @State private var languageMode: LanguageMode = .auto
    @State private var activeDirection: TranslationDirection = .enToVi
    @State private var isPinned: Bool = false
    @State private var isTranslating: Bool = false
    @State private var didCopyFeedback: Bool = false
    @State private var needsLanguageDownload: Bool = false
    @State private var statusMessage: String = "Sẵn sàng (Apple Translation On-Device)"

    @State private var translationConfig: TranslationSession.Configuration?
    @State private var debounceTask: Task<Void, Never>?
    @State private var suppressOnChangeDebounce: Bool = false

    private var wordCount: Int {
        let words = sourceText.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            Divider()
            mainSplitArea
            Divider()
            bottomStatusBar
        }
        .background(WindowAccessor(isPinned: isPinned))
        .frame(minWidth: 720, minHeight: 420)
        .onAppear {
            clipboardMonitor.onExternalCopy = { copiedText in
                applyImmediateInput(copiedText, sourceLabel: "Tự bắt từ Clipboard")
            }
            clipboardMonitor.startMonitoring()
        }
        .onDisappear {
            clipboardMonitor.stopMonitoring()
        }
        .translationTask(translationConfig) { session in
            await performTranslation(using: session)
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "character.bubble.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("VinaTranslate")
                    .font(.system(size: 14, weight: .bold))
            }

            Divider()
                .frame(height: 18)

            Picker("Chế độ", selection: $languageMode) {
                ForEach(LanguageMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 210)
            .onChange(of: languageMode) { _, _ in
                triggerTranslation(immediately: true)
            }

            Button {
                swapDirection()
            } label: {
                HStack(spacing: 5) {
                    Text(activeDirection.shortLabel)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .help("Đảo chiều dịch (⌘⇧S)")
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Spacer()

            Toggle(isOn: $clipboardMonitor.isAutoCaptureEnabled) {
                Label("Tự bắt Copy", systemImage: "doc.on.clipboard")
                    .font(.system(size: 12, weight: .medium))
            }
            .toggleStyle(.button)
            .tint(clipboardMonitor.isAutoCaptureEnabled ? .blue : .secondary)
            .help("Tự động nhận và dịch ngay khi bạn bấm Cmd+C ở bất kỳ ứng dụng nào")

            Toggle(isOn: $isPinned) {
                Label(isPinned ? "Đã ghim nổi" : "Ghim nổi", systemImage: isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12, weight: .medium))
            }
            .toggleStyle(.button)
            .tint(isPinned ? .orange : .secondary)
            .help("Giữ cửa sổ luôn nổi trên cùng (Always on Top)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Main 2-Column Split Area

    private var mainSplitArea: some View {
        HSplitView {
            sourceColumn
                .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
            targetColumn
                .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sourceColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 7, height: 7)
                    Text("VĂN BẢN GỐC · \(activeDirection.sourceTitle)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    if languageMode == .auto && !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Tự nhận diện")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Button {
                    pasteAndTranslateFromClipboard()
                } label: {
                    Label("Dán & Dịch", systemImage: "doc.on.clipboard.fill")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("Dán từ Clipboard và dịch ngay (⌘⇧V)")
                .keyboardShortcut("v", modifiers: [.command, .shift])

                Button {
                    clearAll()
                } label: {
                    Label("Xóa", systemImage: "xmark.circle")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(sourceText.isEmpty && translatedText.isEmpty)
                .help("Xóa toàn bộ nội dung (⌘K)")
                .keyboardShortcut("k", modifiers: [.command])
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            ZStack(alignment: .topLeading) {
                TextEditor(text: $sourceText)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))
                    .onChange(of: sourceText) { _, _ in
                        if suppressOnChangeDebounce {
                            suppressOnChangeDebounce = false
                            return
                        }
                        triggerTranslation(immediately: false)
                    }

                if sourceText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dán (Cmd+V) hoặc gõ văn bản tiếng Anh / tiếng Việt vào đây...")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                        Text("💡 Mẹo: Khi bật 'Tự bắt Copy', bạn chỉ cần bấm Cmd+C ở trình duyệt/tài liệu là ứng dụng tự dịch ngay.")
                            .font(.system(size: 12))
                            .foregroundStyle(.quaternary)
                    }
                    .padding(15)
                    .allowsHitTesting(false)
                }
            }
        }
    }

    private var targetColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("BẢN DỊCH · \(activeDirection.targetTitle)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    if isTranslating {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                    }
                }

                Spacer()

                if needsLanguageDownload {
                    Button {
                        triggerTranslation(immediately: true)
                    } label: {
                        Label("Tải gói ngôn ngữ Anh–Việt", systemImage: "arrow.down.circle.fill")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)
                }

                Button {
                    copyTranslationToClipboard()
                } label: {
                    Label(
                        didCopyFeedback ? "Đã chép!" : "Sao chép",
                        systemImage: didCopyFeedback ? "checkmark.circle.fill" : "doc.on.doc"
                    )
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(didCopyFeedback ? .green : nil)
                .controlSize(.small)
                .disabled(translatedText.isEmpty)
                .help("Sao chép bản dịch vào Clipboard (⌘⇧C)")
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            ZStack(alignment: .topLeading) {
                TextEditor(text: .constant(translatedText))
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))

                if translatedText.isEmpty && !isTranslating {
                    Text("Bản dịch sẽ hiển thị tại đây...")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                        .padding(15)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Bottom Status Bar

    private var bottomStatusBar: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(needsLanguageDownload ? Color.orange : (isTranslating ? Color.blue : Color.green))
                    .frame(width: 7, height: 7)
                Text(statusMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(sourceText.count) ký tự · \(wordCount) từ")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Actions & Translation Pipeline

    private func applyImmediateInput(_ text: String, sourceLabel: String) {
        suppressOnChangeDebounce = true
        sourceText = text
        statusMessage = "\(sourceLabel) — Đang chuẩn bị dịch..."
        triggerTranslation(immediately: true)
    }

    private func pasteAndTranslateFromClipboard() {
        guard let copied = clipboardMonitor.readCurrentString() else {
            statusMessage = "Clipboard hiện đang trống hoặc không chứa văn bản."
            return
        }
        applyImmediateInput(copied, sourceLabel: "Đã dán từ Clipboard")
    }

    private func copyTranslationToClipboard() {
        guard !translatedText.isEmpty else { return }
        clipboardMonitor.copyFromApp(translatedText)
        didCopyFeedback = true
        statusMessage = "Đã sao chép bản dịch vào Clipboard."
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            didCopyFeedback = false
        }
    }

    private func clearAll() {
        debounceTask?.cancel()
        suppressOnChangeDebounce = true
        sourceText = ""
        translatedText = ""
        isTranslating = false
        needsLanguageDownload = false
        statusMessage = "Sẵn sàng (Apple Translation On-Device)"
    }

    private func swapDirection() {
        let newDirection = activeDirection.reversed
        activeDirection = newDirection
        languageMode = (newDirection == .enToVi) ? .enToVi : .viToEn

        if !translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            suppressOnChangeDebounce = true
            sourceText = translatedText
        }
        triggerTranslation(immediately: true)
    }

    private func resolveDirection(for text: String) -> TranslationDirection {
        switch languageMode {
        case .auto:
            return LanguageDetector.detectDirection(for: text)
        case .enToVi:
            return .enToVi
        case .viToEn:
            return .viToEn
        }
    }

    private func triggerTranslation(immediately: Bool) {
        debounceTask?.cancel()

        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translatedText = ""
            isTranslating = false
            statusMessage = "Sẵn sàng (Apple Translation On-Device)"
            return
        }

        let resolvedDirection = resolveDirection(for: sourceText)
        activeDirection = resolvedDirection

        if immediately {
            requestSessionRun(for: resolvedDirection)
        } else {
            debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(280))
                guard !Task.isCancelled else { return }
                let updatedDirection = resolveDirection(for: sourceText)
                activeDirection = updatedDirection
                requestSessionRun(for: updatedDirection)
            }
        }
    }

    private func requestSessionRun(for direction: TranslationDirection) {
        if translationConfig?.source == direction.sourceLanguage &&
            translationConfig?.target == direction.targetLanguage {
            translationConfig?.invalidate()
        } else {
            translationConfig = TranslationSession.Configuration(
                source: direction.sourceLanguage,
                target: direction.targetLanguage
            )
        }
    }

    @MainActor
    private func performTranslation(using session: TranslationSession) async {
        let currentInput = sourceText
        let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let direction = activeDirection
        isTranslating = true
        needsLanguageDownload = false
        statusMessage = "Đang dịch (\(direction.shortLabel))..."

        do {
            let availability = LanguageAvailability()
            let status = await availability.status(
                from: direction.sourceLanguage,
                to: direction.targetLanguage
            )

            switch status {
            case .unsupported:
                isTranslating = false
                statusMessage = "macOS báo chưa hỗ trợ cặp ngôn ngữ \(direction.shortLabel)."
                return
            case .supported:
                statusMessage = "Đang yêu cầu macOS tải gói ngôn ngữ \(direction.shortLabel)..."
                try await session.prepareTranslation()
            case .installed:
                break
            @unknown default:
                break
            }

            let batch = ParagraphBatcher.splitPreservingStructure(currentInput)
            guard !batch.nonEmptySegments.isEmpty else {
                isTranslating = false
                return
            }

            if batch.nonEmptySegments.count == 1 {
                let response = try await session.translate(batch.nonEmptySegments[0])
                guard !Task.isCancelled else { return }
                translatedText = batch.reassemble([response.targetText])
            } else {
                let requests = batch.nonEmptySegments.enumerated().map { index, segment in
                    TranslationSession.Request(
                        sourceText: segment,
                        clientIdentifier: "\(index)"
                    )
                }
                let responses = try await session.translations(from: requests)
                guard !Task.isCancelled else { return }

                var orderedResults = Array(repeating: "", count: batch.nonEmptySegments.count)
                for (fallbackIndex, response) in responses.enumerated() {
                    if let idStr = response.clientIdentifier,
                       let idx = Int(idStr),
                       idx >= 0 && idx < orderedResults.count {
                        orderedResults[idx] = response.targetText
                    } else if fallbackIndex < orderedResults.count {
                        orderedResults[fallbackIndex] = response.targetText
                    }
                }
                translatedText = batch.reassemble(orderedResults)
            }

            isTranslating = false
            needsLanguageDownload = false
            statusMessage = "Đã dịch xong (\(direction.shortLabel) · Apple On-Device)"
        } catch is CancellationError {
            // Cancelled by newer translation request
        } catch {
            isTranslating = false
            needsLanguageDownload = true
            statusMessage = "Cần tải gói ngôn ngữ Tiếng Anh & Tiếng Việt trong Cài đặt macOS (hoặc bấm nút 'Tải gói ngôn ngữ'). Chi tiết: \(error.localizedDescription)"
        }
    }
}
