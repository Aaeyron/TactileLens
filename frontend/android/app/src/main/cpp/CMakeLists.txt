cmake_minimum_required(VERSION 3.22.1)

project(
    tactilelens_liblouis
    LANGUAGES C CXX
)

set(
    LIBLOUIS_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../third_party/liblouis"
)

set(
    LIBLOUIS_SOURCE_DIRECTORY
    "${LIBLOUIS_ROOT}/liblouis"
)

# ============================================================
# PaddleOCR-VL llama.cpp runtime
# ============================================================

set(
    LLAMA_CPP_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../third_party/llama.cpp"
)

# Build only the libraries needed by the Android PaddleOCR-VL bridge.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)
set(GGML_CCACHE OFF CACHE BOOL "" FORCE)

set(
    GGML_CPU_ARM_ARCH
    "armv8.2-a+dotprod+fp16"
    CACHE STRING ""
    FORCE
)

set(LLAMA_OPENSSL OFF CACHE BOOL "" FORCE)
set(LLAMA_SUBPROCESS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_COMMON OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_APP OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_MTMD ON CACHE BOOL "" FORCE)

set(MTMD_VIDEO OFF CACHE BOOL "" FORCE)

add_subdirectory(
    "${LLAMA_CPP_ROOT}"
    "${CMAKE_CURRENT_BINARY_DIR}/llama.cpp"
)

# ============================================================
# TactileLens PaddleOCR-VL Android bridge
# ============================================================

set(
    CMAKE_POSITION_INDEPENDENT_CODE
    ON
)

add_library(
    tactilelens_paddleocr_vl
    SHARED
    "paddleocr_vl_bridge.cpp"
)

target_include_directories(
    tactilelens_paddleocr_vl
    PRIVATE
    "${LLAMA_CPP_ROOT}/include"
    "${LLAMA_CPP_ROOT}/tools/mtmd"
)

target_compile_features(
    tactilelens_paddleocr_vl
    PRIVATE
    cxx_std_17
)

target_link_libraries(
    tactilelens_paddleocr_vl
    PRIVATE
    mtmd
    llama
    ggml
    android
    log
)

add_library(
    liblouis


    STATIC

    "${LIBLOUIS_SOURCE_DIRECTORY}/compileTranslationTable.c"
    "${LIBLOUIS_SOURCE_DIRECTORY}/lou_translateString.c"
    "${LIBLOUIS_SOURCE_DIRECTORY}/lou_backTranslateString.c"
    "${LIBLOUIS_SOURCE_DIRECTORY}/commonTranslationFunctions.c"
    "${LIBLOUIS_SOURCE_DIRECTORY}/metadata.c"
    "${LIBLOUIS_SOURCE_DIRECTORY}/pattern.c"
    "${LIBLOUIS_SOURCE_DIRECTORY}/logging.c"
    "${LIBLOUIS_SOURCE_DIRECTORY}/utils.c"
    "${LIBLOUIS_SOURCE_DIRECTORY}/maketable.c"
)

target_include_directories(
    liblouis
    PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
    "${LIBLOUIS_SOURCE_DIRECTORY}"
)

target_compile_definitions(
    liblouis
    PRIVATE
    PACKAGE_VERSION="3.38.0"
    TABLESDIR=""
)

target_compile_options(
    liblouis
    PRIVATE
    -fPIC
    -Wno-unused-parameter
    -Wno-sign-compare
)

add_library(
    tactilelens_liblouis
    SHARED
    "liblouis_bridge.cpp"
)

target_include_directories(
    tactilelens_liblouis
    PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_compile_features(
    tactilelens_liblouis
    PRIVATE
    cxx_std_17
)

target_link_libraries(
    tactilelens_liblouis
    PRIVATE
    liblouis
    android
    log
)