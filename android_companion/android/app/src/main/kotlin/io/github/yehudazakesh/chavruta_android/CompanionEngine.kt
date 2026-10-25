package io.github.yehudazakesh.chavruta_android

import android.content.Context
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * מנוע ה-Flutter שמריץ את המתאם, ברמת התהליך ולא ברמת המסך.
 *
 * מנוע שנוצר בתוך ה-Activity נהרס איתו, וה-Dart שבו — כלומר המתאם כולו —
 * נעצר. כאן הוא נוצר פעם אחת ונשמר במטמון, והמסך רק מתחבר אליו. כל עוד
 * [CompanionService] רץ, התהליך חי והמתאם ממשיך גם בלי מסך.
 */
object CompanionEngine {
    const val ID = "companion"
    private const val CHANNEL = "chavruta/native"

    fun ensure(context: Context): FlutterEngine {
        FlutterEngineCache.getInstance().get(ID)?.let { return it }
        val app = context.applicationContext
        val engine = FlutterEngine(app)
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "filesDir" -> result.success(app.filesDir.absolutePath)
                    "deviceName" -> result.success(deviceName(app))
                    "startService" -> {
                        CompanionService.start(app)
                        result.success(true)
                    }
                    "stopService" -> {
                        CompanionService.stop(app)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ID, engine)
        return engine
    }

    /** השם שהמשתמש נתן לטלפון בהגדרות, ואם אין — יצרן ודגם. */
    private fun deviceName(context: Context): String {
        if (Build.VERSION.SDK_INT >= 25) {
            val named = Settings.Global.getString(
                context.contentResolver,
                Settings.Global.DEVICE_NAME
            )
            if (!named.isNullOrBlank()) return named
        }
        return "${Build.MANUFACTURER} ${Build.MODEL}".trim()
    }
}
