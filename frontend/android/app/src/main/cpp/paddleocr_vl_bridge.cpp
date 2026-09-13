#include <jni.h>

#include <algorithm>
#include <chrono>
#include <fstream>
#include <mutex>
#include <string>
#include <vector>

#include "llama.h"
#include "mtmd.h"
#include "mtmd-helper.h"

namespace {

std::once_flag initialization_flag;
std::mutex model_mutex;

bool runtime_initialized = false;

llama_model* text_model = nullptr;
llama_context* text_context = nullptr;
mtmd_context* vision_context = nullptr;

std::string loaded_model_path;
std::string loaded_projector_path;
std::string last_error;

int64_t model_load_time_ms = 0;
int64_t scan_time_ms = 0;

void initialize_runtime() {
    llama_backend_init();
    runtime_initialized = true;
}

bool file_exists(const std::string& file_path) {
    if (file_path.empty()) {
        return false;
    }

    std::ifstream file(file_path, std::ios::binary);
    return file.good();
}

std::string read_java_string(JNIEnv* environment, jstring value) {
    if (value == nullptr) {
        return "";
    }

    const char* characters =
        environment->GetStringUTFChars(value, nullptr);

    if (characters == nullptr) {
        return "";
    }

    const std::string result(characters);
    environment->ReleaseStringUTFChars(value, characters);
    return result;
}

void release_models_locked() {
    if (vision_context != nullptr) {
        mtmd_free(vision_context);
        vision_context = nullptr;
    }

    if (text_context != nullptr) {
        llama_free(text_context);
        text_context = nullptr;
    }

    if (text_model != nullptr) {
        llama_model_free(text_model);
        text_model = nullptr;
    }

    loaded_model_path.clear();
    loaded_projector_path.clear();
}

bool models_are_loaded_locked() {
    return text_model != nullptr &&
           text_context != nullptr &&
           vision_context != nullptr;
}

jboolean fail_model_load_locked(
    const std::string& message,
    const std::chrono::steady_clock::time_point& started_at
) {
    release_models_locked();
    last_error = message;
    model_load_time_ms =
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now() - started_at
        ).count();
    return JNI_FALSE;
}

std::string token_to_piece(
    const llama_vocab* vocabulary,
    llama_token token
) {
    std::vector<char> buffer(256);

    int32_t length = llama_token_to_piece(
        vocabulary,
        token,
        buffer.data(),
        static_cast<int32_t>(buffer.size()),
        0,
        false
    );

    if (length < 0) {
        buffer.resize(static_cast<size_t>(-length));
        length = llama_token_to_piece(
            vocabulary,
            token,
            buffer.data(),
            static_cast<int32_t>(buffer.size()),
            0,
            false
        );
    }

    if (length <= 0) {
        return "";
    }

    return std::string(buffer.data(), static_cast<size_t>(length));
}

