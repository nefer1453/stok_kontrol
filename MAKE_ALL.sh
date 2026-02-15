#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP_ID="com.nefer1453.stok_kontrol"
PKG_DIR="com/nefer1453/stok_kontrol"

echo "==> Temiz klasör yapısı"
mkdir -p .github/workflows
mkdir -p app/src/main/java/$PKG_DIR
mkdir -p app/src/main/assets
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/mipmap-anydpi-v26
mkdir -p app/src/main/res/values-v31

echo "==> settings.gradle"
cat > settings.gradle <<'GRADLE'
pluginManagement {
  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
  }
}
rootProject.name = "stok_kontrol"
include(":app")
GRADLE

echo "==> build.gradle (root)"
cat > build.gradle <<'GRADLE'
plugins {
  id "com.android.application" version "8.2.2" apply false
  id "org.jetbrains.kotlin.android" version "1.9.22" apply false
}
GRADLE

echo "==> gradle.properties"
cat > gradle.properties <<'PROP'
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official
PROP

echo "==> app/build.gradle"
cat > app/build.gradle <<'GRADLE'
plugins {
  id "com.android.application"
  id "org.jetbrains.kotlin.android"
}

android {
  namespace "com.nefer1453.stok_kontrol"
  compileSdk 34

  defaultConfig {
    applicationId "com.nefer1453.stok_kontrol"
    minSdk 26
    targetSdk 34
    versionCode 1
    versionName "1.0"
  }

  buildTypes {
    debug {
      debuggable true
      minifyEnabled false
    }
    release {
      minifyEnabled false
      proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
    }
  }

  compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
  }
  kotlinOptions { jvmTarget = "17" }
}

dependencies {
  implementation "org.jetbrains.kotlin:kotlin-stdlib:1.9.22"
  implementation "androidx.core:core-ktx:1.12.0"
  implementation "androidx.appcompat:appcompat:1.6.1"
  implementation "com.google.android.material:material:1.11.0"
}
GRADLE

echo "==> proguard-rules.pro"
cat > app/proguard-rules.pro <<'PRO'
# boş bırakılabilir
PRO

echo "==> themes.xml"
cat > app/src/main/res/values/themes.xml <<'XML'
<resources xmlns:tools="http://schemas.android.com/tools">
  <style name="Theme.StokKontrol" parent="Theme.MaterialComponents.DayNight.NoActionBar">
    <item name="colorPrimary">#1B5E20</item>      <!-- çimen yeşili -->
    <item name="colorPrimaryVariant">#0F3D15</item>
    <item name="colorSecondary">#1B5E20</item>
    <item name="android:statusBarColor">#1B5E20</item>
    <item name="android:navigationBarColor">#FFFFFF</item>
  </style>
</resources>
XML

echo "==> Launcher icon (XML) - PNG yok, ikon hatası biter (minSdk=26)"
cat > app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
XML

cat > app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
XML

cat > app/src/main/res/values/ic_launcher_background.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
  <color name="ic_launcher_background">#1B5E20</color>
</resources>
XML

cat > app/src/main/res/drawable/ic_launcher_foreground.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
  android:width="108dp"
  android:height="108dp"
  android:viewportWidth="108"
  android:viewportHeight="108">
  <path
    android:fillColor="#FFFFFF"
    android:pathData="M20,54c0,-19 15,-34 34,-34s34,15 34,34 -15,34 -34,34 -34,-15 -34,-34zm16,0c0,10 8,18 18,18s18,-8 18,-18 -8,-18 -18,-18 -18,8 -18,18z"/>
</vector>
XML

echo "==> AndroidManifest.xml"
cat > app/src/main/AndroidManifest.xml <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application
    android:label="stok_kontrol"
    android:theme="@style/Theme.StokKontrol"
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round"
    android:supportsRtl="true">

    <activity
      android:name=".MainActivity"
      android:exported="true"
      android:launchMode="singleTask">
      <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
      </intent-filter>
    </activity>

  </application>
</manifest>
XML

