package com.nefer1453.stok_kontrol

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

  @SuppressLint("SetJavaScriptEnabled")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    val wv = WebView(this)
    setContentView(wv)

    wv.webChromeClient = WebChromeClient()
    val s: WebSettings = wv.settings
    s.javaScriptEnabled = true
    s.domStorageEnabled = true
    s.allowFileAccess = true
    s.allowContentAccess = true
    s.mediaPlaybackRequiresUserGesture = false

    // Offline assets
    wv.loadUrl("file:///android_asset/index.html")
  }

  override fun onBackPressed() {
    val wv = (this.findViewById<WebView>(android.R.id.content)).rootView as? WebView
    if (wv != null && wv.canGoBack()) wv.goBack() else super.onBackPressed()
  }
}
