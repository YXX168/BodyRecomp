package com.body.recomp

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    enableHighRefreshRate()
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    enableHighRefreshRate()
  }

  override fun onResume() {
    super.onResume()
    enableHighRefreshRate()
  }

  private fun enableHighRefreshRate() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
    val currentDisplay =
        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
          display
        } else {
          @Suppress("DEPRECATION") windowManager.defaultDisplay
        }) ?: return
    val activeMode = currentDisplay.mode ?: return
    val bestMode =
        currentDisplay.supportedModes
            .filter {
              it.physicalWidth == activeMode.physicalWidth &&
                  it.physicalHeight == activeMode.physicalHeight
            }
            .maxByOrNull { it.refreshRate }
            ?: return
    if (bestMode.refreshRate <= 60f) return
    val params = window.attributes
    var changed = false
    if (params.preferredDisplayModeId != bestMode.modeId) {
      params.preferredDisplayModeId = bestMode.modeId
      changed = true
    }
    @Suppress("DEPRECATION")
    if (params.preferredRefreshRate != bestMode.refreshRate) {
      params.preferredRefreshRate = bestMode.refreshRate
      changed = true
    }
    if (changed) {
      window.attributes = params
    }
  }
}
