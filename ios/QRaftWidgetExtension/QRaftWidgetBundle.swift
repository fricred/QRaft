import WidgetKit
import SwiftUI

/// Widget bundle entry point for QRaftWidgetExtension.
///
/// This file is the `@main` entry for the Widget Extension target added in
/// Xcode (File → New → Target → Widget Extension, Name: QRaftWidgetExtension).
/// Only a single widget type is registered here in v1.
@main
struct QRaftWidgetBundle: WidgetBundle {
    var body: some Widget {
        QRaftWidget()
    }
}
