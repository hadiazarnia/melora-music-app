package com.melora.music.melora_music

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity: AudioServiceActivity() {
    private val CHANNEL = "melora/import"
    private var pendingFileUri: String? = null
    private var pendingFileUris: List<String>? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Handle initial intent
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        when (intent.action) {
            // Open In (VIEW)
            Intent.ACTION_VIEW -> {
                val uri = intent.data
                if (uri != null) {
                    val path = getPathFromUri(uri)
                    if (path != null) {
                        sendToFlutter("importAudioFile", path)
                    } else {
                        sendToFlutter("importAudioFile", uri.toString())
                    }
                }
            }
            
            // Share single file (SEND)
            Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                if (uri != null) {
                    val path = getPathFromUri(uri)
                    if (path != null) {
                        sendToFlutter("importAudioFile", path)
                    } else {
                        sendToFlutter("importAudioFile", uri.toString())
                    }
                }
            }
            
            // Share multiple files (SEND_MULTIPLE)
            Intent.ACTION_SEND_MULTIPLE -> {
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                if (uris != null) {
                    val paths = uris.mapNotNull { uri ->
                        getPathFromUri(uri) ?: uri.toString()
                    }
                    sendToFlutter("importMultipleAudioFiles", paths)
                }
            }
        }
    }

    private fun sendToFlutter(method: String, data: Any) {
        methodChannel?.invokeMethod(method, data)
    }

    private fun getPathFromUri(uri: Uri): String? {
        try {
            if (uri.scheme == "file") {
                return uri.path
            }
            
            if (uri.scheme == "content") {
                val cursor = contentResolver.query(uri, null, null, null, null)
                cursor?.use {
                    if (it.moveToFirst()) {
                        val pathIndex = it.getColumnIndex("_data")
                        if (pathIndex >= 0) {
                            return it.getString(pathIndex)
                        }
                    }
                }
                // Fallback: return content URI as string
                return uri.toString()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}