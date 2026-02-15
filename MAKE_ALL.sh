#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ========== PROJE AYAR ==========
PKG="com.nefer1453.stok_kontrol"
APPNAME="stok_kontrol"
ASSETS="app/src/main/assets"
JAVA_DIR="app/src/main/java/com/nefer1453/stok_kontrol"
RESVAL="app/src/main/res/values"
WF=".github/workflows"

mkdir -p "$ASSETS" "$JAVA_DIR" "$RESVAL" "$WF"

# ========== settings.gradle ==========
cat > settings.gradle <<'GRADLE'
pluginManagement {
  repositories { gradlePluginPortal(); google(); mavenCentral() }
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories { google(); mavenCentral() }
}
rootProject.name = "stok_kontrol"
include(":app")
GRADLE

# ========== root build.gradle ==========
cat > build.gradle <<'GRADLE'
plugins {
  id "com.android.application" version "8.2.2" apply false
  id "org.jetbrains.kotlin.android" version "1.9.22" apply false
}
GRADLE

# ========== gradle.properties ==========
cat > gradle.properties <<'PROP'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official
PROP

# ========== app/build.gradle ==========
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

# ========== proguard ==========
cat > app/proguard-rules.pro <<'TXT'
# boş
TXT

# ========== AndroidManifest ==========
cat > app/src/main/AndroidManifest.xml <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

  <uses-permission android:name="android.permission.INTERNET"/>

  <application
      android:label="Stok Kontrol"
      android:icon="@mipmap/ic_launcher"
      android:roundIcon="@mipmap/ic_launcher_round"
      android:theme="@style/Theme.StokKontrol">
    <activity
        android:name=".MainActivity"
        android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>

</manifest>
XML

# ========== themes.xml ==========
cat > "$RESVAL/themes.xml" <<'XML'
<resources>
  <style name="Theme.StokKontrol" parent="Theme.AppCompat.Light.NoActionBar">
    <item name="colorPrimary">#2e7d32</item>
    <item name="colorPrimaryDark">#1b5e20</item>
    <item name="colorAccent">#2e7d32</item>
  </style>
</resources>
XML

# ========== MainActivity.kt ==========
cat > "$JAVA_DIR/MainActivity.kt" <<'KOT'
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
KOT

# ========== GitHub Actions workflow ==========
cat > "$WF/android-apk.yml" <<'YML'
name: Build Android APK (Offline WebView)

on:
  workflow_dispatch:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: "temurin"
          java-version: "17"

      - name: Set up Android SDK
        uses: android-actions/setup-android@v3

      - name: Set up Gradle
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: "8.2.1"

      - name: Build Debug APK
        run: gradle :app:assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: stok_kontrol-debug-apk
          path: app/build/outputs/apk/debug/app-debug.apk
YML

