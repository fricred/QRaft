package io.gothcorp.qraft

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/**
 * BroadcastReceiver that triggers widget updates.
 *
 * The class name must match the `androidName` passed to
 * `HomeWidget.updateWidget(androidName: 'QrWidgetReceiver')` in
 * `QrWidgetService.pinQrToWidget()`.
 *
 * It must also be declared in `AndroidManifest.xml` with the
 * `android.appwidget.action.APPWIDGET_UPDATE` intent filter and
 * an `@xml/qr_widget_info` provider metadata entry.
 */
class QrWidgetReceiver : HomeWidgetGlanceWidgetReceiver<QrWidget>() {
    override val glanceAppWidget = QrWidget()
}
