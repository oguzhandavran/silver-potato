package com.example.flutter_shell

import androidx.annotation.NonNull
import com.example.flutter_shell.context.ContextBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ContextBridge.register(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
