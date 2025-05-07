//MainActivity.kt

package com.ath.proximity

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.nfc.NfcAdapter
import android.content.Context
import android.net.wifi.p2p.WifiP2pManager
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "proximity_fallback"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startNFC" -> {
                    val adapter = NfcAdapter.getDefaultAdapter(this)
                    result.success(adapter != null && adapter.isEnabled)
                }
                "startWiFi" -> {
                    val manager = getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
                    result.success(manager != null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
