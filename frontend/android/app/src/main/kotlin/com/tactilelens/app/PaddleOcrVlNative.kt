package com.tactilelens.app

object PaddleOcrVlNative {
    init {
        System.loadLibrary(
            "tactilelens_paddleocr_vl",
        )
    }

    external fun nativeInitialize(): Boolean

    external fun nativeRuntimeVersion(): String

    external fun nativeSystemInformation(): String

    external fun nativeLoadModels(
        modelPath: String,
        projectorPath: String,
        threadCount: Int,
    ): Boolean

    external fun nativeScanImage(
    imagePath: String,
    prompt: String,
    maximumTokens: Int,
): String

external fun nativeScanTimeMs(): Long

external fun nativeModelsLoaded(): Boolean

external fun nativeModelLoadTimeMs(): Long

    external fun nativeLastError(): String

    external fun nativeUnloadModels(): Boolean
}