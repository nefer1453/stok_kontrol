set -e

echo "📦 Stok Kontrol Motoru v0.8 (sunulabilir veri mimarisi) kuruluyor..."

# Güvenlik yedeği
ts=$(date +%Y%m%d_%H%M%S)
mkdir -p _backup
[ -f index.html ] && cp -f index.html "_backup/index.html.$ts.bak" || true

cat > index.html <<'HTML'
<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Stok Kontrol</title>
<style>
  :root{
    --bg:#0b1020; --card:#0f172a; --line:#1f2a44; --txt:#e5e7eb; --mut:#94a3b8;
    --g:#16a34a; --r:#ef4444; --y:#f59e0b;
  }
  *{box-sizing:border-box}
  body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;background:var(--bg);color:var(--txt)}
  main{max-width:560px;margin:0 auto;padding:16px 14px 28px}
  .h1{font-weight:950;font-size:22px}
  .hint{color:var(--mut);font-size:12px;line-height:1.3}
  .card{background:linear-gradient(180deg, rgba(255,255,255,.06), rgba(255,255,255,.03));
        border:1px solid rgba(255,255,255,.10); border-radius:18px; padding:14px; margin:12px 0}
  .row{display:flex;gap:10px;align-items:center}
  .between{justify-content:space-between}
  input,select,textarea{
    width:100%; padding:14px 14px; border-radius:16px; border:1px solid rgba(255,255,255,.14);
    background:rgba(0,0,0,.20); color:var(--txt); outline:none; font-size:16px
  }
  textarea{min-height:86px; resize:vertical}
  .btn{
    border:1px solid rgba(255,255,255,.14);
    background:rgba(255,255,255,.06);
    color:var(--txt);
    padding:14px 14px;
    border-radius:16px;
    font-weight:900;
    cursor:pointer;
  }
  .btn:active{transform:scale(.99)}
  .btn.primary{background:rgba(22,163,74,.18); border-color:rgba(22,163,74,.35)}
  .btn.danger{background:rgba(239,68,68,.16); border-color:rgba(239,68,68,.34)}
  .btn.warn{background:rgba(245,158,11,.16); border-color:rgba(245,158,11,.34)}
  .pill{display:inline-flex;gap:6px;align-items:center;padding:8px 10px;border-radius:999px;
        border:1px solid rgba(255,255,255,.12); background:rgba(0,0,0,.15); font-size:12px; color:var(--mut)}
  .list{display:flex;flex-direction:column;gap:10px}
  .item{border:1px solid rgba(255,255,255,.10); background:rgba(0,0,0,.14); border-radius:16px; padding:12px}
  .name{font-weight:950}
  .hr{height:1px;background:rgba(255,255,255,.10);margin:10px 0}
  .grid2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
  .grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px}
  .modal{position:fixed;inset:0;background:rgba(0,0,0,.55);display:none;align-items:flex-end;z-index:99}
  .modal.open{display:flex}
  .sheet{
    width:100%; max-width:560px; margin:0 auto;
    background:rgba(15,23,42,.96); border:1px solid rgba(255,255,255,.12);
    border-radius:18px 18px 0 0; padding:14px; padding-bottom:18px
  }
</style>
</head>
<body>
<main>
  <div class="card">
    <div class="row between">
      <div>
        <div class="h1">Stok Kontrol</div>
        <div class="hint">v0.8 • Sunulabilir veri mimarisi (işlem log + alt kırılımlar)</div>
      </div>
      <span class="pill" id="meta">—</span>
    </div>

    <div class="hr"></div>

    <div class="hint" style="margin-bottom:6px">Ürün adı</div>
    <input id="pName" placeholder="örn: Kaşar 1kg" />

    <div class="row" style="margin-top:10px">
      <button class="btn primary" id="btnAdd">Ürün Ekle</button>
      <button class="btn" id="btnOps">İşlem Ekle</button>
    </div>

    <div class="hint" style="margin-top:8px">İşlem ekle: ürün seç → tür/alt tür → +/− adet → kaydet.</div>
  </div>

  <div class="card">
    <div class="row between">
      <div style="font-weight:950">Ürünler</div>
      <input id="q" type="search" placeholder="Ara..." style="max-width:220px">
    </div>
    <div class="hint" id="info" style="margin-top:8px"></div>
    <div class="hr"></div>
    <div id="list" class="list"></div>
  </div>
