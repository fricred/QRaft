package io.gothcorp.qraft

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * BroadcastReceiver for QRaft home-screen widget updates.
 * HomeWidgetProvider bridges Flutter's HomeWidget.updateWidget() call
 * to a standard APPWIDGET_UPDATE broadcast that QrWidget.onUpdate() handles.
 */
class QrWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        QrWidget().onUpdate(context, appWidgetManager, appWidgetIds)
    }
}
