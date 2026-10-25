package io.github.yehudazakesh.chavruta_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder

/**
 * שירות חזית שאינו עושה דבר מלבד להחזיק את התהליך חי.
 *
 * כשאוצריא בחזית, אנדרואיד (14 ומעלה) מקפיא תוך שניות אפליקציה שירדה
 * לרקע — והמתאם מפסיק לשמוע את המחשב ולענות לתוסף. שירות חזית עם התראה
 * קבועה הוא הדרך המוצהרת לומר למערכת שהעבודה הזאת נמשכת.
 */
class CompanionService : Service() {
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager?
        multicastLock = wifi?.createMulticastLock("chavruta")?.apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    // אין טעם להקים את השירות מחדש לבד: בלי המנוע אין מתאם שהוא מחזיק.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_NOT_STICKY

    override fun onDestroy() {
        multicastLock?.let { if (it.isHeld) it.release() }
        multicastLock = null
        super.onDestroy()
    }

    private fun buildNotification(): Notification {
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE
        )
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "מתאם חברותא",
                    NotificationManager.IMPORTANCE_LOW
                )
            )
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("מתאם חברותא פועל")
            .setContentText("מסנכרן עם אוצריא במחשב")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(open)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "companion"
        private const val NOTIFICATION_ID = 1

        fun start(context: Context) {
            val intent = Intent(context, CompanionService::class.java)
            if (Build.VERSION.SDK_INT >= 26) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, CompanionService::class.java))
        }
    }
}
