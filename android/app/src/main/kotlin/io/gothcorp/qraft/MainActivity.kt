package io.gothcorp.qraft

import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "qraft/deeplink"
    private var startString: String? = null
    private var linksChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // qraft://wifi (scanned dynamic WiFi codes): hand the network to the system.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qraft/wifi").setMethodCallHandler { call, result ->
            when (call.method) {
                "addNetwork" -> result.success(
                    addWifiNetwork(
                        call.argument<String>("ssid") ?: "",
                        call.argument<String>("password") ?: "",
                        call.argument<String>("security") ?: "WPA",
                        call.argument<Boolean>("hidden") ?: false,
                    )
                )
                "openSettings" -> result.success(openWifiSettings())
                else -> result.notImplemented()
            }
        }

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

    /**
     * Android 11+: the system "Save this network?" dialog (ACTION_WIFI_ADD_NETWORKS); one tap
     * saves and connects. Older Android or unsupported security (WEP): WiFi settings instead.
     * Returns "dialog" or "settings" (Flutter copies the password for the settings path).
     */
    private fun addWifiNetwork(ssid: String, password: String, security: String, hidden: Boolean): String {
        if (ssid.isEmpty()) return openWifiSettings()
        val sec = security.uppercase()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && sec != "WEP") {
            try {
                val b = WifiNetworkSuggestion.Builder().setSsid(ssid).setIsHiddenSsid(hidden)
                val open = password.isEmpty() || sec == "NOPASS"
                if (!open) {
                    if (sec == "SAE" || sec == "WPA3") b.setWpa3Passphrase(password) else b.setWpa2Passphrase(password)
                }
                val intent = Intent(Settings.ACTION_WIFI_ADD_NETWORKS)
                intent.putParcelableArrayListExtra(Settings.EXTRA_WIFI_NETWORK_LIST, arrayListOf(b.build()))
                startActivity(intent)
                return "dialog"
            } catch (e: Exception) {
                // Invalid passphrase length etc. → settings fallback.
            }
        }
        return openWifiSettings()
    }

    private fun openWifiSettings(): String {
        return try {
            startActivity(Intent(Settings.ACTION_WIFI_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            "settings"
        } catch (e: Exception) {
            "none"
        }
    }
}
