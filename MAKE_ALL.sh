#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP_ID="com.nefer1453.stok_kontrol"
PKG_DIR="app/src/main/java/com/nefer1453/stok_kontrol"

mkdir -p .github/workflows
mkdir -p app/src/main/assets
mkdir -p "$PKG_DIR"
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/drawable
mkdir -p app

# ---------------------------
# settings.gradle
# ---------------------------
cat > settings.gradle <<'GRADLE'
pluginManagement {
  repositories {
    gradlePluginPortal()
    google()
    mavenCentral()
  }
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
  repositories {
    google()
    mavenCentral()
  }
}
rootProject.name = "stok_kontrol"
include(":app")
GRADLE

# ---------------------------
# gradle.properties
# ---------------------------
cat > gradle.properties <<'PROP'
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
PROP

# ---------------------------
# root build.gradle (plugins DSL, no buildscript madness)
# ---------------------------
cat > build.gradle <<'GRADLE'
plugins {
  id 'com.android.application' version '8.2.2' apply false
  id 'org.jetbrains.kotlin.android' version '1.9.22' apply false
}
GRADLE

# ---------------------------
# app/build.gradle
# ---------------------------
cat > app/build.gradle <<'GRADLE'
plugins {
  id 'com.android.application'
  id 'org.jetbrains.kotlin.android'
}

android {
  namespace 'com.nefer1453.stok_kontrol'
  compileSdk 34

  defaultConfig {
    applicationId "com.nefer1453.stok_kontrol"
    minSdk 26
    targetSdk 34
    versionCode 1
    versionName "1.0"
  }

  buildTypes {
    debug { debuggable true }
    release {
      minifyEnabled false
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
  }

  compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
  }
  kotlinOptions { jvmTarget = '17' }
}

dependencies {
  implementation "org.jetbrains.kotlin:kotlin-stdlib:1.9.22"
  implementation 'androidx.core:core-ktx:1.12.0'
  implementation 'androidx.appcompat:appcompat:1.6.1'
  implementation 'com.google.android.material:material:1.11.0'
}
GRADLE

# ---------------------------
# proguard-rules.pro
# ---------------------------
cat > app/proguard-rules.pro <<'PRO'
# WebView app, keep it simple.
PRO

# ---------------------------
# AndroidManifest.xml
# (IMPORTANT: use drawable icons to avoid missing mipmap errors on Actions)
# ---------------------------
cat > app/src/main/AndroidManifest.xml <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:allowBackup="true"
        android:label="stok_kontrol"
        android:icon="@drawable/ic_launcher"
        android:roundIcon="@drawable/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.StokKontrol">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
XML

# ---------------------------
# themes.xml
# ---------------------------
cat > app/src/main/res/values/themes.xml <<'XML'
<resources>
  <style name="Theme.StokKontrol" parent="Theme.MaterialComponents.DayNight.NoActionBar">
    <item name="android:statusBarColor">@android:color/transparent</item>
    <item name="android:navigationBarColor">@android:color/transparent</item>
  </style>
</resources>
XML

# ---------------------------
# Minimal vector launcher icons (drawable)
# ---------------------------
cat > app/src/main/res/drawable/ic_launcher.xml <<'XML'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#0b2f24" android:pathData="M0,0h108v108h-108z"/>
    <path android:fillColor="#16a34a" android:pathData="M18,54c0,-19.9 16.1,-36 36,-36s36,16.1 36,36 -16.1,36 -36,36 -36,-16.1 -36,-36z"/>
    <path android:fillColor="#facc15" android:pathData="M36,56h36v8h-36z"/>
    <path android:fillColor="#052016" android:pathData="M32,44h44v8h-44z"/>
</vector>
XML

cat > app/src/main/res/drawable/ic_launcher_round.xml <<'XML'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#0b2f24" android:pathData="M54,54m-54,0a54,54 0,1 1,108 0a54,54 0,1 1,-108 0"/>
    <path android:fillColor="#16a34a" android:pathData="M18,54c0,-19.9 16.1,-36 36,-36s36,16.1 36,36 -16.1,36 -36,36 -36,-16.1 -36,-36z"/>
    <path android:fillColor="#facc15" android:pathData="M36,56h36v8h-36z"/>
    <path android:fillColor="#052016" android:pathData="M32,44h44v8h-44z"/>
</vector>
XML

# ---------------------------
# MainActivity.kt
# ---------------------------
cat > "$PKG_DIR/MainActivity.kt" <<'KOT'
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
KOT

