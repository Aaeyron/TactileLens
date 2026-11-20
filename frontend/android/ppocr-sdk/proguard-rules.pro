-keep class com.paddle.ocr.** { *; }
-keep class ai.onnxruntime.** { *; }
# OpenCV's native code looks this class up by name to report an OpenCV
# error; R8 removed it from release builds as unused.
-keep class org.opencv.core.CvException { *; }
