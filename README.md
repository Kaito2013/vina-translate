# VinaTranslate — Ứng dụng Dịch Anh ⇄ Việt Nội Bộ trên macOS 15+

Ứng dụng dịch thuật macOS siêu nhẹ (Native Swift + SwiftUI), sử dụng trực tiếp bộ máy **Apple Translation (`import Translation`)** và **NaturalLanguage (`NLLanguageRecognizer`)** miễn phí 100%, chạy hoàn toàn Offline trên máy (On-Device).

## Tính năng chính

- **Tự động phát hiện ngôn ngữ (`Auto`):** Dán tiếng Anh tự động dịch sang tiếng Việt; dán tiếng Việt tự động dịch sang tiếng Anh.
- **Tự bắt Copy (`Auto-Clipboard`):** Khi bật nút **Tự bắt Copy**, chỉ cần bôi đen văn bản ở bất kỳ đâu (trình duyệt, PDF, Word, Slack...) và bấm `Cmd + C`, VinaTranslate sẽ tự động lấy nội dung và dịch ngay lập tức.
- **Ghim nổi (`Always on Top`):** Giữ cửa sổ luôn nằm trên cùng để vừa đọc tài liệu vừa đối chiếu bản dịch.
- **Giữ nguyên bố cục đoạn văn:** Dịch theo từng đoạn bằng `TranslationSession.translations(from:)` giúp giữ nguyên các dòng xuống hàng.

## Phím tắt nhanh

| Phím tắt | Chức năng |
| --- | --- |
| `⌘ + ⇧ + V` | Dán từ Clipboard & Dịch ngay |
| `⌘ + ⇧ + C` | Sao chép bản dịch |
| `⌘ + ⇧ + S` | Đảo chiều dịch (`EN ⇄ VI`) |
| `⌘ + K` | Xóa nhanh nội dung |

## Cách biên dịch lại (khi cần chỉnh sửa code)

```bash
cd /Users/hoaiminh/vina-translate
./scripts/bundle-app.sh
```

File ứng dụng sau khi đóng gói sẽ tự động được cài vào:
- `/Applications/VinaTranslate.app`
- `/Users/hoaiminh/vina-translate/build/VinaTranslate.app`