# ---------------------------
# index.html (full UI)
# ---------------------------
cat > app/src/main/assets/index.html <<'HTML'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <meta name="theme-color" content="#0b2f24" />
  <title>stok_kontrol</title>
  <style>
    :root{
      --bg:#071a14;
      --panel:#0b2f24;
      --panel2:#083026;
      --line:rgba(250,204,21,.25);
      --text:#e7f7ef;
      --muted:rgba(231,247,239,.65);
      --gold:#facc15;
      --green:#16a34a;
      --red:#ef4444;
      --amber:#f59e0b;
      --shadow:0 10px 30px rgba(0,0,0,.35);
      --r:18px;
    }
    *{box-sizing:border-box}
    html,body{height:100%}
    body{
      margin:0; background:radial-gradient(1100px 500px at 20% 0%, rgba(250,204,21,.08), transparent 50%),
                           radial-gradient(900px 600px at 100% 100%, rgba(22,163,74,.12), transparent 55%),
                           var(--bg);
      color:var(--text);
      font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial;
      overflow-x:hidden;
    }
    .topbar{
      position:sticky; top:0; z-index:30;
      padding:12px 12px 10px;
      backdrop-filter: blur(10px);
      background: linear-gradient(to bottom, rgba(7,26,20,.92), rgba(7,26,20,.65));
      border-bottom:1px solid rgba(250,204,21,.12);
    }
    .toprow{display:flex; align-items:center; gap:10px}
    .btnIcon{
      border:1px solid var(--line);
      background:linear-gradient(180deg, rgba(11,47,36,.85), rgba(8,48,38,.6));
      color:var(--text);
      padding:10px 12px;
      border-radius:14px;
      box-shadow: var(--shadow);
      cursor:pointer;
      user-select:none;
    }
    .titlePill{
      flex:1;
      border:1px solid rgba(250,204,21,.18);
      border-radius:16px;
      padding:10px 12px;
      background:rgba(11,47,36,.55);
      box-shadow: var(--shadow);
      min-width:0;
      display:flex;
      gap:10px;
      align-items:center;
    }
    .titlePill .small{color:var(--muted); font-size:12px}
    .titlePill .big{font-weight:800; letter-spacing:.2px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis}
    .searchRow{margin-top:10px; display:none}
    .searchRow.show{display:block}
    .inp{
      width:100%;
      padding:14px 14px;
      border-radius:16px;
      border:1px solid rgba(250,204,21,.18);
      outline:none;
      background:rgba(11,47,36,.55);
      color:var(--text);
      font-size:16px;
    }
    .main{padding:14px 12px 96px}
    .card{
      background:linear-gradient(180deg, rgba(11,47,36,.85), rgba(8,48,38,.62));
      border:1px solid rgba(250,204,21,.16);
      border-radius:22px;
      box-shadow: var(--shadow);
      padding:14px;
      margin-bottom:12px;
    }
    .row{display:flex; gap:10px; align-items:center}
    .space{justify-content:space-between}
    .h{font-weight:900; letter-spacing:.2px}
    .pill{
      display:inline-flex; align-items:center; gap:8px;
      padding:7px 10px;
      border-radius:999px;
      border:1px solid rgba(250,204,21,.25);
      background:rgba(0,0,0,.12);
      color:var(--text);
      font-size:12px;
      white-space:nowrap;
    }
    .pill.badge{font-weight:800}
    .pill.crit{border-color:rgba(239,68,68,.35); background:rgba(239,68,68,.14)}
    .pill.warn{border-color:rgba(245,158,11,.35); background:rgba(245,158,11,.14)}
    .pill.ok{border-color:rgba(22,163,74,.35); background:rgba(22,163,74,.14)}
    .muted{color:var(--muted)}
    .btn{
      padding:12px 14px;
      border-radius:16px;
      border:1px solid rgba(250,204,21,.22);
      background:linear-gradient(180deg, rgba(250,204,21,.16), rgba(250,204,21,.06));
      color:var(--text);
      font-weight:900;
      cursor:pointer;
      box-shadow: var(--shadow);
    }
    .btn.danger{
      border-color:rgba(239,68,68,.35);
      background:linear-gradient(180deg, rgba(239,68,68,.18), rgba(239,68,68,.07));
    }
    .listHint{font-size:12px; color:var(--muted); margin:0 2px 10px}
    .selectBanner{
      margin-top:10px;
      display:none;
      border:1px solid rgba(250,204,21,.22);
      border-radius:18px;
      padding:10px 12px;
      background:rgba(11,47,36,.55);
      box-shadow: var(--shadow);
      gap:10px;
      align-items:center;
      justify-content:space-between;
    }
    .selectBanner.show{display:flex}
    .bannerLeft{min-width:0}
    .bannerLeft .b1{font-weight:900; white-space:nowrap; overflow:hidden; text-overflow:ellipsis}
    .bannerLeft .b2{font-size:12px; color:var(--muted)}
    .drawer{
      position:fixed; inset:0;
      display:none; z-index:40;
      background:rgba(0,0,0,.45);
    }
    .drawer.show{display:block}
    .drawerPanel{
      position:absolute; left:0; top:0; bottom:0;
      width:min(320px, 88vw);
      background:linear-gradient(180deg, rgba(11,47,36,.96), rgba(8,48,38,.90));
      border-right:1px solid rgba(250,204,21,.14);
      box-shadow: 20px 0 50px rgba(0,0,0,.4);
      padding:14px;
    }
    .drawerTitle{font-weight:950; margin:6px 2px 10px}
    .menuItem{
      display:flex; align-items:center; justify-content:space-between;
      padding:12px 12px;
      border-radius:16px;
      border:1px solid rgba(250,204,21,.14);
      background:rgba(0,0,0,.10);
      margin-bottom:10px;
      cursor:pointer;
    }
    .menuItem .k{font-weight:900}
    .menuItem .s{font-size:12px; color:var(--muted)}
    .modal{
      position:fixed; inset:0; display:none; z-index:50;
      background:rgba(0,0,0,.55);
      padding:16px;
    }
    .modal.show{display:flex; align-items:center; justify-content:center}
    .modalBox{
      width:min(720px, 98vw);
      background:linear-gradient(180deg, rgba(11,47,36,.96), rgba(8,48,38,.90));
      border:1px solid rgba(250,204,21,.18);
      border-radius:24px;
      box-shadow: 0 30px 90px rgba(0,0,0,.6);
      overflow:hidden;
    }
    .modalHead{
      display:flex; align-items:center; justify-content:space-between;
      padding:14px 14px;
      border-bottom:1px solid rgba(250,204,21,.12);
    }
    .modalHead .t{font-weight:950}
    .modalBody{padding:14px}
    .grid{
      display:grid;
      grid-template-columns:1fr;
      gap:10px;
    }
    @media (min-width:720px){
      .grid.two{grid-template-columns:1fr 1fr}
    }
    label{font-size:12px; color:var(--muted); margin:2px 4px 6px; display:block}
    .sel{
      width:100%;
      padding:14px 14px;
      border-radius:16px;
      border:1px solid rgba(250,204,21,.18);
      outline:none;
      background:rgba(0,0,0,.14);
      color:var(--text);
      font-size:16px;
    }
    .wheel{
      display:grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap:10px;
    }
    .footRow{display:flex; gap:10px; justify-content:flex-end; margin-top:12px}
    .fab{
      position:fixed;
      right:14px;
      bottom:14px;
      z-index:35;
      display:none;
      padding:14px 16px;
      border-radius:999px;
      border:1px solid rgba(250,204,21,.24);
      background:linear-gradient(180deg, rgba(250,204,21,.18), rgba(250,204,21,.06));
      box-shadow: var(--shadow);
      font-weight:950;
      cursor:pointer;
    }
    .fab.show{display:block}
    .tabs{
      display:flex; gap:10px; margin:8px 0 12px;
      flex-wrap:wrap;
    }
    .tab{
      padding:9px 12px;
      border-radius:999px;
      border:1px solid rgba(250,204,21,.18);
      background:rgba(0,0,0,.10);
      cursor:pointer;
      font-weight:900;
      font-size:12px;
    }
    .tab.active{
      border-color:rgba(250,204,21,.35);
      background:rgba(250,204,21,.10);
    }
  </style>
