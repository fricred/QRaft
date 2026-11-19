package io.gothcorp.qraft

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import io.gothcorp.qraft.R

/**
 * QRaft home-screen widget (Android).
 *
 * Uses classic AppWidgetProvider + RemoteViews to avoid Kotlin JVM inline
 * compilation issues with Jetpack Glance's CompositionLocal.current accessors.
 *
 * Reads the PNG file path written by the Flutter `home_widget` plugin from
 * SharedPreferences under the key `qr_widget_image`.
 *
 * To activate this widget:
 * 1. The Flutter side calls HomeWidget.updateWidget(androidName: 'QrWidget')
 *    after saving the image path via HomeWidget.saveWidgetData.
 * 2. The user adds the widget from the home screen widget picker.
 */
class QrWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val imagePath = prefs.getString("qr_widget_image", null)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.qr_widget_layout)

            if (imagePath != null) {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.qr_widget_image_view, bitmap)
                    views.setTextViewText(R.id.qr_widget_label, "")
                } else {
                    views.setTextViewText(R.id.qr_widget_label, "Open QRaft to pin a QR")
                }
            } else {
                views.setTextViewText(R.id.qr_widget_label, "Open QRaft to pin a QR")
            }

            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
