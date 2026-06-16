package com.sas.clutr

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class AutoCleanWorker(appContext: Context, workerParams: WorkerParameters) :
    CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        Log.d("AutoCleanWorker", "Starting native background clean...")
        
        val folders = inputData.getStringArray("targetFolders") ?: return Result.success()
        
        var filesDeleted = 0
        var bytesFreed = 0L

        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isTempDelete = prefs.getBoolean("flutter.settings_temp_delete", true)
        
        val trashDir = File(applicationContext.getExternalFilesDir(null), ".clutr_trash")
        if (isTempDelete && !trashDir.exists()) {
            trashDir.mkdirs()
        }

        val registryJson = prefs.getString("flutter.trash_registry", "[]")
        val jsonArray = JSONArray(registryJson ?: "[]")

        for (folderPath in folders) {
            val dir = File(folderPath)
            if (dir.exists() && dir.isDirectory) {
                dir.listFiles()?.forEach { file ->
                    if (file.isFile && !file.name.equals(".nomedia", ignoreCase = true)) {
                        val size = file.length()
                        
                        if (isTempDelete) {
                            val timestamp = System.currentTimeMillis()
                            val destFile = File(trashDir, "${timestamp}_${file.name}")
                            try {
                                file.copyTo(destFile, overwrite = true)
                                if (file.delete()) {
                                    filesDeleted++
                                    bytesFreed += size
                                    
                                    val item = JSONObject()
                                    item.put("originalPath", file.absolutePath)
                                    item.put("trashedPath", destFile.absolutePath)
                                    item.put("deletedAt", timestamp)
                                    jsonArray.put(item)
                                }
                            } catch (e: Exception) {
                                Log.e("AutoCleanWorker", "Failed to move to trash", e)
                            }
                        } else {
                            if (file.delete()) {
                                filesDeleted++
                                bytesFreed += size
                            }
                        }
                    }
                }
            }
        }

        if (isTempDelete && filesDeleted > 0) {
            prefs.edit().putString("flutter.trash_registry", jsonArray.toString()).apply()
        }

        showNotification(filesDeleted, bytesFreed)

        return Result.success()
    }

    private fun showNotification(filesDeleted: Int, bytesFreed: Long) {
        val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "auto_clean_channel"
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Auto Clean", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Notifications for automatic background cleaning"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val mbFreed = bytesFreed / (1024 * 1024)
        val title = "Clutr Auto-Clean Complete"
        val text = "Deleted $filesDeleted files automatically, freeing $mbFreed MB of space!"

        val builder = NotificationCompat.Builder(applicationContext, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Fallback icon
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)

        notificationManager.notify(System.currentTimeMillis().toInt(), builder.build())
    }
}