</head>
<body>

  <div class="topbar">
    <div class="toprow">
      <button class="btnIcon" id="btnMenu">☰</button>

      <div class="titlePill">
        <div style="min-width:0">
          <div class="small" id="subTitle">Ekran</div>
          <div class="big" id="mainTitle">Tüm Ürünler</div>
        </div>
      </div>

      <button class="btnIcon" id="btnSearch">Ara</button>
    </div>

    <div class="searchRow" id="searchRow">
      <input class="inp" id="q" placeholder="Ürün ara..." />
    </div>

    <div class="selectBanner" id="selectBanner">
      <div class="bannerLeft">
        <div class="b1" id="selName">Seçim yok</div>
        <div class="b2" id="selMeta">—</div>
      </div>
      <div class="row" style="gap:8px">
        <button class="btn" id="btnShareTop">Paylaş</button>
        <button class="btn" id="btnClearSel">Temizle</button>
      </div>
    </div>
  </div>

  <div class="main">
    <div class="tabs">
      <div class="tab active" data-view="all">Tüm Ürünler</div>
      <div class="tab" data-view="skt10">SKT: Son 10 Gün</div>
      <div class="tab" data-view="report">Günlük Rapor</div>
      <div class="tab" data-view="settings">Ayarlar</div>
    </div>

    <p class="listHint" id="hint">Ürüne dokun → seç/düzenle. Menüden “Ürün/Parti Ekle”.</p>

    <div id="list"></div>
  </div>

  <button class="fab" id="fabShare">Paylaş</button>

  <!-- Drawer -->
  <div class="drawer" id="drawer">
    <div class="drawerPanel">
      <div class="drawerTitle">Menü</div>

      <div class="menuItem" id="menuAdd">
        <div>
          <div class="k">+ Ürün / Parti Ekle</div>
          <div class="s">Yeni kayıt veya parti ekle</div>
        </div>
        <div>›</div>
      </div>

      <div class="menuItem" id="menuExport">
        <div>
          <div class="k">Paylaş (CSV)</div>
          <div class="s">Seçili / tüm liste</div>
        </div>
        <div>›</div>
      </div>

      <div class="menuItem" id="menuClose">
        <div>
          <div class="k">Kapat</div>
          <div class="s">Menüyü kapat</div>
        </div>
        <div>×</div>
      </div>

      <div class="card" style="margin-top:14px">
        <div class="h">Kısayol</div>
        <div class="muted" style="font-size:12px; margin-top:8px">
          • Ürüne tıkla: seç/düzenle<br/>
          • Seçince üstte Paylaş çıkar<br/>
          • Arama: sağ üst “Ara”
        </div>
      </div>
    </div>
  </div>

  <!-- Add/Edit Modal -->
  <div class="modal" id="modal">
    <div class="modalBox">
      <div class="modalHead">
        <div class="t" id="modalTitle">Ürün / Parti</div>
        <button class="btnIcon" id="btnCloseModal">Kapat</button>
      </div>
      <div class="modalBody">
        <div class="grid">
          <div>
            <label>Mod</label>
            <select class="sel" id="mode">
              <option value="new">Yeni ürün + parti</option>
              <option value="party">Mevcut ürüne parti ekle</option>
            </select>
          </div>

          <div class="grid two">
            <div>
              <label>Ürün adı</label>
              <input class="inp" id="name" placeholder="Örn: DANET SUCUK" />
            </div>
            <div>
              <label>Adet</label>
              <input class="inp" id="qty" inputmode="numeric" placeholder="0" />
            </div>
          </div>

          <div class="grid two">
            <div>
              <label>SKT (kayan) — Ay: NUMARA</label>
              <div class="wheel">
                <select class="sel" id="sktD"></select>
                <select class="sel" id="sktM"></select>
                <select class="sel" id="sktY"></select>
              </div>
            </div>

            <div>
              <label>Temin</label>
              <select class="sel" id="temin">
                <option value="Sipariş">Sipariş</option>
                <option value="Dağılım">Dağılım</option>
                <option value="Direkt">Direkt</option>
              </select>
            </div>
          </div>

          <div class="grid two">
            <div>
              <label>Dağılım nedeni</label>
              <select class="sel" id="dagitimNedeni">
                <option value="">—</option>
                <option value="Inserte hazırlık">Inserte hazırlık</option>
                <option value="Merkez dağılım">Merkez dağılım</option>
                <option value="Şube dağılım">Şube dağılım</option>
              </select>
            </div>

            <div>
              <label>Insert adı</label>
              <input class="inp" id="insertAdi" placeholder="Örn: 14 Şubat" />
            </div>
          </div>

          <div>
            <label>Insert tarihi (kayan) — Ay: İSİM</label>
            <div class="wheel">
              <select class="sel" id="insD"></select>
              <select class="sel" id="insM"></select>
              <select class="sel" id="insY"></select>
            </div>
          </div>

          <div>
            <label>Not</label>
            <textarea class="inp" id="note" rows="3" placeholder="Ek bilgi..."></textarea>
          </div>

          <div class="footRow">
            <button class="btn danger" id="btnDelete" style="display:none">Sil</button>
            <button class="btn" id="btnSave">Kaydet</button>
          </div>
        </div>
      </div>
    </div>
  </div>