# ========== index.html ==========
cat > "$ASSETS/index.html" <<'HTML'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <meta name="theme-color" content="#2e7d32" />
  <title>Stok Kontrol</title>
  <style>
    :root{
      --bg:#ffffff;
      --fg:#0c1410;
      --muted:#6b7280;
      --card:#ffffff;
      --line:#e5e7eb;
      --green:#2e7d32;
      --green2:#1b5e20;
      --red:#d32f2f;
      --amber:#f59e0b;
      --shadow: 0 14px 40px rgba(0,0,0,.08);
      --radius: 16px;
    }
    *{box-sizing:border-box}
    body{
      margin:0;
      font-family: system-ui,-apple-system,Segoe UI,Roboto,Arial;
      background:var(--bg);
      color:var(--fg);
    }

    header{
      position:sticky; top:0; z-index:20;
      background:linear-gradient(180deg,#ffffff,#f8fafc);
      border-bottom:1px solid var(--line);
      padding:10px 12px;
      display:flex; align-items:center; gap:10px;
    }
    .iconbtn{
      border:1px solid var(--line);
      background:#fff;
      border-radius:12px;
      padding:10px 12px;
      font-weight:900;
      box-shadow:0 6px 20px rgba(0,0,0,.06);
    }
    .title{
      font-weight:900;
      color:var(--green2);
      letter-spacing:.2px;
    }
    .spacer{flex:1}
    #searchBtn{
      border:1px solid rgba(46,125,50,.35);
      background:rgba(46,125,50,.07);
      color:var(--green2);
    }

    main{padding:12px 12px 90px}

    .pillbar{
      display:flex; gap:8px; flex-wrap:wrap;
      margin:10px 0;
    }
    .pill{
      border:1px solid var(--line);
      background:#fff;
      border-radius:999px;
      padding:8px 10px;
      font-weight:800;
      color:#14532d;
    }

    .sectionTitle{
      font-size:14px;
      color:var(--muted);
      margin:14px 4px 8px;
      font-weight:900;
      text-transform:uppercase;
      letter-spacing:.06em;
    }

    .grid{
      display:grid;
      grid-template-columns: 1fr;
      gap:10px;
    }
    .card{
      background:var(--card);
      border:1px solid var(--line);
      border-radius:var(--radius);
      padding:12px;
      box-shadow:0 10px 26px rgba(0,0,0,.06);
    }
    .row{display:flex; gap:10px; align-items:center}
    .grow{flex:1}
    .name{font-weight:950}
    .meta{color:var(--muted); font-weight:800; font-size:13px; margin-top:2px}
    .badge{
      font-weight:950;
      padding:6px 10px;
      border-radius:999px;
      border:1px solid var(--line);
      background:#fff;
      color:#111827;
      font-size:12px;
    }
    .badge.red{border-color:rgba(211,47,47,.35); background:rgba(211,47,47,.06); color:#7f1d1d}
    .badge.green{border-color:rgba(46,125,50,.35); background:rgba(46,125,50,.06); color:#14532d}
    .badge.amber{border-color:rgba(245,158,11,.35); background:rgba(245,158,11,.08); color:#7c2d12}

    /* Blink (2sn periyot) */
    @keyframes blink2 { 0%,49%{opacity:1} 50%,100%{opacity:.25} }
    .blink-red { border-color:rgba(211,47,47,.5) !important; animation:blink2 2s infinite; }
    .blink-green { border-color:rgba(46,125,50,.5) !important; animation:blink2 2s infinite; }

    /* Drawer */
    #drawerBack{
      position:fixed; inset:0;
      background:rgba(0,0,0,.35);
      opacity:0; pointer-events:none;
      transition:.15s; z-index:50;
    }
    #drawerBack.show{opacity:1; pointer-events:auto}
    #drawer{
      position:fixed; left:0; top:0; bottom:0;
      width:min(86vw,320px);
      background:#fff;
      transform:translateX(-105%);
      transition:.18s;
      z-index:60;
      border-right:1px solid var(--line);
      box-shadow:var(--shadow);
      padding:12px;
    }
    #drawer.show{transform:translateX(0)}
    .navbtn{
      width:100%;
      text-align:left;
      padding:12px;
      border-radius:14px;
      border:1px solid var(--line);
      background:#fff;
      font-weight:900;
      margin-bottom:10px;
    }
    .navbtn.primary{
      border-color:rgba(46,125,50,.35);
      background:rgba(46,125,50,.06);
      color:var(--green2);
    }

    /* Modal */
    #modalBack{
      position:fixed; inset:0;
      background:rgba(0,0,0,.42);
      opacity:0; pointer-events:none;
      transition:.15s;
      z-index:80;
    }
    #modalBack.show{opacity:1; pointer-events:auto}
    .modal{
      position:fixed; left:50%; top:50%;
      transform:translate(-50%,-50%);
      width:min(94vw,520px);
      background:#fff;
      border:1px solid var(--line);
      border-radius:18px;
      box-shadow:0 18px 60px rgba(0,0,0,.25);
      display:none;
      z-index:90;
      overflow:hidden;
    }
    .modal.show{display:block}
    .mhead{
      padding:12px 14px;
      border-bottom:1px solid var(--line);
      display:flex; gap:10px; align-items:center;
      background:linear-gradient(180deg,#fff,#f8fafc);
    }
    .mhead .mtitle{font-weight:950; color:var(--green2)}
    .mbody{padding:12px 14px}
    .actions{display:flex; gap:10px; justify-content:flex-end; padding:12px 14px; border-top:1px solid var(--line); background:#fff}
    .btn{
      border:1px solid var(--line);
      background:#fff;
      border-radius:14px;
      padding:10px 12px;
      font-weight:950;
    }
    .btn.primary{
      border-color:rgba(46,125,50,.35);
      background:rgba(46,125,50,.08);
      color:var(--green2);
    }
    .btn.danger{
      border-color:rgba(211,47,47,.35);
      background:rgba(211,47,47,.08);
      color:#7f1d1d;
    }

    .field{margin:10px 0}
    label{display:block; font-size:12px; color:var(--muted); font-weight:900; margin:0 0 6px 2px}
    input,select,textarea{
      width:100%;
      padding:12px;
      border-radius:14px;
      border:1px solid var(--line);
      font-weight:800;
      outline:none;
      background:#fff;
    }
    textarea{resize:vertical}

    /* Share FAB */
    #shareFab{
      position:fixed; right:16px; bottom:16px;
      z-index:120;
      border-radius:18px;
      border:2px solid rgba(46,125,50,.35);
      background:rgba(46,125,50,.12);
      color:var(--green2);
      padding:12px 14px;
      font-weight:950;
      box-shadow:0 16px 46px rgba(0,0,0,.18);
    }

    /* Search modal quick */
    #searchBox{display:none}
    #searchBox.show{display:block}

    /* Date Wheel (Sheet) */
    #dwBack{
      position:fixed; inset:0;
      background:rgba(0,0,0,.55);
      opacity:0; pointer-events:none;
      transition:.15s;
      z-index:200;
    }
    #dwBack.show{opacity:1; pointer-events:auto}
    #dwSheet{
      position:fixed; left:50%; bottom:-420px;
      transform:translateX(-50%);
      width:min(96vw,520px);
      background:#fff;
      border:1px solid var(--line);
      border-radius:18px 18px 0 0;
      box-shadow:0 -18px 60px rgba(0,0,0,.25);
      transition:.18s;
      z-index:210;
      overflow:hidden;
    }
    #dwSheet.show{bottom:0}
    #dwHead{
      padding:12px 14px;
      border-bottom:1px solid var(--line);
      display:flex; align-items:center; gap:10px;
      background:linear-gradient(180deg,#fff,#f8fafc);
    }
    #dwTitle{font-weight:950; color:var(--green2)}
    #dwBody{
      display:flex; gap:10px;
      padding:14px;
    }
    .dwCol{flex:1}
    .dwCol select{
      height:210px;
      font-size:18px;
      font-weight:950;
      text-align:center;
      border-radius:16px;
      padding:8px;
    }
    #dwActions{
      display:flex; gap:10px; justify-content:flex-end;
      padding:12px 14px;
      border-top:1px solid var(--line);
      background:#fff;
    }
  </style>
</head>
<body>

<header>
  <button id="menuBtn" class="iconbtn" title="Menü">≡</button>
  <div class="title">Stok Kontrol</div>
  <div class="spacer"></div>
  <button id="searchBtn" class="iconbtn" title="Ara">Ara</button>
</header>

<main>
  <div class="pillbar">
    <div class="pill" id="statPill">Toplam: 0</div>
    <div class="pill" id="todayPill">Bugün kaldırılan: 0</div>
  </div>

  <div class="sectionTitle">Ana Uyarılar</div>
  <div class="grid" id="homeAlerts"></div>

  <div class="sectionTitle" id="listTitle">Tüm Ürünler</div>
  <div class="grid" id="allList"></div>
