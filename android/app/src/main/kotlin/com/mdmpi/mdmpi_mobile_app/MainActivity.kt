package com.mdmpi.mobile.app

import android.annotation.SuppressLint
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var smsChannel: MethodChannel? = null
    private var smsReceiver: BroadcastReceiver? = null
    private var nextRequestCode = 1000

    /** Per send id: parts expected, parts reported, first failing result code. */
    private class PendingSms(val parts: Int) {
        var reported = 0
        var failCode: Int? = null
        var errorCode: Int? = null
    }
    private val pendingSms = HashMap<String, PendingSms>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configureSms(flutterEngine)
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

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        smsReceiver?.let { runCatching { unregisterReceiver(it) } }
        smsReceiver = null
        smsChannel?.setMethodCallHandler(null)
        smsChannel = null
        pendingSms.clear()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /**
     * "mdmpi/sms" send {id, to, message}: sends as multipart (one part goes
     * out as a plain SMS) from the default SMS SIM, then calls "sent" back
     * with {id, ok, resultCode, errorCode} once Android has reported every
     * part. Unlike another_telephony, which reports SENT for any callback,
     * this reads the result code, so a failed send is reported as failed.
     */
    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    private fun configureSms(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mdmpi/sms")
        smsChannel = channel
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                val id = intent?.getStringExtra(EXTRA_ID) ?: return
                val sms = pendingSms[id] ?: return
                sms.reported++
                if (resultCode != Activity.RESULT_OK && sms.failCode == null) {
                    sms.failCode = resultCode
                    sms.errorCode = intent.getIntExtra("errorCode", -1)
                        .takeIf { it != -1 }
                }
                if (sms.reported < sms.parts) return
                pendingSms.remove(id)
                smsChannel?.invokeMethod(
                    "sent",
                    mapOf(
                        "id" to id,
                        "ok" to (sms.failCode == null),
                        "resultCode" to (sms.failCode ?: Activity.RESULT_OK),
                        "errorCode" to sms.errorCode,
                    )
                )
            }
        }
        val filter = IntentFilter(ACTION_SMS_PART_SENT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
        smsReceiver = receiver
        channel.setMethodCallHandler { call, result ->
            if (call.method != "send") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val id = call.argument<String>("id")
            val to = call.argument<String>("to")
            val message = call.argument<String>("message")
            if (id.isNullOrEmpty() || to.isNullOrEmpty() || message.isNullOrEmpty()) {
                result.error("ARGS", "id, to and message are required", null)
                return@setMethodCallHandler
            }
            try {
                sendMultipart(id, to, message)
                result.success(null)
            } catch (e: SecurityException) {
                pendingSms.remove(id)
                result.error("PERMISSION", e.message, null)
            } catch (e: Exception) {
                pendingSms.remove(id)
                result.error("SEND_FAILED", e.message, null)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun smsManager(): SmsManager {
        val subId = SmsManager.getDefaultSmsSubscriptionId()
        val base = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(SmsManager::class.java)
        } else {
            SmsManager.getDefault()
        }
        if (subId == SubscriptionManager.INVALID_SUBSCRIPTION_ID) return base
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            base.createForSubscriptionId(subId)
        } else {
            SmsManager.getSmsManagerForSubscriptionId(subId)
        }
    }

    private fun sendMultipart(id: String, to: String, message: String) {
        val manager = smsManager()
        val parts = manager.divideMessage(message)
        if (parts.isEmpty()) throw IllegalArgumentException("Nothing to send")
        val sentIntents = ArrayList<PendingIntent>()
        for (i in parts.indices) {
            val intent = Intent(ACTION_SMS_PART_SENT).apply {
                `package` = packageName
                putExtra(EXTRA_ID, id)
            }
            sentIntents.add(
                PendingIntent.getBroadcast(
                    this,
                    nextRequestCode++,
                    intent,
                    PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
                )
            )
        }
        pendingSms[id] = PendingSms(parts.size)
        manager.sendMultipartTextMessage(to, null, parts, sentIntents, null)
    }

    companion object {
        private const val ACTION_SMS_PART_SENT = "com.mdmpi.mobile.app.SMS_PART_SENT"
        private const val EXTRA_ID = "sms_id"
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