echo "==> MainActivity.kt (Android share bridge dahil)"
cat > app/src/main/java/$PKG_DIR/MainActivity.kt <<'KOT'
package com.nefer1453.stok_kontrol

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

  private lateinit var web: WebView

  class AndroidBridge(private val act: AppCompatActivity) {
    @JavascriptInterface
    fun share(text: String) {
      val sendIntent = Intent().apply {
        action = Intent.ACTION_SEND
        putExtra(Intent.EXTRA_TEXT, text)
        type = "text/plain"
      }
      act.startActivity(Intent.createChooser(sendIntent, "Paylaş"))
    }
  }

  @SuppressLint("SetJavaScriptEnabled")
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    web = WebView(this)
    setContentView(web)

    web.webViewClient = WebViewClient()
    web.webChromeClient = WebChromeClient()

    val s: WebSettings = web.settings
    s.javaScriptEnabled = true
    s.domStorageEnabled = true
    s.allowFileAccess = true
    s.allowContentAccess = true
    s.cacheMode = WebSettings.LOAD_DEFAULT

    web.addJavascriptInterface(AndroidBridge(this), "AndroidBridge")

    web.loadUrl("file:///android_asset/index.html")
  }

  override fun onBackPressed() {
    if (this::web.isInitialized && web.canGoBack()) web.goBack()
    else super.onBackPressed()
  }
}
KOT