void fail_scan_locked(
    const std::string& message,
    const std::chrono::steady_clock::time_point& started_at
) {
    last_error = message;
    scan_time_ms =
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now() - started_at
        ).count();
}

}  // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeInitialize(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(environment);
    static_cast<void>(instance);

    std::call_once(initialization_flag, initialize_runtime);
    return runtime_initialized ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeRuntimeVersion(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(instance);
    std::call_once(initialization_flag, initialize_runtime);

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
    std::call_once(initialization_flag, initialize_runtime);

    const char* information = llama_print_system_info();
    return environment->NewStringUTF(
        information == nullptr
            ? "System information unavailable."
            : information
    );
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeLoadModels(
    JNIEnv* environment,
    jobject instance,
    jstring model_path_value,
    jstring projector_path_value,
    jint thread_count
) {
    static_cast<void>(instance);
    std::call_once(initialization_flag, initialize_runtime);

    const std::string model_path =
        read_java_string(environment, model_path_value);
    const std::string projector_path =
        read_java_string(environment, projector_path_value);
    const int threads = std::min(
        8,
        std::max(1, static_cast<int>(thread_count))
    );
    const auto started_at = std::chrono::steady_clock::now();

    std::lock_guard<std::mutex> lock(model_mutex);
    last_error.clear();
    model_load_time_ms = 0;

    if (!runtime_initialized) {
        return fail_model_load_locked(
            "The llama.cpp runtime is not initialized.",
            started_at
        );
    }

    if (!file_exists(model_path)) {
        return fail_model_load_locked(
            "The PaddleOCR-VL text model file was not found.",
            started_at
        );
    }

    if (!file_exists(projector_path)) {
        return fail_model_load_locked(
            "The PaddleOCR-VL multimodal projector file was not found.",
            started_at
        );
    }

    if (models_are_loaded_locked() &&
        loaded_model_path == model_path &&
        loaded_projector_path == projector_path) {
        return JNI_TRUE;
    }

    release_models_locked();

    llama_model_params model_parameters =
        llama_model_default_params();
    model_parameters.n_gpu_layers = 0;

    text_model = llama_model_load_from_file(
        model_path.c_str(),
        model_parameters
    );

    if (text_model == nullptr) {
        return fail_model_load_locked(
            "The PaddleOCR-VL text model could not be loaded.",
            started_at
        );
    }

    llama_context_params context_parameters =
        llama_context_default_params();
    context_parameters.n_ctx = 4096;
    context_parameters.n_batch = 4096;
    context_parameters.n_ubatch = 512;
    context_parameters.n_threads = threads;
    context_parameters.n_threads_batch = threads;
    context_parameters.offload_kqv = false;
    context_parameters.op_offload = false;

    text_context = llama_init_from_model(
        text_model,
        context_parameters
    );

    if (text_context == nullptr) {
        return fail_model_load_locked(
            "The PaddleOCR-VL text context could not be created.",
            started_at
        );
    }

    mtmd_context_params vision_parameters =
        mtmd_context_params_default();
    vision_parameters.use_gpu = false;
    vision_parameters.print_timings = true;
    vision_parameters.n_threads = threads;
    vision_parameters.warmup = false;
    vision_parameters.image_min_tokens = 16;
    vision_parameters.image_max_tokens = 64;
    vision_parameters.batch_max_tokens = 512;

    vision_context = mtmd_init_from_file(
        projector_path.c_str(),
        text_model,
        vision_parameters
    );

    if (vision_context == nullptr) {
        return fail_model_load_locked(
            "The PaddleOCR-VL multimodal projector could not be loaded.",
            started_at
        );
    }

    if (!mtmd_support_vision(vision_context)) {
        return fail_model_load_locked(
            "The loaded PaddleOCR-VL projector does not support images.",
            started_at
        );
    }

    loaded_model_path = model_path;
    loaded_projector_path = projector_path;
    model_load_time_ms =
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now() - started_at
        ).count();
    last_error.clear();
    return JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeScanImage(
    JNIEnv* environment,
    jobject instance,
    jstring image_path_value,
    jstring prompt_value,
    jint maximum_tokens
) {
    static_cast<void>(instance);

    const std::string image_path =
        read_java_string(environment, image_path_value);
    std::string instruction =
        read_java_string(environment, prompt_value);
    const int max_tokens = std::min(
        1024,
        std::max(1, static_cast<int>(maximum_tokens))
    );
    const auto started_at = std::chrono::steady_clock::now();

    std::lock_guard<std::mutex> lock(model_mutex);
    last_error.clear();
    scan_time_ms = 0;

    if (!models_are_loaded_locked()) {
        fail_scan_locked(
            "Load the PaddleOCR-VL models before scanning.",
            started_at
        );
        return environment->NewStringUTF("");
    }

    if (!file_exists(image_path)) {
        fail_scan_locked(
            "The scan image file was not found.",
            started_at
        );
        return environment->NewStringUTF("");
    }

    if (instruction.empty()) {
        instruction = "Formula Recognition:";
    }

    const mtmd_helper_init_opt image_options =
        mtmd_helper_init_opt_default();
    mtmd_helper_bitmap_wrapper image =
        mtmd_helper_bitmap_init_from_file(
            vision_context,
            image_path.c_str(),
            false,
            image_options
        );

    if (image.bitmap == nullptr || image.video_ctx != nullptr) {
        if (image.bitmap != nullptr) {
            mtmd_bitmap_free(image.bitmap);
        }
        if (image.video_ctx != nullptr) {
            mtmd_helper_video_free(image.video_ctx);
        }

        fail_scan_locked(
            "PaddleOCR-VL could not decode the scan image.",
            started_at
        );
        return environment->NewStringUTF("");
    }

    const std::string formatted_prompt =
        std::string("<|begin_of_sentence|>") +
        "You are a helpful assistantUser: " +
        mtmd_default_marker() +
        "\n" + instruction +
        "\nAssistant:\n";

    const mtmd_input_text input_text = {
        formatted_prompt.data(),
        formatted_prompt.size(),
        true,
        true,
    };
    const mtmd_bitmap* bitmaps[] = {image.bitmap};
    mtmd_input_chunks* chunks = mtmd_input_chunks_init();

    if (chunks == nullptr) {
        mtmd_bitmap_free(image.bitmap);
        fail_scan_locked(
            "PaddleOCR-VL could not allocate input chunks.",
            started_at
        );
        return environment->NewStringUTF("");
    }

    const int32_t tokenize_result = mtmd_tokenize(
        vision_context,
        chunks,
        &input_text,
        bitmaps,
        1
    );
    mtmd_bitmap_free(image.bitmap);

    if (tokenize_result != 0) {
        mtmd_input_chunks_free(chunks);
        fail_scan_locked(
            "PaddleOCR-VL could not tokenize the image prompt.",
            started_at
        );
        return environment->NewStringUTF("");
    }

    llama_memory_clear(llama_get_memory(text_context), true);

    llama_pos n_past = 0;
    const int32_t evaluation_result = mtmd_helper_eval_chunks(
        vision_context,
        text_context,
        chunks,
        0,
        0,
        static_cast<int32_t>(llama_n_batch(text_context)),
        true,
        &n_past
    );
    mtmd_input_chunks_free(chunks);

    if (evaluation_result != 0) {
        fail_scan_locked(
            "PaddleOCR-VL failed while encoding the scan image.",
            started_at
        );
        return environment->NewStringUTF("");
    }

    const llama_vocab* vocabulary =
        llama_model_get_vocab(text_model);
    llama_sampler* sampler = llama_sampler_init_greedy();

    if (vocabulary == nullptr || sampler == nullptr) {
        if (sampler != nullptr) {
            llama_sampler_free(sampler);
        }
        fail_scan_locked(
            "PaddleOCR-VL could not start text generation.",
            started_at
        );
        return environment->NewStringUTF("");
    }

    std::string output;

    for (int index = 0; index < max_tokens; ++index) {
        llama_token token = llama_sampler_sample(
            sampler,
            text_context,
            -1
        );
        llama_sampler_accept(sampler, token);

        if (llama_vocab_is_eog(vocabulary, token)) {
            break;
        }

        output += token_to_piece(vocabulary, token);

        llama_batch batch = llama_batch_get_one(&token, 1);
        if (llama_decode(text_context, batch) != 0) {
            llama_sampler_free(sampler);
            fail_scan_locked(
                "PaddleOCR-VL failed while generating OCR text.",
                started_at
            );
            return environment->NewStringUTF("");
        }

        ++n_past;
    }

    llama_sampler_free(sampler);
    llama_synchronize(text_context);

    scan_time_ms =
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now() - started_at
        ).count();

    if (output.empty()) {
        last_error = "PaddleOCR-VL returned an empty OCR result.";
        return environment->NewStringUTF("");
    }

    last_error.clear();
    return environment->NewStringUTF(output.c_str());
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeScanTimeMs(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(environment);
    static_cast<void>(instance);

    std::lock_guard<std::mutex> lock(model_mutex);
    return static_cast<jlong>(scan_time_ms);
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeModelsLoaded(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(environment);
    static_cast<void>(instance);

    std::lock_guard<std::mutex> lock(model_mutex);
    return models_are_loaded_locked() ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeModelLoadTimeMs(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(environment);
    static_cast<void>(instance);

    std::lock_guard<std::mutex> lock(model_mutex);
    return static_cast<jlong>(model_load_time_ms);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeLastError(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(instance);

    std::lock_guard<std::mutex> lock(model_mutex);
    return environment->NewStringUTF(
        last_error.empty() ? "" : last_error.c_str()
    );
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_tactilelens_app_PaddleOcrVlNative_nativeUnloadModels(
    JNIEnv* environment,
    jobject instance
) {
    static_cast<void>(environment);
    static_cast<void>(instance);

    std::lock_guard<std::mutex> lock(model_mutex);
    release_models_locked();
    last_error.clear();
    model_load_time_ms = 0;
    scan_time_ms = 0;
    return JNI_TRUE;
}
