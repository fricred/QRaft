import WidgetKit
import SwiftUI

// ---------------------------------------------------------------------------
// App Group constant — must match QrWidgetService._appGroupId in Dart
// ---------------------------------------------------------------------------

private let kAppGroup = "group.io.gothcorp.qraft"
private let kImageKey = "qr_widget_image"
private let kLabelKey = "qr_label"

// ---------------------------------------------------------------------------
// Timeline entry
// ---------------------------------------------------------------------------

/// A single snapshot of the widget's display state.
struct QRaftEntry: TimelineEntry {
    /// Required by TimelineEntry protocol.
    let date: Date

    /// Absolute file path of the PNG rendered by `home_widget.renderFlutterWidget`.
    /// `nil` when no QR has been pinned yet — shows the fallback prompt.
    let imagePath: String?

    /// Short label saved by QrWidgetService, e.g. a truncated URL.
    let label: String?
}

// ---------------------------------------------------------------------------
// Timeline provider
// ---------------------------------------------------------------------------

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QRaftEntry {
        QRaftEntry(date: Date(), imagePath: nil, label: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (QRaftEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QRaftEntry>) -> Void) {
        // Widgets are refreshed on demand via HomeWidget.updateWidget(); no
        // automatic refresh interval is needed. Use .never to avoid battery
        // drain from polling.
        let timeline = Timeline(entries: [currentEntry()], policy: .never)
        completion(timeline)
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /// Reads the latest QR image path and label from the shared App Group
    /// UserDefaults written by the Flutter `home_widget` plugin.
    private func currentEntry() -> QRaftEntry {
        let defaults = UserDefaults(suiteName: kAppGroup)
        let imagePath = defaults?.string(forKey: kImageKey)
        let label = defaults?.string(forKey: kLabelKey)
        return QRaftEntry(date: Date(), imagePath: imagePath, label: label)
    }
}

// ---------------------------------------------------------------------------
// Widget view
// ---------------------------------------------------------------------------

struct QRaftWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Dark background matching the Carden Pro design system (#1A1A1A)
            Color(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x1A / 255.0)

            if let imagePath = entry.imagePath,
               let uiImage = UIImage(contentsOfFile: imagePath) {
                VStack(spacing: 4) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)

                    if let label = entry.label, !label.isEmpty {
                        Text(label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 6)
                    }
                }
            } else {
                // Fallback when no QR has been pinned yet
                VStack(spacing: 6) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 28))
                        .foregroundColor(Color(red: 0x00 / 255.0, green: 0xFF / 255.0, blue: 0x88 / 255.0))

                    Text("Open QRaft to pin a QR")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Widget configuration
// ---------------------------------------------------------------------------

/// The WidgetKit widget for QRaft.
///
/// `kind` must match the `_iOSWidgetName` constant in
/// `lib/features/qr_digital/domain/services/qr_widget_service.dart`
/// (`"QRaftWidget"`). A mismatch means `HomeWidget.updateWidget` won't
/// refresh the displayed PNG.
struct QRaftWidget: Widget {
    let kind: String = "QRaftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                QRaftWidgetEntryView(entry: entry)
                    .containerBackground(.black, for: .widget)
            } else {
                QRaftWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("QRaft")
        .description("Shows your pinned QR code on the home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
