package com.pulsemoney.finance

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class SmsBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "PulseMoneySms"
        private const val MAX_PENDING_SMS = 100
        private const val MAX_BODY_CHARS = 2000
        var methodChannel: MethodChannel? = null
        const val PREFS_NAME = "sms_prefs"
        const val KEY_PENDING = "pending_sms"
        private val amountPattern = Regex(
            """(?i)(?:rs\.?|inr|₹)\s*[0-9][0-9,]*(?:\.[0-9]{1,2})?|\b[0-9][0-9,]*(?:\.[0-9]{1,2})?\s*(?:rs\.?|inr)\b"""
        )
        private val transactionPattern = Regex(
            """(?i)\b(?:debited?|credited?|spent|paid|withdrawn|received|refund|emi|upi|imps|neft|rtgs|transfer|txn|transaction|a/c|acct|account|card|balance|available)\b"""
        )
        private val financialSenderPattern = Regex(
            """(?i)(?:bank|bnk|hdfc|icici|sbi|axis|kotak|yes|idfc|indus|union|boi|bob|canara|paytm|phonepe|gpay|upi|cred|card)"""
        )
        private val nonFinancialSensitivePattern = Regex(
            """(?i)\b(?:otp|one\s*time\s*password|verification\s*code|login\s*code|password\s*reset|authenticate)\b"""
        )

        fun shouldQueueSms(sender: String, body: String): Boolean {
            val hasAmount = amountPattern.containsMatchIn(body)
            val hasTransactionSignal = transactionPattern.containsMatchIn(body)
            val hasFinancialSender = financialSenderPattern.containsMatchIn(sender)

            if (!hasAmount) return false
            if (nonFinancialSensitivePattern.containsMatchIn(body) && !hasTransactionSignal) {
                return false
            }

            return hasTransactionSignal || hasFinancialSender
        }

        @Synchronized
        fun readPendingSms(context: Context): List<Map<String, Any>> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val array = JSONArray(prefs.getString(KEY_PENDING, "[]") ?: "[]")
            val list = mutableListOf<Map<String, Any>>()

            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)
                list.add(
                    mapOf(
                        "id" to item.optString("id"),
                        "sender" to item.optString("sender"),
                        "body" to item.optString("body"),
                        "timestamp" to item.optLong("timestamp"),
                    )
                )
            }

            return list
        }

        @Synchronized
        fun ackPendingSms(context: Context, ids: List<String>) {
            if (ids.isEmpty()) return

            val processedIds = ids.toSet()
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existing = JSONArray(prefs.getString(KEY_PENDING, "[]") ?: "[]")
            val remaining = JSONArray()

            for (i in 0 until existing.length()) {
                val item = existing.getJSONObject(i)
                if (!processedIds.contains(item.optString("id"))) {
                    remaining.put(item)
                }
            }

            prefs.edit().putString(KEY_PENDING, remaining.toString()).apply()
        }

        @Synchronized
        fun clearPendingSms(context: Context) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .remove(KEY_PENDING)
                .apply()
        }

        @Synchronized
        private fun persistSms(context: Context, payload: Map<String, Any>): Boolean {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existing = JSONArray(prefs.getString(KEY_PENDING, "[]") ?: "[]")
            val id = payload["id"] as String

            for (i in 0 until existing.length()) {
                if (existing.getJSONObject(i).optString("id") == id) {
                    return false
                }
            }

            val item = JSONObject()
            item.put("id", id)
            item.put("sender", payload["sender"])
            item.put("body", (payload["body"] as String).take(MAX_BODY_CHARS))
            item.put("timestamp", payload["timestamp"])

            val bounded = JSONArray()
            val keepFrom = (existing.length() - (MAX_PENDING_SMS - 1)).coerceAtLeast(0)
            for (i in keepFrom until existing.length()) {
                bounded.put(existing.getJSONObject(i))
            }
            bounded.put(item)

            prefs.edit().putString(KEY_PENDING, bounded.toString()).apply()
            return true
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val appContext = context?.applicationContext ?: return
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return

        var queuedAny = false

        for (sms in messages) {
            val body = sms.messageBody ?: continue
            val sender = sms.originatingAddress ?: ""
            if (!shouldQueueSms(sender, body)) {
                Log.d(TAG, "Ignored SMS without transaction signals")
                continue
            }
            val timestamp = sms.timestampMillis
            val id = "${sender}_${timestamp}_${body.hashCode()}"

            val payload = mapOf(
                "id" to id,
                "sender" to sender,
                "body" to body,
                "timestamp" to timestamp,
            )

            queuedAny = persistSms(appContext, payload) || queuedAny
        }

        if (queuedAny) {
            Log.d(TAG, "Queued ${messages.size} SMS message(s) for processing")
            methodChannel?.invokeMethod("onSmsQueued", null)
        } else {
            Log.d(TAG, "SMS broadcast received with no new messages to queue")
        }
    }
}
