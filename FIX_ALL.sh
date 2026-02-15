#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(pwd)"
ASSETS="$ROOT/app/src/main/assets"
JAVA="$ROOT/app/src/main/java/com/nefer1453/stok_kontrol"
# bazı projelerde paket adı farklı olabiliyor; klasörü bul:
JAVA_DIR="$(find "$ROOT/app/src/main/java" -maxdepth 6 -type d -path "*/*/*/stok_kontrol*" | head -n 1 || true)"
if [ -n "${JAVA_DIR:-}" ]; then
  JAVA="$JAVA_DIR"
fi

mkdir -p "$ASSETS"
mkdir -p "$JAVA"

TS="$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ROOT/_backup_$TS"
cp -f "$ASSETS/index.html" "$ROOT/_backup_$TS/index.html" 2>/dev/null || true
cp -f "$ASSETS/app.js" "$ROOT/_backup_$TS/app.js" 2>/dev/null || true
cp -f "$JAVA/MainActivity.kt" "$ROOT/_backup_$TS/MainActivity.kt" 2>/dev/null || true

echo "✅ Yedek alındı: _backup_$TS"

# -----------------------
# index.html (tam yaz)
# -----------------------
cat > "$ASSETS/index.html" <<'HTML'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <meta name="theme-color" content="#1b5e20" />
  <title>stok_kontrol</title>
  <style>
    :root{
      --bg:#ffffff;
      --fg:#0c0f0d;
      --muted:#6b7280;
      --green:#1b5e20;      /* çimen yeşili */
      --green2:#0f3d15;
      --danger:#b91c1c;
      --ok:#15803d;
      --card:#f3f5f4;
      --line:#e5e7eb;
      --shadow: 0 18px 60px rgba(0,0,0,.18);
      --radius:16px;
    }
    *{box-sizing:border-box}
    body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;background:var(--bg);color:var(--fg)}
    header{
      position:sticky;top:0;z-index:10;
      display:flex;gap:10px;align-items:center;justify-content:space-between;
      padding:12px 12px;background:var(--green);color:#fff;
    }
    .brand{font-weight:900;letter-spacing:.2px}
    .iconbtn{
      border:0;background:rgba(255,255,255,.14);color:#fff;
      padding:10px 12px;border-radius:12px;font-weight:900;
    }
    main{padding:12px 12px 96px}
    .pillrow{display:flex;gap:8px;flex-wrap:wrap;margin:10px 0}
    .pill{background:var(--card);border:1px solid var(--line);padding:8px 10px;border-radius:999px;font-weight:800}
    .searchWrap{display:none;position:sticky;top:56px;z-index:9;background:var(--bg);padding:10px 0}
    .search{width:100%;padding:12px 12px;border-radius:14px;border:1px solid var(--line);background:#fff;font-size:16px}
    .grid{display:grid;grid-template-columns:1fr;gap:10px}
    .card{
      border:1px solid var(--line);border-radius:var(--radius);
      background:#fff;padding:12px;box-shadow:0 10px 30px rgba(0,0,0,.06);
    }
    .row{display:flex;align-items:center;justify-content:space-between;gap:10px}
    .title{font-size:16px;font-weight:900}
    .sub{font-size:13px;color:var(--muted);margin-top:4px}
    .tag{font-weight:900;font-size:12px;padding:6px 10px;border-radius:999px;border:1px solid var(--line);background:var(--card)}
    .blinkRed{animation:blinkRed 2s infinite}
    .blinkGreen{animation:blinkGreen 2s infinite}
    @keyframes blinkRed{0%,49%{outline:2px solid transparent}50%,100%{outline:2px solid rgba(185,28,28,.85)}}
    @keyframes blinkGreen{0%,49%{outline:2px solid transparent}50%,100%{outline:2px solid rgba(21,128,61,.85)}}

    /* FAB */
    .fab{
      position:fixed;right:16px;bottom:18px;z-index:50;
      border:0;border-radius:18px;padding:14px 16px;
      background:var(--green);color:#fff;font-weight:1000;
      box-shadow:var(--shadow)
    }
    .shareFab{
      position:fixed;right:16px;bottom:78px;z-index:50;
      border:0;border-radius:16px;padding:10px 12px;
      background:#111827;color:#fff;font-weight:900;
      box-shadow:var(--shadow)
    }

    /* Drawer */
    #drawerBack{position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;z-index:60}
    #drawer{position:fixed;left:0;top:0;bottom:0;width:82vw;max-width:360px;background:#fff;transform:translateX(-110%);
      transition:.18s;z-index:61;border-right:1px solid var(--line);padding:12px}
    #drawer.show{transform:translateX(0)}
    #drawerBack.show{display:block}
    .menuItem{width:100%;text-align:left;border:1px solid var(--line);background:#fff;border-radius:14px;padding:12px;font-weight:900;margin:8px 0}

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
    label{display:block;font-size:12px;color:var(--muted);font-weight:900;margin-bottom:6px}
    input,select,textarea{
      width:100%;padding:12px;border-radius:14px;border:1px solid var(--line);font-size:16px
    }
    textarea{resize:vertical}
    /* Kaydet sticky */
    .mFoot{
      position:sticky;bottom:0;
      display:flex;justify-content:flex-end;gap:10px;
      padding:10px 14px;background:linear-gradient(180deg, rgba(255,255,255,.6), #fff);
      border-top:1px solid var(--line);
    }
    .btn{border:1px solid var(--line);background:#fff;border-radius:14px;padding:12px 14px;font-weight:1000}
    .btnPrimary{background:var(--green);color:#fff;border-color:transparent}
    .btnDanger{background:var(--danger);color:#fff;border-color:transparent}

    /* Wheel (Sadece SKT için) */
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
  <button id="exportBtn" class="menuItem">Listeyi Metin Olarak Kopyala</button>
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
      <input id="pName" placeholder="Örn: Aytaç sosis" />
    </div>
    <div class="field">
      <label>Adet</label>
      <input id="qty" inputmode="numeric" placeholder="Örn: 15" />
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
        <label>Neden</label>
        <select id="dagiNeden">
          <option value="iskonto">İskonto</option>
          <option value="inserte_hazirlik">İnserte Hazırlık</option>
        </select>
      </div>
      <div class="field" id="insertNameWrap" style="display:none">
        <label>Insert Adı</label>
        <input id="insertName" placeholder="Örn: Şubat Kampanya" />
      </div>
      <div class="field" id="insertDateWrap" style="display:none">
        <label>Insert Tarihi (serbest)</label>
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

    <!-- SKT gizli: kaydet basınca wheel açılacak -->
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

<!-- Wheel modal (SKT) -->
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

# -----------------------
# app.js (tam yaz)
# -----------------------
cat > "$ASSETS/app.js" <<'JS'
(function(){
  "use strict";

  const $ = (id)=>document.getElementById(id);
  const LS_KEY = "stok_kontrol_state_v2";

  const pad2 = (n)=>String(n).padStart(2,"0");
  const todayYMD = ()=>{
    const d=new Date();
    return {y:d.getFullYear(), m:d.getMonth()+1, day:d.getDate()};
  };
  const iso = (y,m,day)=>`${y}-${pad2(m)}-${pad2(day)}`;
  const parseISO = (s)=>{
    const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(s||""));
    if(!m) return null;
    return {y:+m[1], m:+m[2], day:+m[3]};
  };
  const daysUntil = (isoDate)=>{
    const p = parseISO(isoDate);
    if(!p) return 99999;
    const a = new Date(p.y, p.m-1, p.day);
    const b = new Date(); b.setHours(0,0,0,0);
    a.setHours(0,0,0,0);
    return Math.round((a-b)/86400000);
  };

  function load(){
    try{
      const raw = localStorage.getItem(LS_KEY);
      if(!raw) return { products: [] };
      const st = JSON.parse(raw);
      if(!st || !Array.isArray(st.products)) return { products: [] };
      return st;
    }catch(e){
      return { products: [] };
    }
  }
  function saveState(st){
    localStorage.setItem(LS_KEY, JSON.stringify(st));
  }

  let state = load();
  let selectedId = null;
  let editId = null;

  // ---------- Drawer ----------
  function openDrawer(){ $("drawerBack").classList.add("show"); $("drawer").classList.add("show"); }
  function closeDrawer(){ $("drawerBack").classList.remove("show"); $("drawer").classList.remove("show"); }

  // ---------- Modal helpers ----------
  function openModal(id){
    $("modalBack").classList.add("show");
    $(id).classList.add("show");
    // modal açıkken share butonu kaydetin üstüne binmesin
    $("shareFab").style.display = "none";
  }
  function closeModal(id){
    $(id).classList.remove("show");
    // başka modal var mı?
    const anyOpen = ["modalAdd","modalActions","modalRemove"].some(x=>$(x).classList.contains("show"));
    if(!anyOpen){
      $("modalBack").classList.remove("show");
      $("shareFab").style.display = "";
    }
  }
  function closeAllModals(){
    ["modalAdd","modalActions","modalRemove"].forEach(id=>$(id).classList.remove("show"));
    $("modalBack").classList.remove("show");
    $("shareFab").style.display = "";
  }

  // ---------- Wheel (SKT) ----------
  function ensureWheelOptions(){
    const day = $("dwDay"), mon = $("dwMonth"), yr = $("dwYear");
    if(day.options.length===0){
      for(let i=1;i<=31;i++) day.add(new Option(String(i), String(i)));
    }
    if(mon.options.length===0){
      for(let i=1;i<=12;i++) mon.add(new Option(String(i), String(i))); // ay NUMARA
    }
    if(yr.options.length===0){
      const t = todayYMD().y;
      for(let y=t-1; y<=t+6; y++) yr.add(new Option(String(y), String(y)));
    }
  }
  function showWheel(currentIso){
    ensureWheelOptions();
    const t = parseISO(currentIso) || todayYMD();
    $("dwDay").value = String(t.day);
    $("dwMonth").value = String(t.m);
    $("dwYear").value = String(t.y);

    $("dwBack").classList.add("show");
    $("dwSheet").classList.add("show");
  }
  function hideWheel(){
    $("dwBack").classList.remove("show");
    $("dwSheet").classList.remove("show");
  }
  function wheelValue(){
    const y = +$("dwYear").value;
    const m = +$("dwMonth").value;
    const d = +$("dwDay").value;
    return iso(y,m,d);
  }

  // ---------- Render ----------
  function cardHTML(p){
    const d = daysUntil(p.skt);
    const critical = d < 0;
    const priceHit = (Number(p.priceDays||0) > 0) && d <= Number(p.priceDays||0) && d >= 0;

    const cls = critical ? "card blinkRed" : (priceHit ? "card blinkGreen" : "card");
    const sktText = p.skt ? p.skt : "-";
    const sub = `Adet: ${p.qty||0} • SKT: ${sktText} • Temin: ${p.supply||"-"}`;
    return `
      <div class="${cls}" data-id="${p.id}">
        <div class="row">
          <div class="title">${escapeHtml(p.name||"")}</div>
          <div class="tag">${d===99999 ? "-" : (d<0 ? "GEÇTİ" : d+"g")}</div>
        </div>
        <div class="sub">${escapeHtml(sub)}</div>
      </div>
    `;
  }

  function escapeHtml(s){
    return String(s||"").replace(/[&<>"']/g, (c)=>({
      "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"
    }[c]));
  }

  function getFiltered(){
    const q = ($("q").value||"").trim().toLowerCase();
    let arr = state.products.filter(p=>!p.removed);
    if(q) arr = arr.filter(p=>String(p.name||"").toLowerCase().includes(q));
    // en yeni üstte
    arr.sort((a,b)=>(b.createdAt||0)-(a.createdAt||0));
    return arr;
  }

  function render(){
    const arr = getFiltered();
    const critical = arr.filter(p=>daysUntil(p.skt) < 0);
    const price = arr.filter(p=>{
      const d = daysUntil(p.skt);
      const pd = Number(p.priceDays||0);
      return pd>0 && d<=pd && d>=0;
    });

    $("pillCritical").textContent = "Kritik: " + critical.length;
    $("pillPrice").textContent = "Fiyat: " + price.length;
    $("pillAll").textContent = "Toplam: " + arr.length;

    $("criticalList").innerHTML = critical.map(cardHTML).join("") || `<div class="sub">Yok</div>`;
    $("priceList").innerHTML = price.map(cardHTML).join("") || `<div class="sub">Yok</div>`;
    $("allList").innerHTML = arr.map(cardHTML).join("") || `<div class="sub">Henüz ürün yok</div>`;

    // tıklama bağla
    ["criticalList","priceList","allList"].forEach(listId=>{
      const el = $(listId);
      el.querySelectorAll("[data-id]").forEach(node=>{
        node.addEventListener("click", ()=>{
          selectedId = node.getAttribute("data-id");
          openActionsForSelected();
        });
      });
    });
  }

  // ---------- Actions (Edit/Remove) ----------
  function openActionsForSelected(){
    const p = state.products.find(x=>x.id===selectedId);
    if(!p) return;
    $("actTitle").textContent = p.name || "İşlem";
    openModal("modalActions");
  }

  function fillAddForm(p){
    $("pName").value = p?.name || "";
    $("qty").value = p?.qty ?? "";
    $("supply").value = p?.supply || "temin";
    $("siparisVeren").value = p?.siparisVeren || "";
    $("siparisAlan").value = p?.siparisAlan || "";
    $("dagiNeden").value = p?.dagiNeden || "iskonto";
    $("insertName").value = p?.insertName || "";
    $("insertDateText").value = p?.insertDateText || "";
    $("note").value = p?.note || "";
    $("priceDays").value = p?.priceDays ?? "30";
    $("skt").value = p?.skt || "";
    refreshSupplyUI();
  }

  function refreshSupplyUI(){
    const v = $("supply").value;
    $("siparisWrap").style.display = (v==="siparis") ? "block" : "none";
    $("dagiWrap").style.display = (v==="dagi") ? "block" : "none";

    const dn = $("dagiNeden").value;
    const showInsert = (v==="dagi" && dn==="inserte_hazirlik");
    $("insertNameWrap").style.display = showInsert ? "block" : "none";
    $("insertDateWrap").style.display = showInsert ? "block" : "none";
  }

  // ---------- Save flow (Kaydet -> wheel -> tamam -> save) ----------
  function openAddNew(){
    editId = null;
    $("addTitle").textContent = "Ürün / Parti Ekle";
    fillAddForm(null);
    openModal("modalAdd");
    setTimeout(()=>{ $("pName").focus(); }, 50);
  }

  function openEdit(id){
    const p = state.products.find(x=>x.id===id);
    if(!p) return;
    editId = id;
    $("addTitle").textContent = "Düzenle";
    fillAddForm(p);
    closeModal("modalActions");
    openModal("modalAdd");
    setTimeout(()=>{ $("pName").focus(); }, 50);
  }

  function doRemove(id, reason, note){
    const p = state.products.find(x=>x.id===id);
    if(!p) return;
    p.removed = true;
    p.removedAt = Date.now();
    p.removeReason = reason;
    p.removeNote = note || "";
    saveState(state);
    render();
  }

  function stageSave(){
    const name = ($("pName").value||"").trim();
    const qty = parseInt(($("qty").value||"0"),10) || 0;
    if(!name){ toast("Ürün adı lazım"); $("pName").focus(); return; }
    if(qty<=0){ toast("Adet 0 olamaz"); $("qty").focus(); return; }

    // SKT yoksa önce wheel aç
    const skt = ($("skt").value||"").trim();
    if(!skt){
      showWheel("");
      return;
    }
    finalizeSave();
  }

  function finalizeSave(){
    const now = Date.now();
    const obj = {
      id: editId || ("p_"+now+"_"+Math.random().toString(16).slice(2)),
      name: ($("pName").value||"").trim(),
      qty: parseInt(($("qty").value||"0"),10) || 0,
      skt: ($("skt").value||"").trim(),
      supply: $("supply").value,
      siparisVeren: ($("siparisVeren").value||"").trim(),
      siparisAlan: ($("siparisAlan").value||"").trim(),
      dagiNeden: $("dagiNeden").value,
      insertName: ($("insertName").value||"").trim(),
      insertDateText: ($("insertDateText").value||"").trim(),
      note: ($("note").value||"").trim(),
      priceDays: parseInt(($("priceDays").value||"0"),10) || 0,
      createdAt: now
    };

    if(editId){
      const i = state.products.findIndex(x=>x.id===editId);
      if(i>=0){
        // createdAt korunmalı
        obj.createdAt = state.products[i].createdAt || obj.createdAt;
        state.products[i] = obj;
      }else{
        state.products.push(obj);
      }
    }else{
      state.products.push(obj);
    }

    saveState(state);
    render();

    // form temizle + tekrar isim alanına dön
    editId = null;
    fillAddForm(null);
    closeModal("modalAdd");
    toast("Kaydedildi");
    setTimeout(()=>{ openAddNew(); }, 80); // hızlı seri giriş: tekrar modal aç + imleç isimde
  }

  // ---------- Share ----------
  function currentVisibleText(){
    // Her zaman ekranda görünen 3 bölüm var; filtreye göre zaten daralıyor
    const arr = getFiltered();
    const lines = arr.slice(0, 200).map(p=>{
      const d = daysUntil(p.skt);
      const tag = d<0 ? "Kritik" : (p.priceDays && d<=p.priceDays ? "Fiyat" : "Normal");
      return `- ${p.name} | ${p.qty} adet | SKT ${p.skt} | ${tag}`;
    });
    return lines.join("\n") || "Liste boş.";
  }

  async function shareText(text){
    text = String(text||"").trim();
    if(!text){ toast("Paylaşacak bir şey yok"); return; }

    // 1) Android bridge (en sağlam)
    if(window.AndroidBridge && typeof window.AndroidBridge.share === "function"){
      try{ window.AndroidBridge.share(text); return; }catch(e){}
    }

    // 2) Web Share API (bazı WebView'larda çalışır)
    if(navigator.share){
      try{ await navigator.share({ text }); return; }catch(e){}
    }

    // 3) Son çare: kopyala
    try{
      await navigator.clipboard.writeText(text);
      toast("Kopyalandı (paylaşım desteklenmedi)");
    }catch(e){
      toast("Paylaşım yok, kopyalama da olmadı");
    }
  }

  // ---------- UI events ----------
  function toast(msg){
    // minimal toast: header title geçici değişsin
    const old = document.title;
    document.title = msg;
    setTimeout(()=>{ document.title = old; }, 900);
  }

  function bind(){
    $("menuBtn").addEventListener("click", openDrawer);
    $("drawerBack").addEventListener("click", closeDrawer);

    $("openAddFromMenu").addEventListener("click", ()=>{
      closeDrawer(); openAddNew();
    });

    $("exportBtn").addEventListener("click", async ()=>{
      const t = currentVisibleText();
      try{ await navigator.clipboard.writeText(t); toast("Kopyalandı"); }catch(e){ toast("Kopyalanamadı"); }
      closeDrawer();
    });

    $("searchBtn").addEventListener("click", ()=>{
      const w = $("searchWrap");
      w.style.display = (w.style.display==="block") ? "none" : "block";
      if(w.style.display==="block"){ setTimeout(()=>{ $("q").focus(); }, 30); }
    });

    $("q").addEventListener("input", render);

    $("modalBack").addEventListener("click", closeAllModals);
    $("closeAdd").addEventListener("click", ()=>closeModal("modalAdd"));
    $("closeAct").addEventListener("click", ()=>closeModal("modalActions"));
    $("closeRem").addEventListener("click", ()=>closeModal("modalRemove"));

    $("supply").addEventListener("change", refreshSupplyUI);
    $("dagiNeden").addEventListener("change", refreshSupplyUI);

    // Enter ile hız
    $("pName").addEventListener("keydown", (e)=>{ if(e.key==="Enter"){ e.preventDefault(); $("qty").focus(); }});
    $("qty").addEventListener("keydown", (e)=>{ if(e.key==="Enter"){ e.preventDefault(); stageSave(); }});

    $("saveAdd").addEventListener("click", stageSave);

    // Actions
    $("actEdit").addEventListener("click", ()=> openEdit(selectedId));
    $("actRemove").addEventListener("click", ()=>{
      closeModal("modalActions");
      openModal("modalRemove");
    });

    $("confirmRem").addEventListener("click", ()=>{
      const reason = $("remReason").value;
      const note = $("remNote").value||"";
      doRemove(selectedId, reason, note);
      $("remNote").value="";
      closeModal("modalRemove");
      toast("Kaldırıldı");
    });

    // Wheel buttons
    $("dwClose").addEventListener("click", hideWheel);
    $("dwBack").addEventListener("click", hideWheel);
    $("dwToday").addEventListener("click", ()=>{
      const t = todayYMD();
      $("dwDay").value = String(t.day);
      $("dwMonth").value = String(t.m);
      $("dwYear").value = String(t.y);
    });
    $("dwOk").addEventListener("click", ()=>{
      $("skt").value = wheelValue();
      hideWheel();
      finalizeSave();
    });

    // Share
    $("shareFab").addEventListener("click", ()=>{
      shareText(currentVisibleText());
    });

    refreshSupplyUI();
    render();
  }

  window.addEventListener("load", bind);
})();
JS

# -----------------------
# MainActivity.kt (Android share bridge)
# -----------------------
cat > "$JAVA/MainActivity.kt" <<'KOT'
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
            val chooser = Intent.createChooser(sendIntent, "Paylaş")
            act.startActivity(chooser)
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

        // Android paylaşım köprüsü
        web.addJavascriptInterface(AndroidBridge(this), "AndroidBridge")

        web.loadUrl("file:///android_asset/index.html")
    }

    override fun onBackPressed() {
        if (this::web.isInitialized && web.canGoBack()) web.goBack()
        else super.onBackPressed()
    }
}
KOT

echo "✅ index.html + app.js + MainActivity.kt yazıldı."
echo "✅ Backup klasörü: _backup_$TS"
