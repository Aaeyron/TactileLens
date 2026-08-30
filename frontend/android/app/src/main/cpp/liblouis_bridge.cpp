#include <jni.h>

#include <algorithm>
#include <mutex>
#include <string>
#include <vector>

#include "liblouis.h"

namespace {

std::mutex translationMutex;

void throwJavaException(
    JNIEnv* environment,
    const char* message
) {
    jclass exceptionClass = environment->FindClass(
        "java/lang/IllegalStateException"
    );

    if (exceptionClass != nullptr) {
        environment->ThrowNew(
            exceptionClass,
            message
        );
    }
}

}  // namespace

extern "C"
JNIEXPORT jstring JNICALL
Java_com_tactilelens_app_LiblouisNative_translateNative(
    JNIEnv* environment,
    jobject,
    jstring tableList,
    jstring sourceText
) {
    if (tableList == nullptr || sourceText == nullptr) {
        throwJavaException(
            environment,
            "The Liblouis table list and source text are required."
        );

        return nullptr;
    }

    const jsize sourceLength =
        environment->GetStringLength(sourceText);

    if (sourceLength == 0) {
        return environment->NewStringUTF("");
    }

    const char* nativeTableList =
        environment->GetStringUTFChars(
            tableList,
            nullptr
        );

    if (nativeTableList == nullptr) {
        return nullptr;
    }

    const jchar* nativeSourceText =
        environment->GetStringChars(
            sourceText,
            nullptr
        );

    if (nativeSourceText == nullptr) {
        environment->ReleaseStringUTFChars(
            tableList,
            nativeTableList
        );

        return nullptr;
    }

    static_assert(
        sizeof(widechar) == sizeof(jchar),
        "TactileLens requires the 16-bit Liblouis widechar build."
    );

    int inputLength =
        static_cast<int>(sourceLength);

    const int outputCapacity = std::max(
        1024,
        inputLength * 16 + 256
    );

    int outputLength = outputCapacity;

    std::vector<widechar> inputBuffer(
        static_cast<std::size_t>(inputLength)
    );

    std::vector<widechar> outputBuffer(
        static_cast<std::size_t>(outputCapacity)
    );

    for (int index = 0; index < inputLength; index++) {
        inputBuffer[static_cast<std::size_t>(index)] =
            static_cast<widechar>(nativeSourceText[index]);
    }

    int translationSucceeded = 0;

    {
        const std::lock_guard<std::mutex> lock(
            translationMutex
        );

        translationSucceeded = lou_translateString(
            nativeTableList,
            inputBuffer.data(),
            &inputLength,
            outputBuffer.data(),
            &outputLength,
            nullptr,
            nullptr,
            0
        );
    }

    environment->ReleaseStringChars(
        sourceText,
        nativeSourceText
    );

    environment->ReleaseStringUTFChars(
        tableList,
        nativeTableList
    );

    if (translationSucceeded == 0) {
        throwJavaException(
            environment,
            "Liblouis could not translate the supplied content."
        );

        return nullptr;
    }

    return environment->NewString(
        reinterpret_cast<const jchar*>(
            outputBuffer.data()
        ),
        static_cast<jsize>(outputLength)
    );
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_tactilelens_app_LiblouisNative_versionNative(
    JNIEnv* environment,
    jobject
) {
    const char* version = lou_version();

    if (version == nullptr) {
        return environment->NewStringUTF("unknown");
    }

    return environment->NewStringUTF(version);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_tactilelens_app_LiblouisNative_releaseNative(
    JNIEnv*,
    jobject
) {
    const std::lock_guard<std::mutex> lock(
        translationMutex
    );

    lou_free();
}