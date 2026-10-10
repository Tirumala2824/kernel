# LiteRT-LM 0.18.0 ships no consumer ProGuard rules. Its JNI library
# (liblitertlm_jni.so) calls back into Kotlin classes such as
# LiteRtLmJni$JniMessageCallback and constructs LiteRtLmJniException by name,
# so R8 must not rename or strip anything in the package.
-keep class com.google.ai.edge.litertlm.** { *; }
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
# Tool calling (ReflectionTool) is never used; do not warn about the
# kotlin-reflect pieces it references.
-dontwarn kotlin.reflect.**