</main>

<button id="shareFab">Paylaş ↗</button>

<div id="drawerBack"></div>
<aside id="drawer">
  <button class="navbtn primary" id="navAdd">+ Ürün / Parti Ekle</button>
  <button class="navbtn" id="navHome">Ana Liste</button>
  <button class="navbtn" id="navRemoved">Kaldırılanlar</button>
  <button class="navbtn" id="navBackup">Yedek</button>
  <button class="navbtn" id="navRestore">Geri Yükle</button>
</aside>

<div id="modalBack"></div>

<!-- Add/Edit Modal -->
<section class="modal" id="modalAdd">
  <div class="mhead">
    <div class="mtitle" id="addTitle">Ürün / Parti</div>
    <div class="spacer"></div>
    <button class="btn" id="closeAdd">Kapat</button>
  </div>
  <div class="mbody">
    <div class="field">
      <label>İsim</label>
      <input id="pName" placeholder="Örn: Aytaç sosis" />
    </div>

    <div class="field">
      <label>Adet</label>
      <input id="qty" inputmode="numeric" placeholder="Örn: 15" />
    </div>

    <div class="field">
      <label>SKT (Kaydet deyince wheel açılır)</label>
      <!-- görünür input yok: sadece value tutmak için -->
      <input id="skt" type="hidden" />
      <div class="meta" id="sktPreview">SKT: seçilmedi</div>
    </div>

    <div class="field">
      <label>Temin</label>
      <select id="supply">
        <option value="siparis">Sipariş</option>
        <option value="dagi">Dağılım</option>
        <option value="merkez">Merkez Dağılım</option>
      </select>
    </div>

    <div id="supplySiparis" style="display:none">
      <div class="field">
        <label>Sipariş veren</label>
        <input id="siparisVeren" placeholder="İsim" />
      </div>
      <div class="field">
        <label>Sipariş alan</label>
        <input id="siparisAlan" placeholder="İsim" />
      </div>
    </div>

    <div id="supplyDagi" style="display:none">
      <div class="field">
        <label>Neden</label>
        <select id="dagiNeden">
          <option value="iskonto">İskonto</option>
          <option value="inserte_hazirlik">İnserte hazırlık</option>
          <option value="diger">Diğer</option>
        </select>
      </div>

      <div class="field" id="insertNameWrap" style="display:none">
        <label>Insert adı</label>
        <input id="insertAdi" placeholder="Örn: Şubat Insert" />
      </div>

      <div class="field" id="insertDateWrap" style="display:none">
        <label>Insert tarihi (ister wheel ister takvim)</label>
        <div class="row">
          <select id="insertDateMode" style="max-width:170px">
            <option value="wheel">Kayar</option>
            <option value="calendar">Takvim</option>
          </select>
          <div class="grow"></div>
        </div>
        <input id="insertTarihiWheel" type="hidden" />
        <input id="insertTarihiCal" type="date" style="display:none" />
        <div class="meta" id="insertPreview">Insert: seçilmedi</div>
      </div>
    </div>

    <div class="field">
      <label>Not</label>
      <textarea id="note" rows="2" placeholder="Ek bilgi..."></textarea>
    </div>

    <div class="field">
      <label>Uyarı Ayarı (gün)</label>
      <div class="row">
        <div class="grow">
          <label style="margin-top:0">Kırmızı (SKT'ye kaç gün kala)</label>
          <input id="warnRedDays" inputmode="numeric" placeholder="Örn: 5" />
        </div>
        <div class="grow">
          <label style="margin-top:0">Fiyat iste (kaç gün kala)</label>
          <input id="priceAskDays" inputmode="numeric" placeholder="Örn: 30" />
        </div>
      </div>
      <div class="meta">SKT geçmiş/gelmiş: kırmızı blink. Fiyat zamanı: yeşil blink.</div>
    </div>

  </div>
  <div class="actions">
    <button class="btn primary" id="saveAdd">Kaydet</button>
  </div>
</section>

<!-- Action Sheet (Edit/Remove) -->
<section class="modal" id="modalAct">
  <div class="mhead">
    <div class="mtitle" id="actTitle">Ürün</div>
    <div class="spacer"></div>
    <button class="btn" id="closeAct">Kapat</button>
  </div>
  <div class="mbody">
    <div class="meta" id="actMeta"></div>
  </div>
  <div class="actions">
    <button class="btn" id="actEdit">Düzenle</button>
    <button class="btn danger" id="actRemove">Kaldır</button>
  </div>
</section>

<!-- Remove Modal -->
<section class="modal" id="modalRem">
  <div class="mhead">
    <div class="mtitle">Kaldır</div>
    <div class="spacer"></div>
    <button class="btn" id="closeRem">Kapat</button>
  </div>
  <div class="mbody">
    <div class="field">
      <label>Neden</label>
      <select id="remReason">
        <option value="skt">SKT</option>
        <option value="fabrika">Fabrika kaynaklı</option>
        <option value="kirik">Kırık / zarar gördü</option>
        <option value="diger">Diğer</option>
      </select>
    </div>
    <div class="field">
      <label>Not</label>
      <input id="remNote" placeholder="Örn: koli ezilmiş..." />
    </div>
  </div>
  <div class="actions">
    <button class="btn primary" id="confirmRem">Onayla</button>
  </div>
</section>

<!-- Search Modal -->
<section class="modal" id="modalSearch">
  <div class="mhead">
    <div class="mtitle">Ara</div>
    <div class="spacer"></div>
    <button class="btn" id="closeSearch">Kapat</button>
  </div>
  <div class="mbody">
    <div class="field">
      <label>Ürün ara</label>
      <input id="q" placeholder="Yaz ve liste filtrelensin..." />
    </div>
    <div class="meta">Arama, Tüm Ürünler listesini filtreler.</div>
  </div>
</section>

<!-- Date Wheel Sheet -->
<div id="dwBack"></div>
<div id="dwSheet" role="dialog" aria-modal="true">
  <div id="dwHead">
    <div id="dwTitle">Tarih</div>
    <div class="spacer"></div>
    <button id="dwClose" class="btn" type="button">Kapat</button>
  </div>
  <div id="dwBody">
    <div class="dwCol"><select id="dwDay"></select></div>
    <div class="dwCol"><select id="dwMonth"></select></div>
    <div class="dwCol"><select id="dwYear"></select></div>
  </div>
  <div id="dwActions">
    <button id="dwToday" class="btn" type="button">Bugün</button>
    <button id="dwOk" class="btn primary" type="button">Tamam</button>
  </div>
</div>

<script src="app.js"></script>
</body>
</html>
HTML

# ========== app.js ==========
cat > "$ASSETS/app.js" <<'JS'
(function(){
  "use strict";
  const $ = (id)=>document.getElementById(id);
  const $$ = (sel, p=document)=>Array.from(p.querySelectorAll(sel));

  // ---------- Storage ----------
  const KEY="stok_kontrol_state_v1";
  const defaultState = ()=>({
    products: [],   // {id,name, createdAt, warnRedDays, priceAskDays}
    lots: [],       // {id, productId, qty, skt, supply, siparisVeren, siparisAlan, dagiNeden, insertAdi, insertTarihi, insertDateMode, note, createdAt}
    removed: [],    // {time, productId, productName, reason, note}
  });

  function load(){
    try{
      const s = JSON.parse(localStorage.getItem(KEY) || "null");
      if(!s) return defaultState();
      if(!Array.isArray(s.products)) s.products=[];
      if(!Array.isArray(s.lots)) s.lots=[];
      if(!Array.isArray(s.removed)) s.removed=[];
      return s;
    }catch(_){ return defaultState(); }
  }
  function save(state){ localStorage.setItem(KEY, JSON.stringify(state)); }

  // ---------- Helpers ----------
  const pad2=(n)=>String(n).padStart(2,"0");
  const uid=()=>Math.random().toString(16).slice(2)+Date.now().toString(16);
  function isoToday(){
    const d=new Date(); return `${d.getFullYear()}-${pad2(d.getMonth()+1)}-${pad2(d.getDate())}`;
  }
  function daysUntil(iso){
    // iso: YYYY-MM-DD
    const t = new Date(iso+"T00:00:00");
    const now = new Date(); now.setHours(0,0,0,0);
    return Math.round((t.getTime()-now.getTime())/86400000);
  }
  function fmtIsoTR(iso){
    // 2026-02-14 -> 14.02.2026
    const [y,m,d]=iso.split("-"); return `${d}.${m}.${y}`;
  }

  // nearest lot per product: earliest SKT among active lots
  function nearestLot(state, productId){
    const lots = state.lots.filter(x=>x.productId===productId);
    if(!lots.length) return null;
    lots.sort((a,b)=> (a.skt||"9999-99-99").localeCompare(b.skt||"9999-99-99"));
    return lots[0];
  }

  // ---------- UI base ----------
  function openDrawer(){ $("drawerBack").classList.add("show"); $("drawer").classList.add("show"); }
  function closeDrawer(){ $("drawerBack").classList.remove("show"); $("drawer").classList.remove("show"); }

  function openModal(id){
    $("modalBack").classList.add("show");
    $(id).classList.add("show");
  }
  function closeModal(id){
    $(id).classList.remove("show");
    // başka modal açık mı?
    const anyOpen = $$(".modal").some(m=>m.classList.contains("show"));
    if(!anyOpen) $("modalBack").classList.remove("show");
  }
  function closeAllModals(){
    $$(".modal").forEach(m=>m.classList.remove("show"));
    $("modalBack").classList.remove("show");
  }

  // ---------- Date Wheel ----------
  // SKT: month MUST be numeric (01-12). We already show numeric in wheel.
  // For Temin insert: can use wheel or calendar. Wheel shows numeric too (safe).
  let wheelTarget = null; // {kind:"skt"|"insert", onDone(iso)}
  function dwFill(){
    const day=$("dwDay"), mon=$("dwMonth"), yr=$("dwYear");
    day.innerHTML=""; mon.innerHTML=""; yr.innerHTML="";
    for(let d=1; d<=31; d++){
      const o=document.createElement("option");
      o.value=pad2(d); o.textContent=pad2(d);
      day.appendChild(o);
    }
    for(let m=1; m<=12; m++){
      const o=document.createElement("option");
      o.value=pad2(m); o.textContent=pad2(m); // NUMARA
      mon.appendChild(o);
    }
    const y0=(new Date()).getFullYear();
    for(let y=y0-1; y<=y0+6; y++){
      const o=document.createElement("option");
      o.value=String(y); o.textContent=String(y);
      yr.appendChild(o);
    }
  }
  function dwSet(iso){
    const [y,m,d]=iso.split("-");
    $("dwYear").value=y;
    $("dwMonth").value=m;
    $("dwDay").value=d;
  }
  function dwGet(){
    const y=$("dwYear").value;
    const m=$("dwMonth").value;
    let d=$("dwDay").value;
    // month day clamp
    const max = new Date(Number(y), Number(m), 0).getDate();
    if(Number(d) > max) d = pad2(max);
    return `${y}-${m}-${d}`;
  }
  function dwOpen(title, initialIso, onDone){
    wheelTarget = { onDone };
    $("dwTitle").textContent = title;
    $("dwBack").classList.add("show");
    $("dwSheet").classList.add("show");
    dwSet(initialIso || isoToday());
  }
  function dwClose(){
    $("dwBack").classList.remove("show");
    $("dwSheet").classList.remove("show");
    wheelTarget = null;
  }

  // ---------- Supply toggles ----------
  function applySupplyUI(){
    const v = $("supply").value;
    $("supplySiparis").style.display = (v==="siparis") ? "block":"none";
    $("supplyDagi").style.display = (v==="dagi" || v==="merkez") ? "block":"none";
    // dağılım neden -> insert alanı
    const n = $("dagiNeden").value;
    const showInsert = (n==="inserte_hazirlik");
    $("insertNameWrap").style.display = showInsert ? "block":"none";
    $("insertDateWrap").style.display = showInsert ? "block":"none";
  }

  function applyInsertDateMode(){
    const mode = $("insertDateMode").value;
    $("insertTarihiCal").style.display = (mode==="calendar") ? "block":"none";
  }

  // ---------- Rendering ----------
  let state = load();
  let filterQ = "";
  let currentView = "all"; // "all" | "removed"
  let selectedProductId = null;

  function updatePills(){
    $("statPill").textContent = `Toplam: ${state.products.length}`;
    const today = isoToday();
    const todayRemoved = state.removed.filter(x=> (new Date(x.time)).toISOString().slice(0,10)===today).length;
    $("todayPill").textContent = `Bugün kaldırılan: ${todayRemoved}`;
  }

  function buildAlerts(){
    const wrap = $("homeAlerts");
    wrap.innerHTML = "";

    // rules:
    // 1) SKT <= 0 (expired or today) => RED blink, show only name + SKT
    // 2) priceAskDays rule: if daysUntil(skt) <= priceAskDays AND >=0 => GREEN blink
    const alerts = [];

    for(const p of state.products){
      const lot = nearestLot(state, p.id);
      if(!lot || !lot.skt) continue;
      const d = daysUntil(lot.skt);

      // red: expired or today (d<=0)
      if(d <= 0){
        alerts.push({
          type:"red",
          key:`red-${p.id}`,
          name:p.name,
          skt:lot.skt,
          text:`SKT: ${fmtIsoTR(lot.skt)}`
        });
        continue;
      }

      const priceAskDays = Number(p.priceAskDays || 0);
      if(priceAskDays > 0 && d <= priceAskDays){
        alerts.push({
          type:"green",
          key:`green-${p.id}`,
          name:p.name,
          skt:lot.skt,
          text:`Fiyat iste (${d} gün): ${fmtIsoTR(lot.skt)}`
        });
      }
    }

    if(!alerts.length){
      const c = document.createElement("div");
      c.className="card";
      c.innerHTML = `<div class="name">Şimdilik uyarı yok</div><div class="meta">SKT / fiyat iste uyarısı oluşunca burada görünür.</div>`;
      wrap.appendChild(c);
      return;
    }

    for(const a of alerts){
      const c = document.createElement("div");
      c.className = "card";
      if(a.type==="red") c.classList.add("blink-red");
      if(a.type==="green") c.classList.add("blink-green");

      c.innerHTML = `
        <div class="row">
          <div class="grow">
            <div class="name">${escapeHtml(a.name)}</div>
            <div class="meta">${escapeHtml(a.text)}</div>
          </div>
          <div class="badge ${a.type==="red"?"red":"green"}">${a.type==="red"?"SKT":"FİYAT"}</div>
        </div>
      `;
      // click opens action sheet too
      c.addEventListener("click", ()=>{
        const pid = state.products.find(x=>x.name===a.name)?.id;
        if(pid) openActions(pid);
      });
      wrap.appendChild(c);
    }
  }

  function renderAllList(){
    $("listTitle").textContent = (currentView==="all") ? "Tüm Ürünler" : "Kaldırılanlar";
    const wrap = $("allList");
    wrap.innerHTML="";

    if(currentView==="removed"){
      if(!state.removed.length){
        const c=document.createElement("div");
        c.className="card";
        c.innerHTML=`<div class="name">Kaldırılan yok</div>`;
        wrap.appendChild(c);
        return;
      }
      // newest first
      const arr=[...state.removed].sort((a,b)=>b.time-a.time);
      for(const r of arr){
        const c=document.createElement("div");
        c.className="card";
        const dt = new Date(r.time);
        const when = `${pad2(dt.getDate())}.${pad2(dt.getMonth()+1)}.${dt.getFullYear()} ${pad2(dt.getHours())}:${pad2(dt.getMinutes())}`;
        c.innerHTML = `
          <div class="row">
            <div class="grow">
              <div class="name">${escapeHtml(r.productName)}</div>
              <div class="meta">${escapeHtml(when)} • Neden: ${escapeHtml(r.reason)} ${r.note?("• "+escapeHtml(r.note)):""}</div>
            </div>
            <div class="badge amber">Kaldırıldı</div>
          </div>
        `;
        wrap.appendChild(c);
      }
      return;
    }

    // products list
    let arr = [...state.products];
    if(filterQ.trim()){
      const q = filterQ.trim().toLowerCase();
      arr = arr.filter(p=> p.name.toLowerCase().includes(q));
    }
    // sort by nearest skt
    arr.sort((a,b)=>{
      const la=nearestLot(state,a.id), lb=nearestLot(state,b.id);
      const sa=(la?.skt)||"9999-99-99", sb=(lb?.skt)||"9999-99-99";
      return sa.localeCompare(sb);
    });

    if(!arr.length){
      const c=document.createElement("div");
      c.className="card";
      c.innerHTML=`<div class="name">Liste boş</div><div class="meta">Menüden “+ Ürün / Parti Ekle” ile ekle.</div>`;
      wrap.appendChild(c);
      return;
    }

    for(const p of arr){
      const lot = nearestLot(state,p.id);
      const d = lot?.skt ? daysUntil(lot.skt) : null;

      let badge = `<div class="badge">Normal</div>`;
      let extraClass = "";

      if(lot?.skt){
        if(d <= 0){ badge = `<div class="badge red">SKT</div>`; extraClass="blink-red"; }
        else if(Number(p.priceAskDays||0)>0 && d <= Number(p.priceAskDays)){ badge = `<div class="badge green">FİYAT</div>`; extraClass="blink-green"; }
        else if(Number(p.warnRedDays||0)>0 && d <= Number(p.warnRedDays)){ badge = `<div class="badge amber">Yakın</div>`; }
      }

      const meta = lot?.skt
        ? `SKT: ${fmtIsoTR(lot.skt)} • Adet: ${lot.qty}`
        : `Parti yok`;

      const c=document.createElement("div");
      c.className="card";
      if(extraClass) c.classList.add(extraClass);
      c.innerHTML = `
        <div class="row">
          <div class="grow">
            <div class="name">${escapeHtml(p.name)}</div>
            <div class="meta">${escapeHtml(meta)}</div>
          </div>
          ${badge}
        </div>
      `;
      c.addEventListener("click", ()=> openActions(p.id));
      wrap.appendChild(c);
    }
  }

  function render(){
    updatePills();
    buildAlerts();
    renderAllList();
  }

  // ---------- Actions: Edit/Remove ----------
  function openActions(pid){
    selectedProductId = pid;
    const p = state.products.find(x=>x.id===pid);
    const lot = nearestLot(state, pid);
    $("actTitle").textContent = p?.name || "Ürün";
    $("actMeta").textContent = lot?.skt ? `SKT: ${fmtIsoTR(lot.skt)} • Adet: ${lot.qty}` : "Parti yok";
    openModal("modalAct");
  }

  function openEdit(pid){
    const p = state.products.find(x=>x.id===pid);
    if(!p) return;

    // edit uses same modalAdd
    $("addTitle").textContent = "Düzenle";
    $("pName").value = p.name;
    $("qty").value = String(nearestLot(state,p.id)?.qty || "");
    $("warnRedDays").value = p.warnRedDays ? String(p.warnRedDays) : "";
    $("priceAskDays").value = p.priceAskDays ? String(p.priceAskDays) : "";
    $("note").value = nearestLot(state,p.id)?.note || "";

    // supply fields from nearest lot (best effort)
    const lot = nearestLot(state,p.id);
    $("supply").value = lot?.supply || "siparis";
    $("siparisVeren").value = lot?.siparisVeren || "";
    $("siparisAlan").value = lot?.siparisAlan || "";
    $("dagiNeden").value = lot?.dagiNeden || "iskonto";
    $("insertAdi").value = lot?.insertAdi || "";
    $("insertDateMode").value = lot?.insertDateMode || "wheel";
    $("insertTarihiWheel").value = lot?.insertTarihi || "";
    $("insertTarihiCal").value = lot?.insertTarihi || "";
    $("insertPreview").textContent = lot?.insertTarihi ? `Insert: ${fmtIsoTR(lot.insertTarihi)}` : "Insert: seçilmedi";

    applySupplyUI();
    applyInsertDateMode();

    // store edit target on modal
    $("modalAdd").dataset.editing = pid;
    // show SKT preview from nearest lot
    if(lot?.skt){
      $("skt").value = lot.skt;
      $("sktPreview").textContent = `SKT: ${fmtIsoTR(lot.skt)}`;
    }else{
      $("skt").value = "";
      $("sktPreview").textContent = `SKT: seçilmedi`;
    }

    closeModal("modalAct");
    openModal("modalAdd");
    setTimeout(()=>{ try{$("pName").focus(); $("pName").select?.();}catch(_){ } }, 80);
  }

  function openRemove(pid){
    selectedProductId = pid;
    $("remReason").value = "skt";
    $("remNote").value = "";
    closeModal("modalAct");
    openModal("modalRem");
  }

  // ---------- Add / Save flow ----------
  function resetAddForm(){
    $("modalAdd").dataset.editing = "";
    $("addTitle").textContent = "Ürün / Parti";
    $("pName").value="";
    $("qty").value="";
    $("skt").value="";
    $("sktPreview").textContent="SKT: seçilmedi";
    $("supply").value="siparis";
    $("siparisVeren").value="";
    $("siparisAlan").value="";
    $("dagiNeden").value="iskonto";
    $("insertAdi").value="";
    $("insertDateMode").value="wheel";
    $("insertTarihiWheel").value="";
    $("insertTarihiCal").value="";
    $("insertPreview").textContent="Insert: seçilmedi";
    $("note").value="";
    $("warnRedDays").value="";
    $("priceAskDays").value="";
    applySupplyUI();
    applyInsertDateMode();
  }

  async function saveAddClick(){
    const name = ($("pName").value||"").trim();
    const qty = Number(($("qty").value||"").trim());
    if(!name){ toast("İsim lazım"); $("pName").focus(); return; }
    if(!Number.isFinite(qty) || qty<=0){ toast("Adet doğru değil"); $("qty").focus(); return; }

    // SKT wheel: senin istediğin gibi — ekranda sabit değil; Kaydet deyince pat diye açılır
    let currentSkt = ($("skt").value||"").trim();
    if(!currentSkt){
      dwOpen("SKT seç (AY=01-12)", isoToday(), (iso)=>{
        $("skt").value = iso;
        $("sktPreview").textContent = `SKT: ${fmtIsoTR(iso)}`;
        dwClose();
        // seçer seçmez kaydı tamamla
        finalizeSave(name, qty, iso);
      });
      return;
    }

    finalizeSave(name, qty, currentSkt);
  }

  function finalizeSave(name, qty, sktIso){
    const editing = ($("modalAdd").dataset.editing||"").trim();
    const supply = $("supply").value;
    const siparisVeren = ($("siparisVeren").value||"").trim();
    const siparisAlan = ($("siparisAlan").value||"").trim();
    const dagiNeden = $("dagiNeden").value;
    const insertAdi = ($("insertAdi").value||"").trim();
    const insertDateMode = $("insertDateMode").value;
    let insertTarihi = "";
    if(dagiNeden==="inserte_hazirlik"){
      if(insertDateMode==="calendar"){
        insertTarihi = ($("insertTarihiCal").value||"").trim();
      }else{
        insertTarihi = ($("insertTarihiWheel").value||"").trim();
      }
    }
    const note = ($("note").value||"").trim();

    const warnRedDays = Number(($("warnRedDays").value||"").trim()||0);
    const priceAskDays = Number(($("priceAskDays").value||"").trim()||0);

    // product record
    let pid = editing || null;
    if(!pid){
      pid = uid();
      state.products.push({
        id: pid,
        name,
        createdAt: Date.now(),
        warnRedDays: warnRedDays>0 ? warnRedDays : 0,
        priceAskDays: priceAskDays>0 ? priceAskDays : 0
      });
    }else{
      const p = state.products.find(x=>x.id===pid);
      if(p){
        p.name = name;
        p.warnRedDays = warnRedDays>0 ? warnRedDays : 0;
        p.priceAskDays = priceAskDays>0 ? priceAskDays : 0;
      }
      // eski lotları temizle (basit yaklaşım: nearest lot update)
      // burada: o ürünün ilk lotunu güncelleyelim, yoksa ekleyelim
    }

    // lot
    const existingLot = state.lots.find(x=>x.productId===pid);
    if(existingLot){
      existingLot.qty = qty;
      existingLot.skt = sktIso;
      existingLot.supply = supply;
      existingLot.siparisVeren = siparisVeren;
      existingLot.siparisAlan = siparisAlan;
      existingLot.dagiNeden = dagiNeden;
      existingLot.insertAdi = insertAdi;
      existingLot.insertTarihi = insertTarihi;
      existingLot.insertDateMode = insertDateMode;
      existingLot.note = note;
    }else{
      state.lots.push({
        id: uid(),
        productId: pid,
        qty,
        skt: sktIso,
        supply,
        siparisVeren,
        siparisAlan,
        dagiNeden,
        insertAdi,
        insertTarihi,
        insertDateMode,
        note,
        createdAt: Date.now()
      });
    }

    save(state);
    render();
    toast(editing ? "Güncellendi" : "Kaydedildi");

    // senin istediğin “akış”: isim boşalsın, imleç oraya dönsün
    resetAddForm();
    setTimeout(()=>{ try{$("pName").focus();}catch(_){ } }, 80);
  }

  // Insert tarihi wheel aç (temin kısmı için wheel/takvim ikisi de var)
  function pickInsertWheel(){
    const cur = ($("insertTarihiWheel").value||"").trim() || isoToday();
    dwOpen("Insert tarihi (AY=01-12)", cur, (iso)=>{
      $("insertTarihiWheel").value = iso;
      $("insertPreview").textContent = `Insert: ${fmtIsoTR(iso)}`;
      dwClose();
    });
  }

  // ---------- Remove ----------
  function confirmRemove(){
    const pid = selectedProductId;
    const p = state.products.find(x=>x.id===pid);
    if(!p){ closeModal("modalRem"); return; }
    const reason = $("remReason").value;
    const note = ($("remNote").value||"").trim();

    // remove product + lots
    state.products = state.products.filter(x=>x.id!==pid);
    state.lots = state.lots.filter(x=>x.productId!==pid);
    state.removed.push({ time: Date.now(), productId: pid, productName: p.name, reason, note });

    save(state);
    render();
    closeModal("modalRem");
    toast("Kaldırıldı");
    selectedProductId = null;
  }

  // ---------- Backup / Restore ----------
  function doBackup(){
    try{
      const blob = new Blob([localStorage.getItem(KEY)||""], {type:"application/json"});
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = "stok_kontrol_yedek.json";
      a.click();
      toast("Yedek indirildi");
    }catch(_){ toast("Yedek başarısız"); }
  }
  function doRestore(){
    const inp = document.createElement("input");
    inp.type="file";
    inp.accept="application/json";
    inp.onchange = async ()=>{
      const f = inp.files && inp.files[0];
      if(!f) return;
      const txt = await f.text();
      try{
        JSON.parse(txt);
        localStorage.setItem(KEY, txt);
        state = load();
        render();
        toast("Geri yüklendi");
      }catch(_){ toast("Dosya bozuk"); }
    };
    inp.click();
  }

  // ---------- Share ----------
  function visibleSection(){
    // hangi bölüm daha görünür? (alerts mi list mi)
    const a = $("homeAlerts").getBoundingClientRect();
    const l = $("allList").getBoundingClientRect();
    const vh = window.innerHeight || 800;
    const visA = Math.max(0, Math.min(a.bottom, vh) - Math.max(a.top, 0));
    const visL = Math.max(0, Math.min(l.bottom, vh) - Math.max(l.top, 0));
    return (visA >= visL) ? "alerts" : "list";
  }

  function shareText(){
    if(currentView==="removed"){
      const arr=[...state.removed].sort((a,b)=>b.time-a.time).slice(0,20);
      return "Kaldırılanlar:\n" + arr.map(r=>{
        const dt = new Date(r.time);
        const when = `${pad2(dt.getDate())}.${pad2(dt.getMonth()+1)}.${dt.getFullYear()}`;
        return `- ${r.productName} • ${when} • ${r.reason}${r.note?(" • "+r.note):""}`;
      }).join("\n");
    }

    const vs = visibleSection();
    if(vs==="alerts"){
      // build current alerts text
      const lines=[];
      for(const p of state.products){
        const lot = nearestLot(state,p.id);
        if(!lot?.skt) continue;
        const d=daysUntil(lot.skt);
        if(d<=0){
          lines.push(`- [SKT] ${p.name} • ${fmtIsoTR(lot.skt)}`);
        }else if(Number(p.priceAskDays||0)>0 && d<=Number(p.priceAskDays)){
          lines.push(`- [FİYAT] ${p.name} • ${d} gün • ${fmtIsoTR(lot.skt)}`);
        }
      }
      return lines.length ? ("Ana Uyarılar:\n"+lines.join("\n")) : "Ana Uyarılar: yok";
    }

    // list share
    let arr=[...state.products];
    if(filterQ.trim()){
      const q=filterQ.trim().toLowerCase();
      arr=arr.filter(p=>p.name.toLowerCase().includes(q));
    }
    arr=arr.slice(0,40);
    return "Ürün Listesi:\n" + arr.map(p=>{
      const lot=nearestLot(state,p.id);
      return `- ${p.name}${lot?.skt?(" • SKT "+fmtIsoTR(lot.skt)):""}`;
    }).join("\n");
  }

  async function doShare(){
    const text = shareText();
    try{
      if(navigator.share){
        await navigator.share({ text, title:"Stok Kontrol" });
      }else{
        await navigator.clipboard.writeText(text);
        toast("Paylaşım metni kopyalandı");
      }
    }catch(_){
      try{ await navigator.clipboard.writeText(text); toast("Kopyalandı"); }catch(__){ toast("Paylaşım olmadı"); }
    }
  }

  // ---------- Toast ----------
  let toastT = null;
  function toast(msg){
    clearTimeout(toastT);
    // mini toast: title pill’lerin yanına basit
    const el = document.createElement("div");
    el.style.position="fixed";
    el.style.left="12px";
    el.style.right="12px";
    el.style.bottom="76px";
    el.style.zIndex="999";
    el.style.background="rgba(17,24,39,.88)";
    el.style.color="#fff";
    el.style.padding="10px 12px";
    el.style.borderRadius="14px";
    el.style.fontWeight="900";
    el.style.textAlign="center";
    el.style.backdropFilter="blur(6px)";
    el.textContent=msg;
    document.body.appendChild(el);
    toastT=setTimeout(()=>{ try{el.remove();}catch(_){ } }, 1200);
  }

  function escapeHtml(s){
    return String(s).replace(/[&<>"']/g, (c)=>({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[c]));
  }

  // ---------- Events ----------
  function bind(){
    // drawer
    $("menuBtn").onclick=openDrawer;
    $("drawerBack").onclick=closeDrawer;

    $("navAdd").onclick=()=>{ closeDrawer(); resetAddForm(); openModal("modalAdd"); setTimeout(()=>{$("pName").focus();},80); };
    $("navHome").onclick=()=>{ closeDrawer(); currentView="all"; render(); };
    $("navRemoved").onclick=()=>{ closeDrawer(); currentView="removed"; render(); };
    $("navBackup").onclick=()=>{ closeDrawer(); doBackup(); };
    $("navRestore").onclick=()=>{ closeDrawer(); doRestore(); };

    // modals
    $("modalBack").onclick=closeAllModals;
    $("closeAdd").onclick=()=>closeModal("modalAdd");
    $("closeAct").onclick=()=>closeModal("modalAct");
    $("closeRem").onclick=()=>closeModal("modalRem");
    $("closeSearch").onclick=()=>closeModal("modalSearch");

    // search
    $("searchBtn").onclick=()=>{ openModal("modalSearch"); setTimeout(()=>{$("q").focus();},80); };
    $("q").addEventListener("input", ()=>{
      filterQ = $("q").value||"";
      render();
    });

    // share
    $("shareFab").onclick=doShare;

    // action sheet
    $("actEdit").onclick=()=>openEdit(selectedProductId);
    $("actRemove").onclick=()=>openRemove(selectedProductId);

    // remove
    $("confirmRem").onclick=confirmRemove;

    // add save
    $("saveAdd").onclick=saveAddClick;

    // supply changes
    $("supply").addEventListener("change", applySupplyUI);
    $("dagiNeden").addEventListener("change", applySupplyUI);
    $("insertDateMode").addEventListener("change", applyInsertDateMode);

    // insert date pickers
    $("insertTarihiCal").addEventListener("change", ()=>{
      const v=$("insertTarihiCal").value||"";
      $("insertPreview").textContent = v ? `Insert: ${fmtIsoTR(v)}` : "Insert: seçilmedi";
    });

    // “inserte hazırlık” seçilince wheel modundaysa preview’a tıklayınca wheel aç
    $("insertPreview").addEventListener("click", ()=>{
      const need = ($("dagiNeden").value==="inserte_hazirlik");
      if(!need) return;
      const mode = $("insertDateMode").value;
      if(mode==="wheel") pickInsertWheel();
      else $("insertTarihiCal").showPicker?.();
    });

    // wheel buttons
    $("dwBack").onclick=dwClose;
    $("dwClose").onclick=dwClose;
    $("dwToday").onclick=()=>dwSet(isoToday());
    $("dwOk").onclick=()=>{
      const iso = dwGet();
      if(wheelTarget?.onDone) wheelTarget.onDone(iso);
      // dwClose() wheelTarget.onDone çağıran yerde kapatılıyor (SKT akışında)
      if(wheelTarget) dwClose();
    };

    // wheel fill once
    dwFill();

    // Enter flow: name -> qty -> Save
    $("pName").addEventListener("keydown",(e)=>{
      if(e.key==="Enter"){ e.preventDefault(); $("qty").focus(); }
    });
    $("qty").addEventListener("keydown",(e)=>{
      if(e.key==="Enter"){ e.preventDefault(); $("saveAdd").click(); }
    });
  }

  // init
  document.addEventListener("DOMContentLoaded", ()=>{
    state = load();
    // supply ui defaults
    applySupplyUI();
    applyInsertDateMode();
    render();
    bind();
  });

})();
JS

echo "✅ Komple proje dosyaları yazıldı."
echo "=== assets ==="
ls -la "$ASSETS"
