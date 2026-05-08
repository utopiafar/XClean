package com.utopiafar.xclean.channels

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.ContextCompat
import androidx.core.content.PermissionChecker
import com.utopiafar.xclean.engine.RootFileEngine
import com.utopiafar.xclean.engine.ShizukuFileEngine
import com.utopiafar.xclean.utils.RomUtils
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel handler for permission-related operations.
 *
 * Channel: com.utopiafar.xclean/permission
 */
class PermissionChannel(
    private val context: Context,
    flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.utopiafar.xclean/permission"
        private const val STATUS_GRANTED = "granted"
        private const val STATUS_DENIED = "denied"
        private const val STATUS_PARTIAL = "partial"
    }

    /**
     * The host [Activity], set/unset in [MainActivity] lifecycle callbacks.
     * Used when an [Activity] context is required to launch settings screens.
     */
    var activity: Activity? = null

    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPermissionStatus" -> result.success(getPermissionStatus())
            "requestAllFilesAccess" -> result.success(requestAllFilesAccess())
            "openAppSettings" -> result.success(openAppSettings())
            "getRomType" -> result.success(RomUtils.getRomType())
            "isBatteryOptimizationIgnored" -> result.success(isBatteryOptimizationIgnored())
            "requestIgnoreBatteryOptimization" -> result.success(requestIgnoreBatteryOptimization())
            "isShizukuAvailable" -> result.success(ShizukuFileEngine.isAvailable())
            "isRootAvailable" -> result.success(RootFileEngine.isAvailable())
            else -> result.notImplemented()
        }
    }

    /**
     * Returns the current all-files access permission status.
     *
     * On Android 11+ (API 30+): checks [Environment.isExternalStorageManager].
     * On older versions: checks legacy READ/WRITE_EXTERNAL_STORAGE grants.
     */
    private fun getPermissionStatus(): String {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                if (Environment.isExternalStorageManager()) STATUS_GRANTED else STATUS_DENIED
            }

            else -> {
                val readGranted = ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.READ_EXTERNAL_STORAGE
                ) == PermissionChecker.PERMISSION_GRANTED
                val writeGranted = ContextCompat.checkSelfPermission(
                    context,
                    android.Manifest.permission.WRITE_EXTERNAL_STORAGE
                ) == PermissionChecker.PERMISSION_GRANTED

                when {
                    readGranted && writeGranted -> STATUS_GRANTED
                    readGranted || writeGranted -> STATUS_PARTIAL
                    else -> STATUS_DENIED
                }
            }
        }
    }

    /**
     * Opens the system settings page that grants "All files access" permission.
     *
     * Returns true if an intent could be formed; the actual grant result must
     * be observed by the Flutter side after the user returns to the app.
     */
    private fun requestAllFilesAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            // Not required on pre-Android 11 when legacy storage is active.
            return true
        }

        return try {
            val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION).apply {
                data = Uri.parse("package:${context.packageName}")
            }
            // If the package-specific URI is unsupported on this device,
            // fall back to the plain intent.
            val resolvedIntent = if (intent.resolveActivity(context.packageManager) != null) {
                intent
            } else {
                Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
            }

            activity?.startActivity(resolvedIntent)
                ?: context.startActivity(resolvedIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Opens the app's detail page in system settings.
     */
    private fun openAppSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity?.startActivity(intent)
                ?: context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Checks whether the app is currently ignoring battery optimizations.
     */
    private fun isBatteryOptimizationIgnored(): Boolean {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            ?: return false
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    /**
     * Requests the user to ignore battery optimizations for this app.
     */
    private fun requestIgnoreBatteryOptimization(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
            }
            activity?.startActivity(intent)
                ?: context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: Exception) {
            false
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