</main>

<!-- İşlem Modal -->
<div class="modal" id="dlg">
  <div class="sheet">
    <div class="row between">
      <div class="h1" style="font-size:18px">İşlem Ekle</div>
      <button class="btn" id="dlgClose" style="padding:10px 12px">Kapat</button>
    </div>

    <div class="hint" style="margin:8px 0 6px">Ürün</div>
    <select id="opProd"></select>

    <div class="hint" style="margin:10px 0 6px">Ana tür</div>
    <select id="opType">
      <option value="siparis">Sipariş (Artırır)</option>
      <option value="dagitim">Dağılım (Artırır)</option>
      <option value="satis">Satış (Azaltır)</option>
      <option value="iade">İade / Zayi (Azaltır)</option>
      <option value="skt">SKT (Azaltır)</option>
      <option value="fiyat">Fiyat İsteme (Not)</option>
      <option value="not">Not (Not)</option>
    </select>

    <div class="hint" style="margin:10px 0 6px">Alt tür</div>
    <select id="opSub"></select>

    <div class="grid2" style="margin-top:10px">
      <div>
        <div class="hint" style="margin-bottom:6px">Yön</div>
        <select id="opDir">
          <option value="+">+ (Artış)</option>
          <option value="-">− (Azalış)</option>
          <option value="0">0 (Not)</option>
        </select>
      </div>
      <div>
        <div class="hint" style="margin-bottom:6px">Adet</div>
        <input id="opQty" type="number" min="0" step="1" placeholder="örn: 2">
      </div>
    </div>

    <div class="hint" style="margin:10px 0 6px">Kanal / kaynak</div>
    <select id="opChan"></select>

    <div class="hint" style="margin:10px 0 6px">Açıklama (opsiyonel)</div>
    <textarea id="opNote" placeholder="örn: Insert adı / tarih aralığı / detay..."></textarea>

    <div class="row" style="margin-top:10px">
      <button class="btn primary" id="opSave">Kaydet</button>
      <button class="btn danger" id="opCancel">Vazgeç</button>
    </div>

    <div class="hint" style="margin-top:8px">
      Not: v0.8 veri mimarisi kuruldu. Analiz/raporlar bu log’dan üretilecek.
    </div>
  </div>
</div>

