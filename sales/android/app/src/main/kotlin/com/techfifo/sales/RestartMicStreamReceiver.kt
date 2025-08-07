package com.techfifo.sales

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase

class RestartMicStreamReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == "android.intent.action.RESTART_MIC_STREAM") {
            
            Log.d("RestartReceiver", "🔄 Boot or custom restart intent received")

            // Initialize Firebase if not already done
            try {
                FirebaseApp.initializeApp(context)
            } catch (e: Exception) {
                Log.w("RestartReceiver", "⚠️ Firebase already initialized or failed: ${e.message}")
            }

            // Check if user is logged in
            val isLoggedIn = Firebase.auth.currentUser != null
            if (isLoggedIn) {
                val serviceIntent = Intent(context, MicStreamService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                Log.d("RestartReceiver", "✅ MicStreamService started after boot")
            } else {
                Log.w("RestartReceiver", "❌ No user logged in; Mic stream not restarted")
            }
        }
    }
}

