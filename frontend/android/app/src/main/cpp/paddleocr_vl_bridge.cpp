#include <jni.h>

#include <mutex>
#include <string>

#include "llama.h"
#include "mtmd.h"

namespace {

std::once_flag initialization_flag;
bool runtime_initialized = false;

void initialize_runtime() {
    llama_backend_init();

    // Reference the multimodal API so the mtmd library is linked
    // into the Android PaddleOCR-VL bridge.
    const mtmd_context_params parameters =
        mtmd_context_params_default();

    static_cast<void>(parameters);

    runtime_initialized = true;
}

}  // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeInitialize(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(environment);
    static_cast<void>(instance);

    std::call_once(
        initialization_flag,
        initialize_runtime
    );

    return runtime_initialized ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeRuntimeVersion(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(instance);

    std::call_once(
        initialization_flag,
        initialize_runtime
    );

    const char* version = llama_version();

    return environment->NewStringUTF(
        version == nullptr ? "unknown" : version
    );
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeSystemInformation(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(instance);

    std::call_once(
        initialization_flag,
        initialize_runtime
    );

    const char* information = llama_print_system_info();

    return environment->NewStringUTF(
        information == nullptr
            ? "System information unavailable."
            : information
    );
}