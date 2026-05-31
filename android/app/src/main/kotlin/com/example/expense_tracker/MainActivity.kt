package com.pulsemoney.finance

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "app.sms/receive"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        SmsBroadcastReceiver.methodChannel = channel

        // Expose methods to fetch and acknowledge pending SMS that were persisted when the
        // Flutter engine wasn't available.
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "fetchPendingSms" -> {
                    try {
                        result.success(SmsBroadcastReceiver.readPendingSms(this))
                    } catch (e: Exception) {
                        result.error("ERR", e.message, null)
                    }
                }
                "ackPendingSms" -> {
                    try {
                        val ids = call.argument<List<String>>("ids") ?: emptyList()
                        SmsBroadcastReceiver.ackPendingSms(this, ids)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR", e.message, null)
                    }
                }
                "clearPendingSms" -> {
                    SmsBroadcastReceiver.clearPendingSms(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        SmsBroadcastReceiver.methodChannel = null
        super.onDestroy()
    }
}
