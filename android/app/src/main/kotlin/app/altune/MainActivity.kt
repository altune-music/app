package app.altune

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
  private val CHANNEL = "altune/battery_settings"
  private val FILE_CHANNEL = "altune/file_provider"
  // packageName reads Context.mBase, which is null during the constructor
  // (the framework attaches the Context after instantiation). A field
  // initializer here NPEs on every launch. Compute it lazily on first use,
  // inside the method channel handler where the activity is attached.
  private val FILE_PROVIDER_AUTHORITY by lazy { "$packageName.fileprovider" }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call, result ->
      when (call.method) {
        "openBatteryOptimizationSettings" -> {
          val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:$packageName")
          }
          startActivity(intent)
          result.success(true)
        }
        "getBatteryOptimizationStatus" -> {
          val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
          result.success(pm.isIgnoringBatteryOptimizations(packageName))
        }
        else -> result.notImplemented()
      }
    }
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_CHANNEL).setMethodCallHandler {
      call, result ->
      when (call.method) {
        "getContentUri" -> {
          val path = call.argument<String>("path")
          if (path == null) {
            result.error("INVALID_PATH", "Path is null", null)
            return@setMethodCallHandler
          }
          val file = File(path)
          if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "File does not exist", null)
            return@setMethodCallHandler
          }
          try {
            val uri = FileProvider.getUriForFile(this, FILE_PROVIDER_AUTHORITY, file)
            result.success(uri.toString())
          } catch (e: Exception) {
            result.error("PROVIDER_ERROR", e.message, null)
          }
        }
        else -> result.notImplemented()
      }
    }
  }
}
