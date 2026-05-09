package com.utopiafar.xclean

import android.content.Intent
import android.os.Bundle
import com.utopiafar.xclean.channels.BackgroundChannel
import com.utopiafar.xclean.channels.FileChannel
import com.utopiafar.xclean.channels.PermissionChannel
import com.utopiafar.xclean.utils.DiagnosticLog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * MainActivity for XClean Flutter app.
 *
 * Registers all MethodChannels and the EventChannel required for native Android
 * communication (file operations, permissions, background tasks).
 */
class MainActivity : FlutterActivity() {

    private var fileChannel: FileChannel? = null
    private var permissionChannel: PermissionChannel? = null
    private var backgroundChannel: BackgroundChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        DiagnosticLog.init(applicationContext)
        fileChannel = FileChannel(applicationContext, flutterEngine)
        permissionChannel = PermissionChannel(this, flutterEngine)
        backgroundChannel = BackgroundChannel(this, flutterEngine)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        // Reserved for future permission or activity-result handling
    }

    override fun onResume() {
        super.onResume()
        permissionChannel?.activity = this
    }

    override fun onPause() {
        super.onPause()
        permissionChannel?.activity = null
    }

    override fun onDestroy() {
        fileChannel?.dispose()
        permissionChannel?.dispose()
        backgroundChannel?.dispose()
        super.onDestroy()
    }
}
