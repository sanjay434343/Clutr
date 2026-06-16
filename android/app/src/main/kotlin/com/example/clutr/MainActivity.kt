package com.sas.clutr

import android.content.ContentUris
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.clutr.app/storage"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMediaFiles" -> {
                    val files = getMediaFilesFromStorage()
                    result.success(files)
                }
                "getWhatsAppHiddenMedia" -> {
                    val files = getWhatsAppHiddenMedia()
                    result.success(files)
                }
                "moveFile" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val destPath = call.argument<String>("destPath")
                    if (sourcePath != null && destPath != null) {
                        val sourceFile = File(sourcePath)
                        val destFile = File(destPath)
                        try {
                            destFile.parentFile?.mkdirs()
                            sourceFile.copyTo(destFile, overwrite = true)
                            if (sourceFile.delete()) {
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("MOVE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Paths are null", null)
                    }
                }
                "deleteFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        val file = File(path)
                        if (file.exists() && file.delete()) {
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null", null)
                    }
                }
                "scheduleNativeAutoClean" -> {
                    val daysInterval = call.argument<Int>("daysInterval") ?: 0
                    val targetFolders = call.argument<List<String>>("targetFolders") ?: emptyList()
                    
                    val workManager = androidx.work.WorkManager.getInstance(applicationContext)
                    workManager.cancelUniqueWork("AutoCleanWorker")

                    if (daysInterval > 0 || daysInterval == -1) {
                        val data = androidx.work.Data.Builder()
                            .putStringArray("targetFolders", targetFolders.toTypedArray())
                            .build()
                        
                        // -1 implies 30 seconds for testing
                        if (daysInterval == -1) {
                            val request = androidx.work.OneTimeWorkRequest.Builder(AutoCleanWorker::class.java)
                                .setInitialDelay(30, java.util.concurrent.TimeUnit.SECONDS)
                                .setInputData(data)
                                .build()
                            workManager.enqueueUniqueWork("AutoCleanWorker", androidx.work.ExistingWorkPolicy.REPLACE, request)
                        } else {
                            val request = androidx.work.PeriodicWorkRequest.Builder(
                                AutoCleanWorker::class.java,
                                daysInterval.toLong(), java.util.concurrent.TimeUnit.DAYS
                            )
                                .setInputData(data)
                                .build()
                            workManager.enqueueUniquePeriodicWork("AutoCleanWorker", androidx.work.ExistingPeriodicWorkPolicy.REPLACE, request)
                        }
                    }
                    result.success(true)
                }
                "isAppInstalled" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            context.packageManager.getPackageInfo(packageName, 0)
                            result.success(true)
                        } catch (e: android.content.pm.PackageManager.NameNotFoundException) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getMediaFilesFromStorage(): List<Map<String, Any>> {
        val mediaList = mutableListOf<Map<String, Any>>()
        
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.DATE_ADDED
        )

        val selection = (MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
                + " OR "
                + MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO)

        val queryUri = MediaStore.Files.getContentUri("external")
        val sortOrder = "${MediaStore.MediaColumns.DATE_ADDED} DESC"

        contentResolver.query(
            queryUri,
            projection,
            selection,
            null,
            sortOrder
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val pathColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
            val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
            val mimeTypeColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
            val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_ADDED)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                val path = cursor.getString(pathColumn)
                val name = cursor.getString(nameColumn)
                val size = cursor.getLong(sizeColumn)
                val mimeType = cursor.getString(mimeTypeColumn)
                val dateAdded = cursor.getLong(dateColumn)

                val contentUri = ContentUris.withAppendedId(queryUri, id)

                val fileData = mapOf(
                    "id" to id.toString(),
                    "path" to (path ?: ""),
                    "name" to (name ?: ""),
                    "size" to size,
                    "mimeType" to (mimeType ?: ""),
                    "dateAdded" to dateAdded,
                    "uri" to contentUri.toString()
                )
                mediaList.add(fileData)
            }
        }
        
        return mediaList
    }

    private fun getWhatsAppHiddenMedia(): List<Map<String, Any>> {
        val mediaList = mutableListOf<Map<String, Any>>()
        
        val paths = listOf(
            File(android.os.Environment.getExternalStorageDirectory(), "Android/media/com.whatsapp/WhatsApp/Media/.Statuses"),
            File(android.os.Environment.getExternalStorageDirectory(), "WhatsApp/Media/.Statuses")
        )

        for (dir in paths) {
            if (dir.exists() && dir.isDirectory) {
                dir.listFiles()?.forEach { file ->
                    if (file.isFile && !file.name.equals(".nomedia", ignoreCase = true)) {
                        val mimeType = if (file.name.endsWith(".mp4", ignoreCase = true)) "video/mp4" else "image/jpeg"
                        val fileData = mapOf(
                            "id" to file.absolutePath.hashCode().toString(),
                            "path" to file.absolutePath,
                            "name" to file.name,
                            "size" to file.length(),
                            "mimeType" to mimeType,
                            "dateAdded" to file.lastModified() / 1000,
                            "uri" to "file://${file.absolutePath}"
                        )
                        mediaList.add(fileData)
                    }
                }
            }
        }
        
        return mediaList
    }
}
