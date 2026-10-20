# google_mlkit_text_recognition only bundles the Latin model; the other
# script recognizers are referenced but intentionally absent.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# R8 obfuscation breaks ML Kit's internal classes in release builds: every
# frame failed with InputImageConverterError (NullPointerException inside
# com.google.android.gms.internal.mlkit_vision_common).
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# shared_preferences_android is called from Dart through JNI by method name;
# without this, release builds fail with NoSuchMethodError
# (SharedPreferencesApiRegistrar.getAll) and history never loads.
# Its methods are Kotlin suspend functions: JNI looks them up by full
# signature, and package:jni resolves these Kotlin classes by name to drive the
# coroutines (see the 'kotlin/...' class names in package:jni's Dart sources).
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
