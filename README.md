# VinaTranslate — Ứng dụng Dịch Anh ⇄ Việt Nội Bộ cho macOS

Ứng dụng dịch thuật macOS siêu nhẹ (Native Swift + SwiftUI), sử dụng trực tiếp bộ máy **Apple Translation (`import Translation`)** và **NaturalLanguage (`NLLanguageRecognizer`)** chính chủ của Apple:
- **Miễn phí 100%**, không cần API Key, không giới hạn số ký tự hay số lượt dịch.
- **Chạy hoàn toàn Offline trên máy (On-Device)** bằng Apple Neural Engine, bảo mật tuyệt đối dữ liệu nội bộ.
- **Tự động bắt Clipboard (`Auto-Clipboard`)** và **Ghim nổi (`Always on Top`)**: chỉ cần ấn `Cmd + C` ở bất kỳ ứng dụng nào là tự dịch ngay.

---

## 📋 Yêu cầu hệ thống (System Requirements)

- **Hệ điều hành:** macOS 15.0 (Sequoia) trở lên *(vì Apple chỉ mở `Translation` framework từ macOS 15)*.
- **Công cụ biên dịch:** Xcode Command Line Tools (`Swift 6.0+`).
  - Kiểm tra nhanh bằng lệnh:
    ```bash
    sw_vers && swift --version
    ```
  - Nếu máy chưa có Command Line Tools, chạy lệnh sau để cài:
    ```bash
    xcode-select --install
    ```

---

## 🚀 Hướng dẫn Cài đặt (Installation)

### Cách 1: Cài đặt tự động vào `/Applications` chỉ với 1 lệnh (Khuyên dùng)

Mở **Terminal** và chạy:

```bash
git clone git@github.com:kaito2013/vina-translate.git
cd vina-translate
./scripts/bundle-app.sh
```

*(Hoặc nếu dùng HTTPS: `git clone https://github.com/kaito2013/vina-translate.git`)*

Script `./scripts/bundle-app.sh` sẽ tự động:
1. Biên dịch mã nguồn Swift ở chế độ **Release** tối ưu tốc độ.
2. Vẽ và đóng gói bộ Icon chuẩn Retina macOS (`16x16` → `1024x1024` `AppIcon.icns`).
3. Tạo gói ứng dụng hoàn chỉnh, ký ad-hoc (`codesign`) và cài đặt thẳng vào:
   - **`/Applications/VinaTranslate.app`** (hiện trong Launchpad & Spotlight)
   - `./build/VinaTranslate.app`

Sau khi chạy xong, mở ngay ứng dụng bằng lệnh:

```bash
open -a /Applications/VinaTranslate.app
```

---

### Cách 2: Tải gói ngôn ngữ Offline Anh – Việt (Chỉ làm 1 lần đầu tiên)

1. Mở **VinaTranslate** và dán một câu tiếng Anh hoặc tiếng Việt bất kỳ vào khung bên trái.
2. Nếu máy Mac của bạn chưa tải sẵn gói ngôn ngữ **Tiếng Anh & Tiếng Việt** của Apple:
   - Hệ thống macOS sẽ tự bật hộp thoại hỏi tải gói ngôn ngữ về máy, hoặc bạn có thể bấm nút màu cam **"Tải gói ngôn ngữ Anh–Việt"** trên thanh công cụ của app.
   - Ngoài ra, bạn cũng có thể tải thủ công trong: **System Settings (Cài đặt hệ thống) → General (Cài đặt chung) → Language & Region (Ngôn ngữ & Vùng) → Translation Languages (Ngôn ngữ dịch)** → Bật tải về **English** và **Vietnamese**.
3. Sau khi tải xong 1 lần duy nhất, ứng dụng hoạt động **100% Offline** không cần Internet.

---

## ✨ Tính năng & Phím tắt

### Tính năng nổi bật
- **Tự động phát hiện ngôn ngữ (`Auto`):** Tự nhận biết đoạn văn bản bạn vừa copy là tiếng Anh hay tiếng Việt (hỗ trợ chuẩn cả từ ngắn có dấu tiếng Việt như *"Xin chào"*, *"Cảm ơn"*) để tự chọn chiều dịch `EN → VI` hoặc `VI → EN`.
- **Tự bắt Copy (`📋 Tự bắt Copy`):** Khi bật công tắc này, bạn chỉ cần bôi đen chữ ở trình duyệt/PDF/Word/Slack rồi bấm `Cmd + C` — VinaTranslate sẽ tự lấy văn bản và dịch tức thì. *(Có cơ chế chống lặp thông minh: khi bạn bấm nút "Sao chép" bản dịch từ trong app, app sẽ không tự dịch ngược lại).*
- **Ghim nổi (`📌 Ghim nổi`):** Giữ cửa sổ luôn nổi trên cùng (`Always on Top`) và đi theo qua các màn hình làm việc (Spaces).
- **Giữ nguyên bố cục đoạn văn:** Dịch theo từng đoạn bằng `TranslationSession.translations(from:)` giúp giữ nguyên toàn bộ cấu trúc xuống dòng của tài liệu gốc.

### Bảng phím tắt

| Phím tắt | Chức năng |
| --- | --- |
| `⌘ + ⇧ + V` | Dán từ Clipboard & Dịch ngay |
| `⌘ + ⇧ + C` | Sao chép toàn bộ bản dịch vào Clipboard |
| `⌘ + ⇧ + S` | Đảo chiều dịch (`EN ⇄ VI`) và chuyển bản dịch sang ô gốc |
| `⌘ + K` | Xóa nhanh toàn bộ nội dung |

---

## 🛠️ Cấu trúc thư mục & Kiểm thử (Development)

```text
vina-translate/
├── Package.swift                                  # Cấu hình Swift Package (macOS 15+)
├── Sources/
│   ├── VinaTranslateCore/                         # Core logic độc lập (có Unit Tests)
│   │   ├── LanguageDetector.swift                 # Tự động nhận diện Anh / Việt
│   │   ├── ParagraphBatcher.swift                 # Tách/ghép đoạn văn giữ nguyên dòng trống
│   │   └── ClipboardMonitor.swift                 # Theo dõi Pasteboard & chống lặp nội bộ
│   └── VinaTranslate/                             # Giao diện macOS App
│       ├── VinaTranslateApp.swift                 # Điểm khởi chạy ứng dụng & cấu hình Icon
│       ├── ContentView.swift                      # Giao diện 2 cột + Apple TranslationSession
│       └── WindowAccessor.swift                   # Điều khiển cửa sổ Always on Top
├── Tests/
│   └── VinaTranslateCoreTests/                    # Bộ kiểm thử XCTest
└── scripts/
    ├── generate-icon.swift                        # Script CoreGraphics tạo bộ icon Retina
    └── bundle-app.sh                              # Script build Release & đóng gói .app
```

Chạy bộ kiểm thử tự động:

```bash
swift test
```
