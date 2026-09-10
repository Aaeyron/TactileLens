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
}