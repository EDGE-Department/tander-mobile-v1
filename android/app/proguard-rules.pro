# Twilio Programmable Video — JNI-referenced classes.
# The native libs (libtwilio_video_android_so.so) resolve tvi.webrtc.* and
# com.twilio.* classes by their literal names via FindClass() inside
# JNI_OnLoad. R8 cannot see those native references, so without these keeps it
# tree-shakes tvi.webrtc.WebRtcClassLoader out (and renames tvi.webrtc.EglBase
# etc.). At runtime Twilio's JNI_OnLoad does FindClass("tvi/webrtc/
# WebRtcClassLoader"), gets null, and RTC_CHECK-aborts (SIGABRT) the instant a
# call starts. This was the "app crashes on every call" bug — release-only,
# because R8 only runs for the release build. Keep is scoped to these two
# packages only.
-keep class com.twilio.** { *; }
-keep class tvi.webrtc.** { *; }
-dontwarn com.twilio.**
-dontwarn tvi.webrtc.**
-keepattributes InnerClasses

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit — suppress missing optional script recognizer classes
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# Play Core — Flutter deferred components (not used in sideloaded/debug builds)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
