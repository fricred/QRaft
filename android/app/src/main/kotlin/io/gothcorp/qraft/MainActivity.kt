package io.gothcorp.qraft

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "qraft/deeplink"
    private var startString: String? = null
    private var linksChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        linksChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        linksChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    result.success(startString)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val action: String? = intent?.action
        val data: Uri? = intent?.data

        if (Intent.ACTION_VIEW == action && data != null) {
            startString = data.toString()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        val action: String? = intent.action
        val data: Uri? = intent.data
        
        if (Intent.ACTION_VIEW == action && data != null) {
            linksChannel?.invokeMethod("routeUpdated", data.toString())
        }
    }
}