<script>
(function(){
  // ===== v0.8 DB =====
  const KEY = "stok_kontrol_v8";
  const $ = (id)=>document.getElementById(id);

  const uid=()=>Math.random().toString(16).slice(2)+Date.now().toString(16);

  const LS = {
    get(k,d){ try{ return JSON.parse(localStorage.getItem(k)||"null") ?? d }catch(_){ return d } },
    set(k,v){ localStorage.setItem(k, JSON.stringify(v)); }
  };

  function emptyDB(){
    return {
      v:8,
      createdAt: Date.now(),
      products: [],     // {id,name,createdAt}
      ops: []           // {id,ts,prodId,prodName,type,sub,dir,qty,chan,note}
    };
  }

  // Eski anahtarları tara ve birleştir (veri kaybını öldür)
  function migrate(){
    let db = LS.get(KEY, null);
    if(!db) db = emptyDB();

    // localStorage anahtarlarında stok_kontrol_ ile başlayanları çek
    try{
      for(let i=0;i<localStorage.length;i++){
        const k = localStorage.key(i);
        if(!k) continue;
        if(k === KEY) continue;
        if(!k.startsWith("stok_kontrol_")) continue;

        const old = LS.get(k, null);
        if(!old) continue;

        // v0.1 gibi {items:[{name...}], ops:[]} ise ürünleri al
        if(Array.isArray(old.items)){
          for(const it of old.items){
            const name = String(it.name||"").trim();
            if(!name) continue;
            if(!db.products.some(p=>p.name.toLowerCase()===name.toLowerCase())){
              db.products.push({id:uid(), name, createdAt: it.ts || Date.now()});
            }
          }
        }
        // v0.7 gibi ops varsa kaba şekilde ekle (çakışmasın diye id set)
        if(Array.isArray(old.ops)){
          for(const o of old.ops){
            const ts = o.ts || Date.now();
            const prodName = String(o.name||o.prodName||"").trim();
            if(!prodName) continue;

            // product eşle
            let p = db.products.find(x=>x.name.toLowerCase()===prodName.toLowerCase());
            if(!p){
              p = {id:uid(), name:prodName, createdAt:ts};
              db.products.push(p);
            }
            // op ekle
            db.ops.push({
              id: uid(),
              ts,
              prodId: p.id,
              prodName: p.name,
              type: String(o.type||"not"),
              sub: String(o.sub||o.reason||""),
              dir: String(o.dir||"0"),
              qty: Number.isFinite(+o.qty) ? (+o.qty) : 0,
              chan: String(o.chan||""),
              note: String(o.note||"")
            });
          }
        }
      }
    }catch(_){}

    // Ops'i çok şişirme
    if(db.ops.length > 5000) db.ops = db.ops.slice(-5000);

    // Kaydet
    LS.set(KEY, db);
    return db;
  }

  let db = migrate();

  function save(){ LS.set(KEY, db); }

  // ===== UI sözlükler =====
  const SUB = {
    siparis: ["Firma • Ziyaret", "Firma • Telefon geldi", "Firma • Telefon edildi", "Depo • Merkez depo", "Depo • Şarküteri depo"],
    dagitim: ["Merkez dağılımı", "Normal dağılım", "İskonto dağılımı", "Insert dağılımı"],
    satis: ["Normal satış", "Insert satış"],
    iade: ["Müşteri iadesi", "Tarihi geçmiş", "Fabrika kaynaklı", "Raf kaynaklı", "Diğer"],
    skt: ["SKT çıktı"],
    fiyat: ["Fiyat isteği"],
    not: ["Not"]
  };

  const CHAN = {
    siparis: ["Firma", "Depo", "Merkez", "Telefon", "Ziyaret"],
    dagitim: ["Merkez", "Depo", "Firma"],
    satis: ["Kasa", "Online", "Diğer"],
    iade: ["Müşteri", "İç iade"],
    skt: ["Reyon", "Depo"],
    fiyat: ["Merkez", "Satın alma", "Genel müdürlük", "Firma"],
    not: ["—"]
  };

  function typeDefaultDir(t){
    if(t==="siparis"||t==="dagitim") return "+";
    if(t==="satis"||t==="iade"||t==="skt") return "-";
    return "0";
  }

  // ===== Render =====
  function renderMeta(){
    const p = db.products.length;
    const o = db.ops.length;
    $("meta").textContent = `${p} ürün • ${o} işlem`;
  }

  function renderProducts(){
    const q = ($("q").value||"").trim().toLowerCase();
    const rows = db.products.slice()
      .filter(p=>!q || p.name.toLowerCase().includes(q))
      .sort((a,b)=> (b.createdAt||0)-(a.createdAt||0));

    $("info").textContent = rows.length ? `${rows.length} ürün` : "Henüz ürün yok.";
    const box = $("list"); box.innerHTML = "";
    if(!rows.length){
      box.innerHTML = `<div class="item"><div class="hint">İlk ürünü ekle. Sonra “İşlem Ekle” ile sipariş/dağılım/satış/iadeyi loglarsın.</div></div>`;
      return;
    }
    for(const p of rows){
      const el = document.createElement("div");
      el.className="item";
      el.innerHTML = `
        <div class="row between">
          <div class="name">${escapeHTML(p.name)}</div>
          <span class="pill">${new Date(p.createdAt||Date.now()).toLocaleDateString("tr-TR")}</span>
        </div>
        <div class="hint" style="margin-top:6px">İşlem eklemek için: üstte “İşlem Ekle”.</div>
      `;
      box.appendChild(el);
    }
  }

  function renderOpProd(){
    const sel = $("opProd");
    sel.innerHTML = "";
    const rows = db.products.slice().sort((a,b)=>a.name.localeCompare(b.name,"tr"));
    for(const p of rows){
      const opt = document.createElement("option");
      opt.value = p.id;
      opt.textContent = p.name;
      sel.appendChild(opt);
    }
  }

  function renderSubAndChan(){
    const t = $("opType").value;
    const sub = SUB[t] || ["—"];
    const chan = CHAN[t] || ["—"];

    $("opSub").innerHTML = sub.map(x=>`<option value="${escapeAttr(x)}">${escapeHTML(x)}</option>`).join("");
    $("opChan").innerHTML = chan.map(x=>`<option value="${escapeAttr(x)}">${escapeHTML(x)}</option>`).join("");

    $("opDir").value = typeDefaultDir(t);
    if(t==="fiyat" || t==="not"){
      $("opQty").value = 0;
      $("opQty").disabled = true;
    }else{
      $("opQty").disabled = false;
      if(!$("opQty").value) $("opQty").value = 1;
    }
  }

  function openDlg(){
    if(!db.products.length){
      alert("Önce en az 1 ürün ekle.");
      $("pName").focus();
      return;
    }
    renderOpProd();
    renderSubAndChan();
    $("dlg").classList.add("open");
  }
  function closeDlg(){ $("dlg").classList.remove("open"); }

  function addProduct(){
    const name = ($("pName").value||"").trim();
    if(!name){ alert("Ürün adı yaz."); $("pName").focus(); return; }
    if(db.products.some(p=>p.name.toLowerCase()===name.toLowerCase())){
      alert("Bu ürün zaten var.");
      $("pName").select();
      return;
    }
    db.products.unshift({id:uid(), name, createdAt: Date.now()});
    save();
    $("pName").value="";
    $("pName").focus();
    renderMeta(); renderProducts();
  }

  function addOp(){
    const prodId = $("opProd").value;
    const prod = db.products.find(p=>p.id===prodId);
    if(!prod){ alert("Ürün seç."); return; }

    const type = $("opType").value;
    const sub  = $("opSub").value || "";
    const dir  = $("opDir").value;
    const qty  = $("opQty").disabled ? 0 : Math.max(0, parseInt($("opQty").value||"0",10));
    const chan = $("opChan").value || "";
    const note = ($("opNote").value||"").trim();

    // Basit doğrulama
    if((dir==="+" || dir==="-") && qty<=0){
      alert("Adet 1 veya daha büyük olmalı.");
      $("opQty").focus();
      return;
    }

    db.ops.push({
      id: uid(),
      ts: Date.now(),
      prodId: prod.id,
      prodName: prod.name,
      type, sub, dir,
      qty,
      chan,
      note: note || ""
    });

    // log şişmesin
    if(db.ops.length > 5000) db.ops = db.ops.slice(-5000);

    save();
    $("opNote").value="";
    closeDlg();
    renderMeta();
  }

  function escapeHTML(s){
    return String(s||"").replace(/[&<>"']/g,m=>({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[m]));
  }
  function escapeAttr(s){
    return String(s||"").replace(/"/g,"&quot;").replace(/</g,"&lt;");
  }

  // Events
  $("btnAdd").onclick = addProduct;
  $("pName").addEventListener("keydown",(e)=>{ if(e.key==="Enter"){ e.preventDefault(); addProduct(); }});
  $("btnOps").onclick = openDlg;

  $("dlgClose").onclick = closeDlg;
  $("opCancel").onclick = closeDlg;

  $("opType").addEventListener("change", renderSubAndChan);
  $("opSave").onclick = addOp;

  $("q").addEventListener("input", renderProducts);

  // First paint
  renderMeta();
  renderProducts();
  $("pName").focus();
})();
</script>
</body>
</html>
HTML

git add index.html
git commit -m "v0.8: sunulabilir veri modeli + işlem modalı (migrate güvenli)" || true
git push -u origin main

echo
echo "✅ bitti. Aç:"
echo "https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
