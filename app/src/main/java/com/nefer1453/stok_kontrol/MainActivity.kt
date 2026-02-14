package com.nefer1453.stok_kontrol

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

  @SuppressLint("SetJavaScriptEnabled")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    val wv = WebView(this)
    setContentView(wv)

    wv.webViewClient = WebViewClient()
    wv.webChromeClient = WebChromeClient()

    val s: WebSettings = wv.settings
    s.javaScriptEnabled = true
    s.domStorageEnabled = true
    s.allowFileAccess = true
    s.allowContentAccess = true
    s.loadsImagesAutomatically = true
    s.mediaPlaybackRequiresUserGesture = false
    s.cacheMode = WebSettings.LOAD_DEFAULT

    wv.loadUrl("file:///android_asset/index.html")
  }

  override fun onBackPressed() {
    val wv = (window.decorView.rootView as? WebView)
    if (wv != null && wv.canGoBack()) wv.goBack() else super.onBackPressed()
  }
}
