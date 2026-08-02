package com.sathi.sathi

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sathi.security/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeviceCompromised" -> {
                    val isCompromised = checkDeviceSecurity()
                    result.success(isCompromised)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Check if device is rooted or jailbroken
     * Returns true if device is compromised
     */
    private fun checkDeviceSecurity(): Boolean {
        // Check for common root/jailbreak indicators
        return checkRootApps() || 
               checkSuCommand() || 
               checkDangerousProps() ||
               checkRWPaths() ||
               checkSelinux()
    }

    private fun checkRootApps(): Boolean {
        val rootApps = listOf(
            "com.topjohnwu.magisk",
            "com.saurik.substrate",
            "com.thirdparty.superuser",
            "eu.chainfire.supersu",
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.zhiqupk.root.global"
        )
        
        val packageManager = packageManager
        for (packageName in rootApps) {
            try {
                packageManager.getPackageInfo(packageName, 0)
                return true
            } catch (e: Exception) {
                // Package not found, continue
            }
        }
        return false
    }

    private fun checkSuCommand(): Boolean {
        val paths = listOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        
        for (path in paths) {
            if (File(path).exists()) {
                return true
            }
        }
        return false
    }

    private fun checkDangerousProps(): Boolean {
        try {
            val process = Runtime.getRuntime().exec("getprop ro.debuggable")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val line = reader.readLine()
            reader.close()
            if (line != null && line == "1") {
                return true
            }
        } catch (e: Exception) {
            // Ignore
        }
        return false
    }

    private fun checkRWPaths(): Boolean {
        val paths = listOf(
            "/system/lib",
            "/system/app"
        )
        
        for (path in paths) {
            try {
                val file = File(path)
                if (file.canWrite()) {
                    return true
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
        return false
    }

    private fun checkSelinux(): Boolean {
        try {
            val process = Runtime.getRuntime().exec("getenforce")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val line = reader.readLine()
            reader.close()
            if (line != null && line.lowercase() == "permissive") {
                return true
            }
        } catch (e: Exception) {
            // Ignore
        }
        return false
    }
}
