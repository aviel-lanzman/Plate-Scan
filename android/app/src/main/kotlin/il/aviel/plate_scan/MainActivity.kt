package il.aviel.plate_scan

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var tones: ToneGenerator? = null

    // Flutter's SystemSound.alert only plays on desktop, so the continuous
    // scan alert beeps through this channel instead.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "plate_scan/alert")
            .setMethodCallHandler { call, result ->
                if (call.method != "beep") return@setMethodCallHandler result.notImplemented()
                try {
                    val generator = tones
                        ?: ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100).also { tones = it }
                    generator.startTone(ToneGenerator.TONE_PROP_BEEP2, 400)
                    result.success(true)
                } catch (e: RuntimeException) {
                    // ToneGenerator throws when the audio system is unavailable.
                    result.success(false)
                }
            }
    }

    override fun onDestroy() {
        tones?.release()
        tones = null
        super.onDestroy()
    }
}
