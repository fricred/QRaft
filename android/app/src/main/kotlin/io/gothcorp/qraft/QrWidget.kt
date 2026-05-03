package io.gothcorp.qraft

import android.content.Context
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.Text
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition

/**
 * QRaft home-screen widget (Android).
 *
 * Reads the PNG file path written by the Flutter `home_widget` plugin under
 * the key `qr_widget_image`, then renders the image using Jetpack Glance.
 *
 * The state definition uses [HomeWidgetGlanceStateDefinition] provided by the
 * `home_widget` plugin — this ensures the shared-preference data written by
 * Dart is readable by the Glance composition.
 */
class QrWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                QrWidgetContent()
            }
        }
    }

    @Composable
    private fun QrWidgetContent() {
        val prefs = currentState<HomeWidgetGlanceState>().preferences
        val imagePath = prefs.getString("qr_widget_image", null)

        Box(
            modifier = GlanceModifier.fillMaxSize(),
            contentAlignment = Alignment.Center,
        ) {
            if (imagePath != null) {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                if (bitmap != null) {
                    Image(
                        provider = ImageProvider(bitmap),
                        contentDescription = "QR Code",
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .padding(8.dp),
                    )
                } else {
                    // File exists in prefs but couldn't be decoded
                    FallbackText("Open QRaft to pin a QR")
                }
            } else {
                FallbackText("Open QRaft to pin a QR")
            }
        }
    }

    @Composable
    private fun FallbackText(message: String) {
        Text(text = message)
    }
}
