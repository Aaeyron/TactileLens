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