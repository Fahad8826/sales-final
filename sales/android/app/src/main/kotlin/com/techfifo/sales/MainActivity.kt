package com.techfifo.sales

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val MIC_CHANNEL = "mic_service_channel"
    private val LOCATION_CHANNEL = "location_service_channel"
    private val PERMISSION_REQUEST_CODE = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestPermissionsIfNeeded()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Microphone stream handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MIC_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startMicStream" -> {
                        if (hasPermission(Manifest.permission.RECORD_AUDIO)) {
                            val intent = Intent(this, MicStreamService::class.java)
                            startServiceBasedOnVersion(intent)
                            result.success("Mic stream started")
                        } else {
                            result.error("PERMISSION_DENIED", "Record audio permission not granted", null)
                        }
                    }

                    "stopMicStream" -> {
                        stopService(Intent(this, MicStreamService::class.java))
                        result.success("Mic stream stopped")
                    }

                    "refresh_offer" -> {
                        val intent = Intent("RESTART_OFFER")
                        sendBroadcast(intent)
                        result.success("Offer refresh broadcast sent")
                    }

                    else -> result.notImplemented()
                }
            }

        // Location service handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLocationService" -> {
                        if (hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)) {
                            val intent = Intent(this, LocationService::class.java)
                            startServiceBasedOnVersion(intent)
                            result.success("Location service started")
                        } else {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                                PERMISSION_REQUEST_CODE
                            )
                            result.error("PERMISSION_DENIED", "Location permission not granted", null)
                        }
                    }

                    "stopLocationService" -> {
                        stopService(Intent(this, LocationService::class.java))
                        result.success("Location service stopped")
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermissionsIfNeeded() {
        val permissions = mutableListOf<String>()
        if (!hasPermission(Manifest.permission.RECORD_AUDIO)) {
            permissions.add(Manifest.permission.RECORD_AUDIO)
        }
 
        if (!hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)) {
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }

        if (permissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }

    private fun startServiceBasedOnVersion(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            if (allGranted) {
                // Optional: you can notify Flutter side here if needed
            }
        }
    }
}