<script src="./app.js"></script>
</body>
</html>
HTML

# ---------------------------
# app.js (FULL logic)
# ---------------------------
cat > app/src/main/assets/app.js <<'JS'
(() => {
  "use strict";

  const $ = (id) => document.getElementById(id);
  const pad2 = (n) => String(n).padStart(2, "0");
  const isoToday = () => {
    const d = new Date();
    return `${d.getFullYear()}-${pad2(d.getMonth()+1)}-${pad2(d.getDate())}`;
  };
  const parseISO = (iso) => {
    if (!iso) return null;
    const d = new Date(iso + "T00:00:00");
    return isNaN(d) ? null : d;
  };
  const daysBetween = (a, b) => {
    // b - a (days)
    const ms = 24*60*60*1000;
    const da = new Date(a.getFullYear(), a.getMonth(), a.getDate()).getTime();
    const db = new Date(b.getFullYear(), b.getMonth(), b.getDate()).getTime();
    return Math.round((db - da) / ms);
  };

  const monthTr = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"];

  // -----------------------------
  // Storage
  // -----------------------------
  const KEY = "stok_kontrol_v1";
  const SETKEY = "stok_kontrol_settings_v1";

  const defaultSettings = {
    warnDays: 7,     // yakın
    critDays: 0,     // kritik (0 ve altı)
    sktWindow: 10,   // son X gün listesi
  };

  const loadSettings = () => {
    try {
      const s = JSON.parse(localStorage.getItem(SETKEY) || "null");
      return { ...defaultSettings, ...(s||{}) };
    } catch { return { ...defaultSettings }; }
  };

  const saveSettings = (s) => localStorage.setItem(SETKEY, JSON.stringify(s));

  const loadData = () => {
    try {
      const d = JSON.parse(localStorage.getItem(KEY) || "null");
      if (!d || !Array.isArray(d.items)) return { items: [] };
      return d;
    } catch {
      return { items: [] };
    }
  };

  const saveData = () => localStorage.setItem(KEY, JSON.stringify(state.db));

  // -----------------------------
  // State
  // -----------------------------
  const state = {
    view: "all",
    q: "",
    selectedId: null,
    editingId: null,
    settings: loadSettings(),
    db: loadData(),
  };

  // If empty, seed a couple samples (optional)
  if (state.db.items.length === 0) {
    state.db.items.push(
      mkItem({ name:"Hzbz", qty:5, sktISO:addDaysISO(isoToday(), -0), temin:"Temin", note:"" }),
      mkItem({ name:"Hshs", qty:5, sktISO:addDaysISO(isoToday(), 7), temin:"Temin", note:"" })
    );
    saveData();
  }

  function addDaysISO(iso, days) {
    const d = parseISO(iso) || new Date();
    d.setDate(d.getDate() + days);
    return `${d.getFullYear()}-${pad2(d.getMonth()+1)}-${pad2(d.getDate())}`;
  }

  function uid() {
    return Math.random().toString(16).slice(2) + "-" + Date.now().toString(16);
  }

  function mkItem(p) {
    const now = new Date().toISOString();
    return {
      id: uid(),
      name: (p.name || "").trim(),
      qty: Number(p.qty || 0),
      sktISO: p.sktISO || isoToday(),
      temin: p.temin || "Sipariş",
      dagitimNedeni: p.dagitimNedeni || "",
      insertAdi: (p.insertAdi || "").trim(),
      insertISO: p.insertISO || "",
      note: (p.note || "").trim(),
      createdISO: now,
      updatedISO: now,
    };
  }

  // -----------------------------
  // UI refs
  // -----------------------------
  const listEl = $("list");
  const qEl = $("q");
  const searchRow = $("searchRow");
  const btnSearch = $("btnSearch");
  const btnMenu = $("btnMenu");
  const drawer = $("drawer");
  const menuClose = $("menuClose");
  const menuAdd = $("menuAdd");
  const menuExport = $("menuExport");

  const tabs = Array.from(document.querySelectorAll(".tab"));

  const selectBanner = $("selectBanner");
  const selName = $("selName");
  const selMeta = $("selMeta");
  const btnShareTop = $("btnShareTop");
  const btnClearSel = $("btnClearSel");
  const fabShare = $("fabShare");

  // Modal
  const modal = $("modal");
  const btnCloseModal = $("btnCloseModal");
  const modalTitle = $("modalTitle");
  const modeEl = $("mode");
  const nameEl = $("name");
  const qtyEl = $("qty");
  const teminEl = $("temin");
  const dagitimNedeniEl = $("dagitimNedeni");
  const insertAdiEl = $("insertAdi");
  const noteEl = $("note");
  const btnSave = $("btnSave");
  const btnDelete = $("btnDelete");

  // Date selects (wheel-like)
  const sktD = $("sktD"), sktM = $("sktM"), sktY = $("sktY");
  const insD = $("insD"), insM = $("insM"), insY = $("insY");

  // Titles
  const mainTitle = $("mainTitle");
  const subTitle = $("subTitle");
  const hint = $("hint");

  // -----------------------------
  // Date wheel builders
  // -----------------------------
  function fillSelect(sel, arr, fmt = (x)=>String(x)) {
    sel.innerHTML = "";
    for (const v of arr) {
      const o = document.createElement("option");
      o.value = String(v);
      o.textContent = fmt(v);
      sel.appendChild(o);
    }
  }

  function bindDateWheel({ dSel, mSel, ySel, monthMode }) {
    const years = [];
    const y0 = new Date().getFullYear() - 1;
    const y1 = new Date().getFullYear() + 12;
    for (let y=y0; y<=y1; y++) years.push(y);

    fillSelect(dSel, Array.from({length:31}, (_,i)=>i+1), (v)=>pad2(v));

    fillSelect(mSel, Array.from({length:12}, (_,i)=>i+1), (v)=>{
      if (monthMode === "num") return pad2(v);        // ✅ SKT numara
      return monthTr[v-1];                           // ✅ Insert isim
    });

    fillSelect(ySel, years, (v)=>String(v));

    const api = {
      getISO(){
        const dd = Number(dSel.value);
        const mm = Number(mSel.value);
        const yy = Number(ySel.value);
        // clamp day
        const maxDay = new Date(yy, mm, 0).getDate();
        const day = Math.min(dd, maxDay);
        if (day !== dd) dSel.value = String(day);
        return `${yy}-${pad2(mm)}-${pad2(day)}`;
      },
      setISO(iso){
        const d = parseISO(iso) || new Date();
        dSel.value = String(d.getDate());
        mSel.value = String(d.getMonth()+1);
        ySel.value = String(d.getFullYear());
      }
    };

    // keep day valid when month/year change
    const fix = ()=>{ api.getISO(); };
    mSel.addEventListener("change", fix);
    ySel.addEventListener("change", fix);

    return api;
  }

  const wheelSKT = bindDateWheel({ dSel:sktD, mSel:sktM, ySel:sktY, monthMode:"num" });
  const wheelINS = bindDateWheel({ dSel:insD, mSel:insM, ySel:insY, monthMode:"name" });

  // -----------------------------
  // View helpers
  // -----------------------------
  function setView(v) {
    state.view = v;
    state.selectedId = null;
    syncSelectionUI();
    render();
  }

  function setTitles() {
    const map = {
      all:   { t:"Tüm Ürünler", s:"Ekran" },
      skt10: { t:`SKT: Son ${state.settings.sktWindow} Gün`, s:"Ekran" },
      report:{ t:"Günlük Rapor", s:"Ekran" },
      settings:{ t:"Ayarlar", s:"Ekran" },
    };
    mainTitle.textContent = map[state.view].t;
    subTitle.textContent = map[state.view].s;

    if (state.view === "all") hint.textContent = "Ürüne dokun → seç/düzenle. Menüden “Ürün/Parti Ekle”.";
    if (state.view === "skt10") hint.textContent = "Yakın SKT listesi. Ürüne dokun → seç/düzenle.";
    if (state.view === "report") hint.textContent = "Bugün eklenen/düzenlenen ve SKT yaklaşanlar.";
    if (state.view === "settings") hint.textContent = "Kritik renk eşikleri burada.";
  }

  function badgeForDaysLeft(daysLeft) {
    if (daysLeft <= state.settings.critDays) return { cls:"crit", txt:`Kritik (${daysLeft}g)` };
    if (daysLeft <= state.settings.warnDays) return { cls:"warn", txt:`Yakın (${daysLeft}g)` };
    return { cls:"ok", txt:`İyi (${daysLeft}g)` };
  }

  function fmtTR(iso) {
    const d = parseISO(iso);
    if (!d) return "—";
    return `${pad2(d.getDate())}.${pad2(d.getMonth()+1)}.${d.getFullYear()}`;
  }

  function todayKey() {
    const d = new Date();
    return `${d.getFullYear()}-${pad2(d.getMonth()+1)}-${pad2(d.getDate())}`;
  }

  // -----------------------------
  // Selection + Share
  // -----------------------------
  function getSelected() {
    return state.db.items.find(x => x.id === state.selectedId) || null;
  }

  function syncSelectionUI() {
    const it = getSelected();
    const on = !!it;

    selectBanner.classList.toggle("show", on);
    fabShare.classList.toggle("show", on);

    if (!it) {
      selName.textContent = "Seçim yok";
      selMeta.textContent = "—";
      return;
    }
    selName.textContent = it.name || "(isimsiz)";
    selMeta.textContent = `Adet: ${it.qty} • SKT: ${fmtTR(it.sktISO)} • Temin: ${it.temin || "—"}`;
  }

  function shareTextForItem(it) {
    const daysLeft = daysBetween(new Date(), parseISO(it.sktISO) || new Date());
    const b = badgeForDaysLeft(daysLeft);
    return [
      `Ürün: ${it.name}`,
      `Adet: ${it.qty}`,
      `SKT: ${fmtTR(it.sktISO)} (${b.txt})`,
      `Temin: ${it.temin || ""}`,
      it.dagitimNedeni ? `Dağılım nedeni: ${it.dagitimNedeni}` : "",
      it.insertAdi ? `Insert: ${it.insertAdi}` : "",
      it.insertISO ? `Insert tarihi: ${fmtTR(it.insertISO)}` : "",
      it.note ? `Not: ${it.note}` : "",
    ].filter(Boolean).join("\n");
  }

  function exportCSV(items) {
    const cols = ["id","name","qty","sktISO","temin","dagitimNedeni","insertAdi","insertISO","note","createdISO","updatedISO"];
    const esc = (s) => `"${String(s??"").replaceAll('"','""')}"`;
    const lines = [cols.join(",")];
    for (const it of items) {
      lines.push(cols.map(c => esc(it[c])).join(","));
    }
    return lines.join("\n");
  }

  async function doShareSelectedOrAll(preferSelected=true) {
    const it = getSelected();
    if (preferSelected && it) {
      const text = shareTextForItem(it);
      await shareOrCopy(text);
      return;
    }
    const csv = exportCSV(filteredItemsAll());
    await shareOrCopy(csv, "stok_kontrol.csv");
  }

  async function shareOrCopy(text, filename) {
    try {
      if (navigator.share) {
        // Some webviews require files; fallback to text share.
        await navigator.share({ text });
        toast("Paylaşıldı");
        return;
      }
    } catch {}
    try {
      await navigator.clipboard.writeText(text);
      toast("Panoya kopyalandı");
    } catch {
      // last fallback
      prompt("Kopyala:", text);
    }
  }

  // mini toast
  let toastTimer = null;
  function toast(msg) {
    clearTimeout(toastTimer);
    let t = document.getElementById("toast");
    if (!t) {
      t = document.createElement("div");
      t.id = "toast";
      t.style.position = "fixed";
      t.style.left = "50%";
      t.style.bottom = "84px";
      t.style.transform = "translateX(-50%)";
      t.style.padding = "10px 12px";
      t.style.borderRadius = "999px";
      t.style.border = "1px solid rgba(250,204,21,.25)";
      t.style.background = "rgba(11,47,36,.92)";
      t.style.boxShadow = "0 10px 30px rgba(0,0,0,.35)";
      t.style.zIndex = "99";
      document.body.appendChild(t);
    }
    t.textContent = msg;
    t.style.display = "block";
    toastTimer = setTimeout(()=>{ t.style.display="none"; }, 1200);
  }

  // -----------------------------
  // Filtering + rendering
  // -----------------------------
  function filteredItemsAll() {
    const q = state.q.trim().toLowerCase();
    let arr = state.db.items.slice();

    if (q) {
      arr = arr.filter(it => (it.name||"").toLowerCase().includes(q));
    }

    // default sort: soonest SKT first then name
    arr.sort((a,b) => {
      const da = parseISO(a.sktISO) || new Date(0);
      const db = parseISO(b.sktISO) || new Date(0);
      const x = da.getTime() - db.getTime();
      if (x !== 0) return x;
      return (a.name||"").localeCompare(b.name||"");
    });

    return arr;
  }

  function filteredItemsSKTWindow() {
    const win = Number(state.settings.sktWindow || 10);
    const now = new Date();
    return filteredItemsAll().filter(it => {
      const d = parseISO(it.sktISO);
      if (!d) return false;
      const left = daysBetween(now, d);
      return left <= win;
    });
  }

  function reportData() {
    const today = todayKey();
    const items = state.db.items;

    const createdToday = items.filter(it => (it.createdISO||"").slice(0,10) === today);
    const updatedToday = items.filter(it => (it.updatedISO||"").slice(0,10) === today && (it.createdISO||"").slice(0,10) !== today);

    const now = new Date();
    const soon = items
      .map(it => ({ it, left: daysBetween(now, parseISO(it.sktISO)||now) }))
      .filter(x => x.left <= state.settings.sktWindow)
      .sort((a,b)=>a.left-b.left)
      .slice(0, 30);

    return { createdToday, updatedToday, soon };
  }

  function render() {
    setTitles();
    tabs.forEach(t => t.classList.toggle("active", t.dataset.view === state.view));

    if (state.view === "settings") {
      renderSettings();
      return;
    }
    if (state.view === "report") {
      renderReport();
      return;
    }

    const items = (state.view === "skt10") ? filteredItemsSKTWindow() : filteredItemsAll();

    // fast render with fragment
    listEl.innerHTML = "";
    const frag = document.createDocumentFragment();

    if (items.length === 0) {
      const empty = document.createElement("div");
      empty.className = "card";
      empty.innerHTML = `<div class="h">Liste boş</div><div class="muted" style="margin-top:8px">Menüden “Ürün/Parti Ekle”.</div>`;
      frag.appendChild(empty);
      listEl.appendChild(frag);
      return;
    }

    for (const it of items) {
      const now = new Date();
      const sktD = parseISO(it.sktISO) || now;
      const left = daysBetween(now, sktD);
      const b = badgeForDaysLeft(left);

      const card = document.createElement("div");
      card.className = "card";
      card.dataset.id = it.id;

      const selected = (it.id === state.selectedId);
      const border = selected ? "rgba(250,204,21,.45)" : "rgba(250,204,21,.16)";
      card.style.borderColor = border;

      card.innerHTML = `
        <div class="row space">
          <div class="h">${escapeHtml(it.name || "(isimsiz)")}</div>
          <div class="pill badge">${escapeHtml(String(it.qty))} adet</div>
        </div>

        <div class="row" style="margin-top:10px; flex-wrap:wrap">
          <div class="pill ${b.cls}">${escapeHtml(b.txt)}</div>
          <div class="pill">SKT: ${escapeHtml(fmtTR(it.sktISO))}</div>
          <div class="pill">${escapeHtml(it.temin || "—")}</div>
          ${it.dagitimNedeni ? `<div class="pill">Dağılım/Insert</div>` : ``}
          ${it.insertAdi ? `<div class="pill">Insert: ${escapeHtml(it.insertAdi)}</div>` : ``}
          ${it.insertISO ? `<div class="pill">Tarih: ${escapeHtml(fmtTR(it.insertISO))}</div>` : ``}
        </div>

        <div class="row space" style="margin-top:12px; gap:10px; flex-wrap:wrap">
          <button class="btn danger btnRemove">Kaldır</button>
          <div class="muted" style="font-size:12px">Dokun: seç/düzenle</div>
        </div>
      `;

      // interactions
      card.addEventListener("click", (e) => {
        const btn = e.target.closest("button");
        if (btn) return; // buttons handled below
        // first tap: select, second tap: edit
        if (state.selectedId !== it.id) {
          state.selectedId = it.id;
          syncSelectionUI();
          render();
        } else {
          openModalForEdit(it.id);
        }
      });

      card.querySelector(".btnRemove").addEventListener("click", (e) => {
        e.stopPropagation();
        removeItem(it.id);
      });

      frag.appendChild(card);
    }

    listEl.appendChild(frag);
  }

  function renderSettings() {
    listEl.innerHTML = "";
    const c = document.createElement("div");
    c.className = "card";
    c.innerHTML = `
      <div class="h">Ayarlar</div>
      <div class="muted" style="margin-top:6px; font-size:12px">Renk eşikleri ve SKT penceresi.</div>

      <div class="grid two" style="margin-top:12px">
        <div>
          <label>Yakın gün eşiği (warnDays)</label>
          <input class="inp" id="setWarn" inputmode="numeric" value="${escapeHtml(String(state.settings.warnDays))}" />
        </div>
        <div>
          <label>Kritik gün eşiği (critDays)</label>
          <input class="inp" id="setCrit" inputmode="numeric" value="${escapeHtml(String(state.settings.critDays))}" />
        </div>
      </div>

      <div style="margin-top:10px">
        <label>SKT penceresi (Son X gün)</label>
        <input class="inp" id="setWin" inputmode="numeric" value="${escapeHtml(String(state.settings.sktWindow))}" />
      </div>

      <div class="footRow">
        <button class="btn" id="btnSaveSet">Kaydet</button>
      </div>
    `;
    listEl.appendChild(c);

    c.querySelector("#btnSaveSet").addEventListener("click", () => {
      const warn = Number(c.querySelector("#setWarn").value || 7);
      const crit = Number(c.querySelector("#setCrit").value || 0);
      const win = Number(c.querySelector("#setWin").value || 10);

      state.settings.warnDays = isFinite(warn) ? warn : 7;
      state.settings.critDays = isFinite(crit) ? crit : 0;
      state.settings.sktWindow = isFinite(win) ? win : 10;

      saveSettings(state.settings);
      toast("Ayarlar kaydedildi");
      render();
    });
  }

  function renderReport() {
    listEl.innerHTML = "";
    const r = reportData();

    const c = document.createElement("div");
    c.className = "card";
    c.innerHTML = `
      <div class="h">Günlük Rapor</div>
      <div class="muted" style="margin-top:6px; font-size:12px">${escapeHtml(todayKey())}</div>

      <div style="margin-top:12px" class="row" >
        <div class="pill ok">Bugün eklenen: ${r.createdToday.length}</div>
        <div class="pill warn">Bugün düzenlenen: ${r.updatedToday.length}</div>
      </div>

      <div class="muted" style="margin-top:12px; font-size:12px">SKT yaklaşan (ilk 30):</div>
      <div id="repSoon" style="margin-top:8px"></div>

      <div class="footRow">
        <button class="btn" id="btnShareReport">Raporu Paylaş</button>
      </div>
    `;
    listEl.appendChild(c);

    const repSoon = c.querySelector("#repSoon");
    if (r.soon.length === 0) {
      repSoon.innerHTML = `<div class="muted">Yakın SKT yok.</div>`;
    } else {
      const f = document.createDocumentFragment();
      for (const x of r.soon) {
        const it = x.it;
        const b = badgeForDaysLeft(x.left);
        const row = document.createElement("div");
        row.style.marginBottom = "8px";
        row.innerHTML = `
          <div class="row space" style="gap:10px">
            <div style="min-width:0">
              <div class="h" style="font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis">${escapeHtml(it.name)}</div>
              <div class="muted" style="font-size:12px">SKT: ${escapeHtml(fmtTR(it.sktISO))}</div>
            </div>
            <div class="pill ${b.cls}">${escapeHtml(b.txt)}</div>
          </div>
        `;
        row.addEventListener("click", () => {
          state.selectedId = it.id;
          syncSelectionUI();
          setView("all");
        });
        f.appendChild(row);
      }
      repSoon.appendChild(f);
    }

    c.querySelector("#btnShareReport").addEventListener("click", async () => {
      const txt = buildReportText(r);
      await shareOrCopy(txt);
    });
  }

  function buildReportText(r) {
    const lines = [];
    lines.push(`Günlük Rapor (${todayKey()})`);
    lines.push(`Bugün eklenen: ${r.createdToday.length}`);
    lines.push(`Bugün düzenlenen: ${r.updatedToday.length}`);
    lines.push("");
    lines.push(`SKT yaklaşan (ilk 30):`);
    if (r.soon.length === 0) lines.push("—");
    else {
      for (const x of r.soon) {
        const it = x.it;
        const b = badgeForDaysLeft(x.left);
        lines.push(`- ${it.name} | ${it.qty} adet | SKT ${fmtTR(it.sktISO)} (${b.txt})`);
      }
    }
    return lines.join("\n");
  }

  function escapeHtml(s) {
    return String(s)
      .replaceAll("&","&amp;")
      .replaceAll("<","&lt;")
      .replaceAll(">","&gt;")
      .replaceAll('"',"&quot;")
      .replaceAll("'","&#39;");
  }

  // -----------------------------
  // CRUD
  // -----------------------------
  function removeItem(id) {
    const i = state.db.items.findIndex(x => x.id === id);
    if (i < 0) return;
    state.db.items.splice(i, 1);
    if (state.selectedId === id) state.selectedId = null;
    saveData();
    syncSelectionUI();
    render();
  }

  function upsertItem(item) {
    const i = state.db.items.findIndex(x => x.id === item.id);
    if (i >= 0) state.db.items[i] = item;
    else state.db.items.push(item);
    saveData();
  }

  // -----------------------------
  // Modal open/close
  // -----------------------------
  function openModalForNew() {
    state.editingId = null;
    modalTitle.textContent = "Ürün / Parti Ekle";
    btnDelete.style.display = "none";

    modeEl.value = "new";
    nameEl.value = "";
    qtyEl.value = "";
    teminEl.value = "Sipariş";
    dagitimNedeniEl.value = "";
    insertAdiEl.value = "";
    noteEl.value = "";

    wheelSKT.setISO(isoToday());
    wheelINS.setISO(isoToday());

    showModal();
    setTimeout(() => nameEl.focus(), 80);
  }

  function openModalForEdit(id) {
    const it = state.db.items.find(x => x.id === id);
    if (!it) return;
    state.editingId = id;
    modalTitle.textContent = "Düzenle";
    btnDelete.style.display = "inline-block";

    modeEl.value = "new";
    nameEl.value = it.name || "";
    qtyEl.value = String(it.qty ?? "");
    teminEl.value = it.temin || "Sipariş";
    dagitimNedeniEl.value = it.dagitimNedeni || "";
    insertAdiEl.value = it.insertAdi || "";
    noteEl.value = it.note || "";

    wheelSKT.setISO(it.sktISO || isoToday());
    wheelINS.setISO(it.insertISO || isoToday());

    showModal();
    setTimeout(() => nameEl.focus(), 80);
  }

  function showModal() { modal.classList.add("show"); }
  function closeModal() { modal.classList.remove("show"); }

  // -----------------------------
  // Save from modal
  // -----------------------------
  function saveFromModal() {
    const name = (nameEl.value || "").trim();
    const qty = Number(qtyEl.value || 0);
    if (!name) { toast("İsim boş olamaz"); nameEl.focus(); return; }

    const sktISO = wheelSKT.getISO();
    const temin = teminEl.value || "Sipariş";
    const dagitimNedeni = dagitimNedeniEl.value || "";
    const insertAdi = (insertAdiEl.value || "").trim();
    const insertISO = insertAdi || dagitimNedeni ? wheelINS.getISO() : ""; // only meaningful when distribution/insert used
    const note = (noteEl.value || "").trim();

    const now = new Date().toISOString();

    if (state.editingId) {
      const old = state.db.items.find(x => x.id === state.editingId);
      if (!old) return;
      const updated = { ...old, name, qty, sktISO, temin, dagitimNedeni, insertAdi, insertISO, note, updatedISO: now };
      upsertItem(updated);
      state.selectedId = updated.id;
    } else {
      const it = mkItem({ name, qty, sktISO, temin, dagitimNedeni, insertAdi, insertISO, note });
      it.updatedISO = now;
      upsertItem(it);
      state.selectedId = it.id;
    }

    closeModal();
    syncSelectionUI();
    render();
    toast("Kaydedildi");
  }

  // -----------------------------
  // Events
  // -----------------------------
  btnSearch.addEventListener("click", () => {
    searchRow.classList.toggle("show");
    if (searchRow.classList.contains("show")) setTimeout(()=>qEl.focus(), 50);
    else { state.q=""; qEl.value=""; render(); }
  });

  qEl.addEventListener("input", () => {
    state.q = qEl.value || "";
    render();
  });

  btnMenu.addEventListener("click", () => drawer.classList.add("show"));
  menuClose.addEventListener("click", () => drawer.classList.remove("show"));
  drawer.addEventListener("click", (e) => { if (e.target === drawer) drawer.classList.remove("show"); });

  menuAdd.addEventListener("click", () => {
    drawer.classList.remove("show");
    openModalForNew();
  });

  menuExport.addEventListener("click", async () => {
    drawer.classList.remove("show");
    await doShareSelectedOrAll(true);
  });

  btnCloseModal.addEventListener("click", closeModal);
  modal.addEventListener("click", (e) => { if (e.target === modal) closeModal(); });

  btnSave.addEventListener("click", saveFromModal);

  btnDelete.addEventListener("click", () => {
    if (!state.editingId) return;
    removeItem(state.editingId);
    closeModal();
    toast("Silindi");
  });

  btnClearSel.addEventListener("click", () => {
    state.selectedId = null;
    syncSelectionUI();
    render();
  });

  btnShareTop.addEventListener("click", async () => {
    await doShareSelectedOrAll(true);
  });

  fabShare.addEventListener("click", async () => {
    await doShareSelectedOrAll(true);
  });

  // Enter flow: name -> qty -> save
  nameEl.addEventListener("keydown", (e) => {
    if (e.key === "Enter") { e.preventDefault(); qtyEl.focus(); }
  });
  qtyEl.addEventListener("keydown", (e) => {
    if (e.key === "Enter") { e.preventDefault(); saveFromModal(); }
  });

  tabs.forEach(t => t.addEventListener("click", () => setView(t.dataset.view)));

  // Initial
  syncSelectionUI();
  render();

})();
JS

# ---------------------------
# GitHub Actions workflow (stable Gradle)
# ---------------------------
cat > .github/workflows/android-apk.yml <<'YML'
name: Build Android APK (Offline WebView)

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Android SDK
        uses: android-actions/setup-android@v3

      - name: Install SDK packages
        run: |
          sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"

      - name: Install Gradle 8.2.1
        run: |
          curl -sL https://services.gradle.org/distributions/gradle-8.2.1-bin.zip -o gradle.zip
          unzip -q gradle.zip
          echo "$PWD/gradle-8.2.1/bin" >> $GITHUB_PATH
          gradle -v

      - name: Build Debug APK
        run: |
          gradle :app:assembleDebug --no-daemon

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: stok_kontrol-debug-apk
          path: app/build/outputs/apk/debug/app-debug.apk
YML

echo "✅ Proje dosyaları oluşturuldu."
echo "=== assets ==="
ls -la app/src/main/assets
