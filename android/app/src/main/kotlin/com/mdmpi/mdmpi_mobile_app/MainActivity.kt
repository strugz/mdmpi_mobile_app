package com.mdmpi.mobile.app

import android.content.Context
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mdmpi/sim_info")
            .setMethodCallHandler { call, result ->
                if (call.method == "getDefaultSmsSim") {
                    try {
                        result.success(defaultSmsSim())
                    } catch (e: SecurityException) {
                        result.error("PERMISSION", e.message, null)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    /** The SIM Android sends SMS from when the app passes no subscription id. */
    @Suppress("DEPRECATION")
    private fun defaultSmsSim(): Map<String, Any?> {
        val subscriptions = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE)
            as SubscriptionManager
        val simCount = subscriptions.activeSubscriptionInfoCount
        val subId = SmsManager.getDefaultSmsSubscriptionId()
        val info = if (subId == SubscriptionManager.INVALID_SUBSCRIPTION_ID) null
            else subscriptions.getActiveSubscriptionInfo(subId)
        if (info == null) {
            return mapOf("simCount" to simCount, "hasDefault" to false)
        }
        val number = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            subscriptions.getPhoneNumber(subId)
        } else {
            info.number
        }
        return mapOf(
            "simCount" to simCount,
            "hasDefault" to true,
            "slot" to info.simSlotIndex + 1,
            "carrier" to info.carrierName?.toString(),
            "number" to number,
        )
    }
}
