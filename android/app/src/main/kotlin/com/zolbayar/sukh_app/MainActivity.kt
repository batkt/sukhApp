package com.home.sukh_app

import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sukh_app/vibration"
    private var vibrator: Vibrator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrate" -> {
                    @Suppress("UNCHECKED_CAST")
                    val patternList = call.argument<List<Int>>("pattern") as? List<Int>
                    val repeat = call.argument<Int>("repeat") ?: -1
                    
                    if (vibrator?.hasVibrator() == true) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            // Android 8.0+ (API 26+)
                            if (patternList != null && patternList.isNotEmpty()) {
                                val timings = patternList.map { it.toLong() }.toLongArray()
                                // Use simple waveform without amplitudes for compatibility
                                val vibrationEffect = VibrationEffect.createWaveform(timings, repeat)
                                vibrator?.vibrate(vibrationEffect)
                            } else {
                                // Single gentle vibration - 200ms with default amplitude
                                vibrator?.vibrate(VibrationEffect.createOneShot(300, VibrationEffect.DEFAULT_AMPLITUDE))
                            }
                        } else {
                            // Android 7.1 and below
                            if (patternList != null && patternList.isNotEmpty()) {
                                val timings = patternList.map { it.toLong() }.toLongArray()
                                vibrator?.vibrate(timings, repeat)
                            } else {
                                vibrator?.vibrate(500)
                            }
                        }
                        result.success(true)
                    } else {
                        result.error("NO_VIBRATOR", "Device does not have a vibrator", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
