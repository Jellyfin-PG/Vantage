package com.retrostream.vantage

import android.content.Context
import android.os.Build
import android.view.KeyEvent
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.retrostream.vantage/emulator"
    private var isMappingMode: Boolean = false

    companion object {
        var retroView: com.swordfish.libretrodroid.GLRetroView? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.retrostream.vantage/retro_view",
            RetroViewFactory(this)
        )

        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launch" -> {
                        val romPath  = call.argument<String>("romPath")  ?: return@setMethodCallHandler result.error("MISSING", "romPath required", null)
                        val corePath = call.argument<String>("corePath") ?: return@setMethodCallHandler result.error("MISSING", "corePath required", null)
                        
                        
                        RetroViewFactory.pendingRom  = romPath
                        RetroViewFactory.pendingCore = corePath
                        result.success(null)
                    }
                    "pause"  -> { retroView?.onPause(); result.success(null) }
                    "resume" -> { retroView?.onResume(); result.success(null) }
                    "reset"  -> { retroView?.reset(); result.success(null) }
                    "getAspectRatio" -> {
                        
                        result.success(1.33)
                    }
                    "saveState" -> {
                        val data = retroView?.serializeState()
                        result.success(data)
                    }
                    "loadState" -> {
                        val data = call.argument<ByteArray>("state") ?: return@setMethodCallHandler result.error("MISSING","data required",null)
                        retroView?.unserializeState(data)
                        result.success(true)
                    }
                    "setVolume" -> {
                        
                        val volume = call.arguments as? Double ?: 1.0
                        retroView?.audioEnabled = volume > 0.0
                        result.success(null)
                    }
                    "setFastForward" -> {
                        
                        val enabled = call.arguments as? Boolean ?: false
                        retroView?.frameSpeed = if (enabled) 2 else 1
                        result.success(null)
                    }
                    "setSlowMotion" -> {
                        
                        
                        result.success(null)
                    }
                    "setAnalog" -> {
                        
                        val index = call.argument<Int>("index") ?: 0
                        val id    = call.argument<Int>("id")    ?: 0
                        val value = call.argument<Int>("value") ?: 0
                        val normalized = value / 32767f
                        val source = if (index == 0)
                            com.swordfish.libretrodroid.GLRetroView.MOTION_SOURCE_ANALOG_LEFT
                        else
                            com.swordfish.libretrodroid.GLRetroView.MOTION_SOURCE_ANALOG_RIGHT
                        
                        if (id == 0) {
                            retroView?.sendMotionEvent(source, normalized, 0f, 0)
                        } else {
                            retroView?.sendMotionEvent(source, 0f, normalized, 0)
                        }
                        result.success(null)
                    }
                    "serializeState" -> {
                        val data = retroView?.serializeState()
                        result.success(data)
                    }
                    "unserializeState" -> {
                        val data = call.argument<ByteArray>("data") ?: return@setMethodCallHandler result.error("MISSING","data required",null)
                        retroView?.unserializeState(data)
                        result.success(null)
                    }
                    "keyDown" -> {
                        val keyCode = call.argument<Int>("keyCode") ?: 0
                        retroView?.sendKeyEvent(KeyEvent.ACTION_DOWN, keyCode)
                        result.success(null)
                    }
                    "keyUp" -> {
                        val keyCode = call.argument<Int>("keyCode") ?: 0
                        retroView?.sendKeyEvent(KeyEvent.ACTION_UP, keyCode)
                        result.success(null)
                    }
                    "httpGet" -> {
                        val url   = call.argument<String>("url") ?: return@setMethodCallHandler result.error("MISSING","url",null)
                        val token = call.argument<String>("token") ?: ""
                        Thread {
                            try {
                                val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
                                conn.setRequestProperty("Authorization", "MediaBrowser Token=\"\$token\"")
                                if (conn.responseCode == 404) { result.success(null); return@Thread }
                                val bytes = conn.inputStream.readBytes()
                                result.success(bytes)
                            } catch (e: Exception) { result.error("HTTP_ERROR", e.message, null) }
                        }.start()
                    }
                    "httpPost" -> {
                        val url         = call.argument<String>("url") ?: return@setMethodCallHandler result.error("MISSING","url",null)
                        val token       = call.argument<String>("token") ?: ""
                        val data        = call.argument<ByteArray>("data") ?: ByteArray(0)
                        val contentType = call.argument<String>("contentType") ?: "application/octet-stream"
                        Thread {
                            try {
                                val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
                                conn.requestMethod = "POST"
                                conn.setRequestProperty("Authorization", "MediaBrowser Token=\"\$token\"")
                                conn.setRequestProperty("Content-Type", contentType)
                                conn.doOutput = true
                                conn.outputStream.write(data)
                                if (conn.responseCode !in 200..299) throw Exception("HTTP \${conn.responseCode}")
                                result.success(null)
                            } catch (e: Exception) { result.error("HTTP_ERROR", e.message, null) }
                        }.start()
                    }
                    "setMappingMode" -> {
                        val mode = call.argument<Boolean>("mode") ?: false
                        isMappingMode = mode
                        result.success(null)
                    }
                    "resetMappingMode" -> {
                        isMappingMode = false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (!isMappingMode && retroView?.onKeyDown(keyCode, event) == true) return true
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (!isMappingMode && retroView?.onKeyUp(keyCode, event) == true) return true
        return super.onKeyUp(keyCode, event)
    }

    override fun onGenericMotionEvent(event: android.view.MotionEvent?): Boolean {
        
        
        
        return super.onGenericMotionEvent(event)
    }
}




class RetroViewFactory(private val activity: android.app.Activity) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    companion object {
        var pendingRom:  String? = null
        var pendingCore: String? = null
    }

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return RetroViewWrapper(activity, pendingRom ?: "", pendingCore ?: "")
    }
}

class RetroViewWrapper(
    private val activity: android.app.Activity,
    private val romPath: String,
    private val corePath: String
) : PlatformView {

    private val internalRetroView: com.swordfish.libretrodroid.GLRetroView by lazy {
        val data = com.swordfish.libretrodroid.GLRetroViewData(activity).apply {
            coreFilePath    = corePath
            gameFilePath    = romPath
            shader          = com.swordfish.libretrodroid.GLRetroView.SHADER_SHARP
            systemDirectory = java.io.File(activity.filesDir, "system").also { it.mkdirs() }.absolutePath
            savesDirectory  = java.io.File(activity.filesDir, "saves").also { it.mkdirs() }.absolutePath
        }
        val view = com.swordfish.libretrodroid.GLRetroView(activity, data)
        view.layoutParams = android.widget.FrameLayout.LayoutParams(
            android.view.ViewGroup.LayoutParams.MATCH_PARENT,
            android.view.ViewGroup.LayoutParams.MATCH_PARENT,
            android.view.Gravity.CENTER
        )
        
        
        
        view.isFocusable = false
        view.isFocusableInTouchMode = false
        
        MainActivity.retroView = view

        
        
        if (activity is androidx.lifecycle.LifecycleOwner) {
            activity.lifecycle.addObserver(view)
        }

        view
    }

    override fun getView(): android.view.View = internalRetroView
    override fun dispose() {
        
        if (activity is androidx.lifecycle.LifecycleOwner) {
            activity.lifecycle.removeObserver(internalRetroView)
        }
        internalRetroView.onDestroy()
        if (MainActivity.retroView == internalRetroView) {
            MainActivity.retroView = null
        }
    }
}

