package com.tactilelens.app

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val LIBLOUIS_CHANNEL =
            "com.tactilelens.app/liblouis"
    }

    private val mainHandler =
        Handler(Looper.getMainLooper())

    private val liblouisExecutor: ExecutorService =
        Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine,
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LIBLOUIS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    runLiblouisTask(result) {
                        LiblouisNative.initialize(
                            applicationContext,
                        )

                        mapOf(
                            "success" to true,
                            "version" to
                                LiblouisNative.runtimeVersion(),
                        )
                    }
                }

                "translateBlock" -> {
                    val content =
                        call.argument<String>("content")
                            ?.trim()
                            .orEmpty()

                    val isFormula =
                        call.argument<Boolean>("isFormula")
                            ?: false

                    val isTable =
                        call.argument<Boolean>("isTable")
                            ?: false

                    runLiblouisTask(result) {
                        val translation =
                            LiblouisNative.translateBlock(
                                context =
                                    applicationContext,
                                content = content,
                                isFormula = isFormula,
                                isTable = isTable,
                            )

                        mapOf(
                            "success" to
                                translation.success,
                            "code" to translation.code,
                            "content" to
                                translation.content,
                            "error" to translation.error,
                        )
                    }
                }

                "version" -> {
                    runLiblouisTask(result) {
                        mapOf(
                            "version" to
                                LiblouisNative.runtimeVersion(),
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun runLiblouisTask(
        result: MethodChannel.Result,
        operation: () -> Any?,
    ) {
        liblouisExecutor.execute {
            try {
                val value = operation()

                mainHandler.post {
                    result.success(value)
                }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error(
                        "LIBLOUIS_ERROR",
                        error.message
                            ?: "Offline Braille translation failed.",
                        null,
                    )
                }
            }
        }
    }

    override fun onDestroy() {
        liblouisExecutor.shutdown()
        super.onDestroy()
    }
}