@echo off
rem Builds the bundled llama.cpp for Android arm64 with the Vulkan GPU backend (plus CPU), as
rem command-line tools for a phone bench (llama-server, llama-mtmd-cli). Bench only: nothing
rem here goes into the app. Output: C:\Projects\Capstone\vl_gguf\android\bin.
rem
rem Needs: Android NDK 28.2.13676358 (installed with the app's toolchain; it has the Vulkan C
rem headers, libvulkan.so and glslc), Vulkan-Headers v1.3.275 (vulkan.hpp, matching the NDK's
rem VK_HEADER_VERSION 275) in C:\Projects\Capstone\vl_gguf\android\Vulkan-Headers, and the VS
rem Build Tools (MSVC builds llama.cpp's host-side shader generator), and SPIRV-Headers
rem vulkan-sdk-1.3.275.0 installed (header-only) in C:\Projects\Capstone\vl_gguf\android\spirv-install.
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
set SDK=%LOCALAPPDATA%\Android\Sdk
set NDK=%SDK%\ndk\28.2.13676358
set CMAKE=%SDK%\cmake\3.22.1\bin\cmake.exe
set NINJA=%SDK%\cmake\3.22.1\bin\ninja.exe
set SRC=C:\Projects\Capstone\TactileLens\frontend\third_party\llama.cpp
set OUT=C:\Projects\Capstone\vl_gguf\android
set BUILD=%OUT%\build_vulkan
set SYSROOT=%NDK%\toolchains\llvm\prebuilt\windows-x86_64\sysroot

rem Host toolchain for vulkan-shaders-gen (runs on this PC during the build).
> "%OUT%\host-msvc.cmake" echo set(CMAKE_C_COMPILER cl)
>> "%OUT%\host-msvc.cmake" echo set(CMAKE_CXX_COMPILER cl)

"%CMAKE%" -S "%SRC%" -B "%BUILD%" -G Ninja -DCMAKE_MAKE_PROGRAM="%NINJA%" ^
  -DCMAKE_TOOLCHAIN_FILE="%NDK%\build\cmake\android.toolchain.cmake" ^
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-28 -DCMAKE_BUILD_TYPE=Release ^
  -DBUILD_SHARED_LIBS=OFF -DGGML_NATIVE=OFF -DGGML_OPENMP=OFF -DGGML_LLAMAFILE=OFF ^
  -DGGML_CPU_ARM_ARCH=armv8.2-a+dotprod+fp16 ^
  -DGGML_VULKAN=ON ^
  -DVulkan_INCLUDE_DIR="%OUT%\Vulkan-Headers\include" ^
  -DVulkan_LIBRARY="%SYSROOT%\usr\lib\aarch64-linux-android\28\libvulkan.so" ^
  -DVulkan_GLSLC_EXECUTABLE="%NDK%\shader-tools\windows-x86_64\glslc.exe" ^
  -DGGML_VULKAN_SHADERS_GEN_TOOLCHAIN="%OUT%\host-msvc.cmake" ^
  -DSPIRV-Headers_DIR="%OUT%\spirv-install\share\cmake\SPIRV-Headers" ^
  -DCMAKE_CXX_FLAGS="-I%OUT:\=/%/spirv-install/include" ^
  -DLLAMA_CURL=OFF -DLLAMA_OPENSSL=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF ^
  -DLLAMA_BUILD_SERVER=ON -DLLAMA_BUILD_TOOLS=ON
if errorlevel 1 exit /b 1
"%CMAKE%" --build "%BUILD%" -j 8 --target llama-server llama-mtmd-cli
if errorlevel 1 exit /b 1
if not exist "%OUT%\bin" mkdir "%OUT%\bin"
copy /y "%BUILD%\bin\llama-server" "%OUT%\bin\" >nul
copy /y "%BUILD%\bin\llama-mtmd-cli" "%OUT%\bin\" >nul
echo BUILD_OK