echo "==> index.html (beyaz zemin + çimen yeşili, arama sağ üst, ürün ekle menüde)"
cat > app/src/main/assets/index.html <<'HTML'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <meta name="theme-color" content="#1B5E20" />
  <title>stok_kontrol</title>
  <style>
    :root{
      --bg:#ffffff; --fg:#0c0f0d; --muted:#6b7280;
      --g:#1B5E20; --g2:#0F3D15;
      --line:#e5e7eb; --card:#f7f8f7;
      --danger:#b91c1c; --ok:#15803d;
      --shadow:0 18px 60px rgba(0,0,0,.18);
      --r:16px;
    }
    *{box-sizing:border-box}
    body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;background:var(--bg);color:var(--fg)}
    header{
      position:sticky;top:0;z-index:10;
      display:flex;align-items:center;justify-content:space-between;gap:10px;
      padding:12px;background:var(--g);color:#fff;
    }
    .brand{font-weight:1000;letter-spacing:.2px}
    .iconbtn{border:0;background:rgba(255,255,255,.14);color:#fff;padding:10px 12px;border-radius:12px;font-weight:1000}
    main{padding:12px 12px 110px}
    .pillrow{display:flex;gap:8px;flex-wrap:wrap;margin:10px 0}
    .pill{background:#fff;border:1px solid var(--line);padding:8px 10px;border-radius:999px;font-weight:900}
    .searchWrap{display:none;position:sticky;top:56px;z-index:9;background:var(--bg);padding:10px 0}
    .search{width:100%;padding:12px;border-radius:14px;border:1px solid var(--line);font-size:16px}
    .grid{display:grid;grid-template-columns:1fr;gap:10px}
    .card{
      border:1px solid var(--line);border-radius:var(--r);
      background:#fff;padding:12px;box-shadow:0 10px 30px rgba(0,0,0,.06)
    }
    .row{display:flex;align-items:center;justify-content:space-between;gap:10px}
    .title{font-size:16px;font-weight:1000}
    .sub{font-size:13px;color:var(--muted);margin-top:4px}
    .tag{font-weight:1000;font-size:12px;padding:6px 10px;border-radius:999px;border:1px solid var(--line);background:var(--card)}
    .blinkRed{animation:blinkRed 2s infinite}
    .blinkGreen{animation:blinkGreen 2s infinite}
    @keyframes blinkRed{0%,49%{outline:2px solid transparent}50%,100%{outline:2px solid rgba(185,28,28,.85)}}
    @keyframes blinkGreen{0%,49%{outline:2px solid transparent}50%,100%{outline:2px solid rgba(21,128,61,.85)}}

    /* FAB paylaş: her zaman sağ altta (modal açıkken gizlenecek) */
    .shareFab{
      position:fixed;right:16px;bottom:18px;z-index:50;
      border:0;border-radius:18px;padding:14px 16px;
      background:#111827;color:#fff;font-weight:1000;box-shadow:var(--shadow)
    }

    /* Drawer */
    #drawerBack{position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;z-index:60}
    #drawer{position:fixed;left:0;top:0;bottom:0;width:82vw;max-width:360px;background:#fff;transform:translateX(-110%);
      transition:.18s;z-index:61;border-right:1px solid var(--line);padding:12px}
    #drawer.show{transform:translateX(0)}
    #drawerBack.show{display:block}
    .menuItem{width:100%;text-align:left;border:1px solid var(--line);background:#fff;border-radius:14px;padding:12px;font-weight:1000;margin:8px 0}

    /* Modal */
    #modalBack{position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;z-index:80}
    .modal{
      position:fixed;left:50%;top:50%;transform:translate(-50%,-50%);
      width:min(92vw,520px);max-height:min(86vh,720px);
      background:#fff;border:1px solid var(--line);border-radius:18px;
      box-shadow:var(--shadow);display:none;z-index:81;overflow:hidden;
    }
    .modal.show{display:block}
    #modalBack.show{display:block}
    .mHead{display:flex;justify-content:space-between;align-items:center;padding:12px 14px;background:var(--card);border-bottom:1px solid var(--line)}
    .mTitle{font-weight:1000}
    .mBody{padding:12px 14px;overflow:auto;max-height:calc(min(86vh,720px) - 112px)}
    .field{margin:10px 0}
    label{display:block;font-size:12px;color:var(--muted);font-weight:1000;margin-bottom:6px}
    input,select,textarea{width:100%;padding:12px;border-radius:14px;border:1px solid var(--line);font-size:16px}
    textarea{resize:vertical}

    /* Kaydet: modalın en altında sağda sabit */
    .mFoot{
      position:sticky;bottom:0;
      display:flex;justify-content:flex-end;gap:10px;
      padding:10px 14px;background:linear-gradient(180deg, rgba(255,255,255,.6), #fff);
      border-top:1px solid var(--line);
    }
    .btn{border:1px solid var(--line);background:#fff;border-radius:14px;padding:12px 14px;font-weight:1000}
    .btnPrimary{background:var(--g);color:#fff;border-color:transparent}
    .btnDanger{background:var(--danger);color:#fff;border-color:transparent}

    /* SKT Wheel (ay = NUMARA) */
    #dwBack{position:fixed;inset:0;background:rgba(0,0,0,.55);display:none;z-index:90}
    #dwSheet{
      position:fixed;left:50%;top:50%;transform:translate(-50%,-50%);
      width:min(92vw,420px);background:#fff;border-radius:18px;display:none;z-index:91;
      border:1px solid var(--line);box-shadow:var(--shadow);overflow:hidden;
    }
    #dwBack.show{display:block}
    #dwSheet.show{display:block}
    #dwHead{display:flex;justify-content:space-between;align-items:center;padding:12px 14px;background:var(--card);border-bottom:1px solid var(--line)}
    #dwTitle{font-weight:1000}
    #dwBody{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;padding:12px 14px}
    #dwActions{display:flex;justify-content:flex-end;gap:10px;padding:12px 14px;border-top:1px solid var(--line)}
  </style>
</head>
<body>

<header>
  <button id="menuBtn" class="iconbtn" title="Menü">≡</button>
  <div class="brand">stok_kontrol</div>
  <button id="searchBtn" class="iconbtn" title="Ara">⌕</button>
</header>

<main>
  <div id="searchWrap" class="searchWrap">
    <input id="q" class="search" placeholder="Ürün ara..." />
  </div>

  <div class="pillrow">
    <div id="pillCritical" class="pill">Kritik: 0</div>
    <div id="pillPrice" class="pill">Fiyat: 0</div>
    <div id="pillAll" class="pill">Toplam: 0</div>
  </div>

  <section>
    <h3>Kritik (SKT geldi)</h3>
    <div id="criticalList" class="grid"></div>
  </section>

  <section style="margin-top:14px">
    <h3>Fiyat zamanı (son 30 gün)</h3>
    <div id="priceList" class="grid"></div>
  </section>

  <section style="margin-top:14px">
    <h3>Tüm ürünler</h3>
    <div id="allList" class="grid"></div>
  </section>
</main>

<button id="shareFab" class="shareFab">Paylaş ↗</button>

<div id="drawerBack"></div>
<aside id="drawer">
  <button id="openAddFromMenu" class="menuItem">+ Ürün / Parti Ekle</button>
  <button id="copyBtn" class="menuItem">Listeyi Metin Olarak Kopyala</button>
</aside>

<div id="modalBack"></div>

<section id="modalAdd" class="modal" aria-modal="true" role="dialog">
  <div class="mHead">
    <div class="mTitle" id="addTitle">Ürün / Parti Ekle</div>
    <button class="btn" id="closeAdd">Kapat</button>
  </div>
  <div class="mBody">
    <div class="field">
      <label>Ürün Adı</label>
      <input id="pName" placeholder="Örn: Danet sucuk" />
    </div>
    <div class="field">
      <label>Adet</label>
      <input id="qty" inputmode="numeric" placeholder="Örn: 12" />
    </div>

    <div class="field">
      <label>Temin</label>
      <select id="supply">
        <option value="temin">Temin</option>
        <option value="siparis">Sipariş</option>
        <option value="dagi">Dağılım</option>
      </select>
    </div>

    <div id="siparisWrap" style="display:none">
      <div class="field"><label>Sipariş Veren</label><input id="siparisVeren" placeholder="İsim" /></div>
      <div class="field"><label>Sipariş Alan</label><input id="siparisAlan" placeholder="İsim" /></div>
    </div>

    <div id="dagiWrap" style="display:none">
      <div class="field">
        <label>Dağılım Nedeni</label>
        <select id="dagiNeden">
          <option value="iskonto">İskonto</option>
          <option value="inserte_hazirlik">İnserte Hazırlık</option>
        </select>
      </div>
      <div class="field" id="insertNameWrap" style="display:none">
        <label>Insert Adı</label>
        <input id="insertName" placeholder="Örn: 14 Şubat" />
      </div>
      <div class="field" id="insertDateWrap" style="display:none">
        <label>Insert Tarihi (serbest / takvim yazısı)</label>
        <input id="insertDateText" placeholder="Örn: 14-25 / 02" />
      </div>
    </div>

    <div class="field">
      <label>Not</label>
      <textarea id="note" rows="2" placeholder="Ek bilgi..."></textarea>
    </div>

    <div class="field">
      <label>Fiyat isteme eşiği (gün) — örn 30</label>
      <input id="priceDays" inputmode="numeric" placeholder="Örn: 30" />
    </div>

    <input id="skt" type="hidden" />
  </div>
  <div class="mFoot">
    <button id="saveAdd" class="btn btnPrimary">Kaydet</button>
  </div>
</section>

<section id="modalActions" class="modal" aria-modal="true" role="dialog">
  <div class="mHead">
    <div class="mTitle" id="actTitle">İşlem</div>
    <button class="btn" id="closeAct">Kapat</button>
  </div>
  <div class="mBody">
    <button id="actEdit" class="menuItem">Düzenle</button>
    <button id="actRemove" class="menuItem" style="border-color:#fecaca">Kaldır</button>
  </div>
</section>

<section id="modalRemove" class="modal" aria-modal="true" role="dialog">
  <div class="mHead">
    <div class="mTitle">Kaldırma Nedeni</div>
    <button class="btn" id="closeRem">Kapat</button>
  </div>
  <div class="mBody">
    <div class="field">
      <label>Neden</label>
      <select id="remReason">
        <option value="skt">SKT</option>
        <option value="fabrika">Fabrika kaynaklı</option>
        <option value="kirilma">Kırık / zarar gördü</option>
        <option value="diger">Diğer</option>
      </select>
    </div>
    <div class="field">
      <label>Not</label>
      <input id="remNote" placeholder="Örn: koli ezilmiş..." />
    </div>
    <div class="mFoot">
      <button id="confirmRem" class="btn btnDanger">Onayla</button>
    </div>
  </div>
</section>

<div id="dwBack"></div>
<div id="dwSheet" role="dialog" aria-modal="true">
  <div id="dwHead">
    <div id="dwTitle">SKT Tarihi</div>
    <button id="dwClose" class="btn" type="button">Kapat</button>
  </div>
  <div id="dwBody">
    <select id="dwDay"></select>
    <select id="dwMonth"></select>
    <select id="dwYear"></select>
  </div>
  <div id="dwActions">
    <button id="dwToday" class="btn" type="button">Bugün</button>
    <button id="dwOk" class="btn btnPrimary" type="button">Tamam</button>
  </div>
</div>

<script src="app.js"></script>
</body>
</html>
HTML

echo "==> app.js (kayıt kaybolmaz + edit kaybolmaz + share Android sheet + modal açıkken share gizlenir)"
cat > app/src/main/assets/app.js <<'JS'
(function(){
  "use strict";
  const $ = (id)=>document.getElementById(id);
  const LS_KEY = "stok_kontrol_state_v3";

  const pad2 = (n)=>String(n).padStart(2,"0");
  const iso = (y,m,d)=>`${y}-${pad2(m)}-${pad2(d)}`;
  const parseISO = (s)=>{
    const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(s||""));
    if(!m) return null;
    return {y:+m[1], mo:+m[2], d:+m[3]};
  };
  const today = ()=>{
    const t=new Date(); t.setHours(0,0,0,0);
    return t;
  };
  const daysUntil = (isoDate)=>{
    const p=parseISO(isoDate);
    if(!p) return 99999;
    const a=new Date(p.y, p.mo-1, p.d); a.setHours(0,0,0,0);
    return Math.round((a - today())/86400000);
  };
  const esc = (s)=>String(s||"").replace(/[&<>"']/g, c=>({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[c]));

  function load(){
    try{
      const raw=localStorage.getItem(LS_KEY);
      if(!raw) return { products: [] };
      const st=JSON.parse(raw);
      if(!st || !Array.isArray(st.products)) return { products: [] };
      return st;
    }catch(_){ return { products: [] }; }
  }
  function save(){ localStorage.setItem(LS_KEY, JSON.stringify(state)); }

  let state = load();
  let selectedId = null;
  let editId = null;
  let currentShareMode = "all"; // all | critical | price

  // Drawer
  function openDrawer(){ $("drawerBack").classList.add("show"); $("drawer").classList.add("show"); }
  function closeDrawer(){ $("drawerBack").classList.remove("show"); $("drawer").classList.remove("show"); }

  // Modal helpers
  function anyModalOpen(){
    return ["modalAdd","modalActions","modalRemove"].some(id=>$(id).classList.contains("show"));
  }
  function openModal(id){
    $("modalBack").classList.add("show");
    $(id).classList.add("show");
    $("shareFab").style.display = "none"; // Kaydetin üstüne binmesin
  }
  function closeModal(id){
    $(id).classList.remove("show");
    if(!anyModalOpen()){
      $("modalBack").classList.remove("show");
      $("shareFab").style.display = "";
    }
  }
  function closeAllModals(){
    ["modalAdd","modalActions","modalRemove"].forEach(id=>$(id).classList.remove("show"));
    $("modalBack").classList.remove("show");
    $("shareFab").style.display = "";
  }

  // Wheel
  function ensureWheel(){
    const day=$("dwDay"), mo=$("dwMonth"), yr=$("dwYear");
    if(day.options.length===0) for(let i=1;i<=31;i++) day.add(new Option(String(i), String(i)));
    if(mo.options.length===0) for(let i=1;i<=12;i++) mo.add(new Option(String(i), String(i))); // AY NUMARA
    if(yr.options.length===0){
      const t=new Date().getFullYear();
      for(let y=t-1;y<=t+6;y++) yr.add(new Option(String(y), String(y)));
    }
  }
  function showWheel(currentIso){
    ensureWheel();
    const p=parseISO(currentIso);
    const t=new Date();
    $("dwDay").value = String(p?.d ?? t.getDate());
    $("dwMonth").value = String(p?.mo ?? (t.getMonth()+1));
    $("dwYear").value = String(p?.y ?? t.getFullYear());
    $("dwBack").classList.add("show");
    $("dwSheet").classList.add("show");
  }
  function hideWheel(){
    $("dwBack").classList.remove("show");
    $("dwSheet").classList.remove("show");
  }
  function wheelValue(){
    const y=+$("dwYear").value, m=+$("dwMonth").value, d=+$("dwDay").value;
    return iso(y,m,d);
  }

  // UI
  function toast(msg){
    const old=document.title;
    document.title=msg;
    setTimeout(()=>{ document.title=old; }, 800);
  }

  function refreshSupplyUI(){
    const v=$("supply").value;
    $("siparisWrap").style.display = (v==="siparis") ? "block" : "none";
    $("dagiWrap").style.display = (v==="dagi") ? "block" : "none";
    const dn=$("dagiNeden").value;
    const showInsert=(v==="dagi" && dn==="inserte_hazirlik");
    $("insertNameWrap").style.display = showInsert ? "block" : "none";
    $("insertDateWrap").style.display = showInsert ? "block" : "none";
  }

  function fillForm(p){
    $("pName").value = p?.name || "";
    $("qty").value = (p?.qty ?? "");
    $("supply").value = p?.supply || "temin";
    $("siparisVeren").value = p?.siparisVeren || "";
    $("siparisAlan").value = p?.siparisAlan || "";
    $("dagiNeden").value = p?.dagiNeden || "iskonto";
    $("insertName").value = p?.insertName || "";
    $("insertDateText").value = p?.insertDateText || "";
    $("note").value = p?.note || "";
    $("priceDays").value = (p?.priceDays ?? "30");
    $("skt").value = p?.skt || "";
    refreshSupplyUI();
  }

  function openAddNew(){
    editId=null;
    $("addTitle").textContent="Ürün / Parti Ekle";
    fillForm(null);
    openModal("modalAdd");
    setTimeout(()=>$("pName").focus(), 50);
  }

  function openEdit(id){
    const p=state.products.find(x=>x.id===id && !x.removed);
    if(!p){ toast("Ürün yok"); return; }
    editId=id;
    $("addTitle").textContent="Düzenle";
    fillForm(p);
    closeModal("modalActions");
    openModal("modalAdd");
    setTimeout(()=>$("pName").focus(), 50);
  }

  function openActions(id){
    const p=state.products.find(x=>x.id===id && !x.removed);
    if(!p) return;
    selectedId=id;
    $("actTitle").textContent=p.name || "İşlem";
    openModal("modalActions");
  }

  function doRemove(id, reason, note){
    const p=state.products.find(x=>x.id===id && !x.removed);
    if(!p) return;
    p.removed=true;
    p.removedAt=Date.now();
    p.removeReason=reason;
    p.removeNote=note||"";
    save();
    render();
  }

  function getFiltered(){
    const q=($("q").value||"").trim().toLowerCase();
    let arr=state.products.filter(p=>!p.removed);
    if(q) arr=arr.filter(p=>String(p.name||"").toLowerCase().includes(q));
    arr.sort((a,b)=>(b.createdAt||0)-(a.createdAt||0));
    return arr;
  }

  function cardHTML(p){
    const d=daysUntil(p.skt);
    const critical = d < 0;
    const pd = Number(p.priceDays||0);
    const priceHit = pd>0 && d<=pd && d>=0;

    let cls="card";
    if(critical) cls+=" blinkRed";
    else if(priceHit) cls+=" blinkGreen";

    const tag = (d===99999) ? "-" : (d<0 ? "GEÇTİ" : (d+"g"));
    return `
      <div class="${cls}" data-id="${p.id}">
        <div class="row">
          <div class="title">${esc(p.name)}</div>
          <div class="tag">${tag}</div>
        </div>
        <div class="sub">Adet: ${p.qty||0} • SKT: ${esc(p.skt||"-")} • Temin: ${esc(p.supply||"-")}</div>
      </div>
    `;
  }

  function render(){
    const arr=getFiltered();
    const critical=arr.filter(p=>daysUntil(p.skt) < 0);
    const price=arr.filter(p=>{
      const d=daysUntil(p.skt);
      const pd=Number(p.priceDays||0);
      return pd>0 && d<=pd && d>=0;
    });

    $("pillCritical").textContent="Kritik: "+critical.length;
    $("pillPrice").textContent="Fiyat: "+price.length;
    $("pillAll").textContent="Toplam: "+arr.length;

    $("criticalList").innerHTML = critical.map(cardHTML).join("") || `<div class="sub">Yok</div>`;
    $("priceList").innerHTML    = price.map(cardHTML).join("") || `<div class="sub">Yok</div>`;
    $("allList").innerHTML      = arr.map(cardHTML).join("") || `<div class="sub">Henüz ürün yok</div>`;

    // click bindings
    ["criticalList","priceList","allList"].forEach(listId=>{
      const el=$(listId);
      el.querySelectorAll("[data-id]").forEach(node=>{
        node.addEventListener("click", ()=>openActions(node.getAttribute("data-id")));
      });
    });

    // paylaşım modu: kullanıcı hangi bölümdeyse ona göre (scroll’a göre basit)
    // En üstte hangi başlık görünüyorsa onu baz alalım:
    // (Basit/sağlam: share her zaman filtreli listeyi paylaşır; q varsa q’ya göre.)
    // currentShareMode sadece metin başlığı için:
    currentShareMode = "all";
  }

  function currentShareText(){
    const arr=getFiltered();

    // Ekran mantığı: kritik + fiyat + tüm ürünler var.
    // Paylaş: 3 blok halinde üret
    const critical = arr.filter(p=>daysUntil(p.skt) < 0);
    const price = arr.filter(p=>{
      const d=daysUntil(p.skt);
      const pd=Number(p.priceDays||0);
      return pd>0 && d<=pd && d>=0;
    });

    const fmt = (p)=>{
      const d=daysUntil(p.skt);
      const pd=Number(p.priceDays||0);
      const tag = d<0 ? "KRİTİK" : (pd>0 && d<=pd ? "FİYAT" : "NORMAL");
      return `- ${p.name} | ${p.qty} adet | SKT ${p.skt} | ${tag}`;
    };

    let out=[];
    out.push("stok_kontrol");
    out.push("");
    out.push("KRİTİK (SKT geçti):");
    out.push(critical.length ? critical.map(fmt).join("\n") : "- Yok");
    out.push("");
    out.push("FİYAT ZAMANI (son 30 gün vb):");
    out.push(price.length ? price.map(fmt).join("\n") : "- Yok");
    out.push("");
    out.push("TÜM ÜRÜNLER:");
    out.push(arr.length ? arr.map(fmt).join("\n") : "- Yok");

    return out.join("\n");
  }

  async function shareText(text){
    text=String(text||"").trim();
    if(!text){ toast("Paylaşacak şey yok"); return; }

    // APK/WebView: AndroidBridge ile açılır
    if(window.AndroidBridge && typeof window.AndroidBridge.share==="function"){
      try{ window.AndroidBridge.share(text); return; }catch(_){}
    }

    // Tarayıcı testinde: Web Share varsa dener, yoksa kopyalar
    if(navigator.share){
      try{ await navigator.share({ text }); return; }catch(_){}
    }
    try{
      await navigator.clipboard.writeText(text);
      toast("Kopyalandı (tarayıcı testi)");
    }catch(_){
      toast("Kopyalanamadı");
    }
  }

  // Save flow: Kaydet -> SKT wheel -> Tamam -> kaydet
  function stageSave(){
    const name=($("pName").value||"").trim();
    const qty=parseInt(($("qty").value||"0"),10)||0;
    if(!name){ toast("Ürün adı lazım"); $("pName").focus(); return; }
    if(qty<=0){ toast("Adet 0 olamaz"); $("qty").focus(); return; }

    const skt=($("skt").value||"").trim();
    if(!skt){ showWheel(""); return; }
    finalizeSave();
  }

  function finalizeSave(){
    const now=Date.now();
    const obj={
      id: editId || ("p_"+now+"_"+Math.random().toString(16).slice(2)),
      name: ($("pName").value||"").trim(),
      qty: parseInt(($("qty").value||"0"),10)||0,
      skt: ($("skt").value||"").trim(),
      supply: $("supply").value,
      siparisVeren: ($("siparisVeren").value||"").trim(),
      siparisAlan: ($("siparisAlan").value||"").trim(),
      dagiNeden: $("dagiNeden").value,
      insertName: ($("insertName").value||"").trim(),
      insertDateText: ($("insertDateText").value||"").trim(),
      note: ($("note").value||"").trim(),
      priceDays: parseInt(($("priceDays").value||"0"),10)||0,
      createdAt: now
    };

    if(editId){
      const i=state.products.findIndex(x=>x.id===editId);
      if(i>=0){
        obj.createdAt = state.products[i].createdAt || obj.createdAt;
        state.products[i]=obj;
      }else{
        state.products.push(obj);
      }
    }else{
      state.products.push(obj);
    }

    save();
    render();

    // hızlı seri giriş: kaydedince form temizle + kapat
    editId=null;
    fillForm(null);
    closeModal("modalAdd");
    toast("Kaydedildi");
  }

  function bind(){
    $("menuBtn").addEventListener("click", openDrawer);
    $("drawerBack").addEventListener("click", closeDrawer);

    $("openAddFromMenu").addEventListener("click", ()=>{ closeDrawer(); openAddNew(); });

    $("copyBtn").addEventListener("click", async ()=>{
      const t=currentShareText();
      try{ await navigator.clipboard.writeText(t); toast("Kopyalandı"); }catch(_){ toast("Kopyalanamadı"); }
      closeDrawer();
    });

    $("searchBtn").addEventListener("click", ()=>{
      const w=$("searchWrap");
      w.style.display = (w.style.display==="block") ? "none" : "block";
      if(w.style.display==="block") setTimeout(()=>$("q").focus(), 30);
    });

    $("q").addEventListener("input", render);

    $("modalBack").addEventListener("click", closeAllModals);
    $("closeAdd").addEventListener("click", ()=>closeModal("modalAdd"));
    $("closeAct").addEventListener("click", ()=>closeModal("modalActions"));
    $("closeRem").addEventListener("click", ()=>closeModal("modalRemove"));

    $("supply").addEventListener("change", refreshSupplyUI);
    $("dagiNeden").addEventListener("change", refreshSupplyUI);

    $("pName").addEventListener("keydown", (e)=>{ if(e.key==="Enter"){ e.preventDefault(); $("qty").focus(); }});
    $("qty").addEventListener("keydown", (e)=>{ if(e.key==="Enter"){ e.preventDefault(); stageSave(); }});
    $("saveAdd").addEventListener("click", stageSave);

    $("actEdit").addEventListener("click", ()=>openEdit(selectedId));
    $("actRemove").addEventListener("click", ()=>{
      closeModal("modalActions");
      openModal("modalRemove");
    });

    $("confirmRem").addEventListener("click", ()=>{
      const reason=$("remReason").value;
      const note=$("remNote").value||"";
      doRemove(selectedId, reason, note);
      $("remNote").value="";
      closeModal("modalRemove");
      toast("Kaldırıldı");
    });

    $("dwClose").addEventListener("click", hideWheel);
    $("dwBack").addEventListener("click", hideWheel);
    $("dwToday").addEventListener("click", ()=>{
      const t=new Date();
      $("dwDay").value=String(t.getDate());
      $("dwMonth").value=String(t.getMonth()+1);
      $("dwYear").value=String(t.getFullYear());
    });
    $("dwOk").addEventListener("click", ()=>{
      $("skt").value = wheelValue();
      hideWheel();
      finalizeSave();
    });

    $("shareFab").addEventListener("click", ()=>{
      shareText(currentShareText());
    });

    refreshSupplyUI();
    render();
  }

  window.addEventListener("load", bind);
})();
JS

echo "==> GitHub Actions: wrapper yok, direkt gradle kullan"
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

      - name: Set up Gradle
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: 8.2.1

      - name: Build Debug APK
        run: gradle :app:assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/app-debug.apk
YML

echo "✅ Tüm dosyalar yazıldı."
