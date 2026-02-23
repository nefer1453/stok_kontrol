set -e
cd "$HOME/stok_kontrol"

ts=$(date +%Y%m%d_%H%M%S)
cp -f index.html "index.html.bak.$ts" 2>/dev/null || true

cat > index.html <<'HTML'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
  <title>Stok Kontrol Motoru</title>
  <style>
    :root{
      --bg:#0b1220; --card:#0f172a; --line:#22304a; --txt:#e5e7eb; --mut:#9ca3af;
      --ok:#16a34a; --bad:#ef4444; --warn:#f59e0b; --btn:#111827;
      --r:18px;
    }
    *{box-sizing:border-box}
    body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;background:linear-gradient(180deg,#050a14,var(--bg));color:var(--txt)}
    header{position:sticky;top:0;z-index:10;background:rgba(5,10,20,.9);backdrop-filter: blur(10px);border-bottom:1px solid rgba(255,255,255,.06)}
    .wrap{max-width:560px;margin:0 auto;padding:14px}
    .row{display:flex;gap:10px;align-items:center}
    .between{justify-content:space-between}
    .card{background:rgba(15,23,42,.9);border:1px solid rgba(255,255,255,.07);border-radius:var(--r);padding:14px}
    .h1{font-weight:900;font-size:18px}
    .hint{color:var(--mut);font-size:12px;line-height:1.35}
    .hr{height:1px;background:rgba(255,255,255,.08);margin:12px 0}
    input,select,textarea{width:100%;padding:14px;border-radius:16px;border:1px solid rgba(255,255,255,.10);background:rgba(0,0,0,.25);color:var(--txt);outline:none}
    input:focus,select:focus,textarea:focus{border-color:rgba(22,163,74,.45);box-shadow:0 0 0 3px rgba(22,163,74,.15)}
    button{border:0;border-radius:16px;padding:14px 14px;font-weight:900;color:var(--txt);background:rgba(17,24,39,.9)}
    button:active{transform:scale(.99)}
    button.primary{background:linear-gradient(135deg,#16a34a,#22c55e);color:#07210f}
    button.danger{background:linear-gradient(135deg,#ef4444,#fb7185);color:#2a070d}
    button.ghost{background:transparent;border:1px solid rgba(255,255,255,.10)}
    button:disabled{opacity:.45}
    .pill{display:inline-flex;align-items:center;gap:8px;padding:8px 10px;border-radius:999px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.07);font-size:12px}
    .list{display:flex;flex-direction:column;gap:10px}
    .item{display:flex;gap:12px;align-items:flex-start;padding:12px;border-radius:16px;border:1px solid rgba(255,255,255,.08);background:rgba(0,0,0,.16)}
    .name{font-weight:950}
    .kbd{font-family:ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace}
    .screen{display:none}
    .screen.on{display:block}
    .seg{display:flex;gap:10px;flex-wrap:wrap}
    .seg button{flex:1;min-width:140px}
    .subseg{display:flex;gap:10px;flex-wrap:wrap}
    .subseg button{flex:1;min-width:160px}
    .stickyBottom{
      position:sticky; bottom:0; padding:12px 0 14px;
      background:linear-gradient(180deg, rgba(5,10,20,0), rgba(5,10,20,.92) 35%, rgba(5,10,20,.98));
    }
    .grid2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
  </style>
</head>
<body>
<header>
  <div class="wrap row between">
    <div>
      <div class="h1">Stok Kontrol</div>
      <div class="hint">v0.6 • ürün → işlem → adet → kayıt (stok ops’tan hesap)</div>
    </div>
    <div class="row">
      <button class="ghost" id="btnTools" title="Araçlar">⋯</button>
    </div>
  </div>
</header>

<main class="wrap">

  <!-- SCREEN: HOME -->
  <section class="screen on" id="scrHome">
    <div class="card">
      <div class="row between">
        <div>
          <div class="h1">Ürünler</div>
          <div class="hint">Ürün seç → İşlem Ekle ekranına geç.</div>
        </div>
        <button class="primary" id="btnNewProd">+ Ürün</button>
      </div>

      <div class="hr"></div>

      <div class="row" style="align-items:flex-start">
        <div style="flex:1">
          <input id="q" type="search" placeholder="Ara (sabit)" autocomplete="off">
          <div class="hint" id="info" style="margin-top:6px"></div>
        </div>
      </div>

      <div class="list" id="prodList" style="margin-top:12px"></div>
    </div>
  </section>

  <!-- SCREEN: ADD PRODUCT -->
  <section class="screen" id="scrProd">
    <div class="card">
      <div class="row between">
        <div class="h1">Yeni Ürün</div>
        <button class="ghost" id="btnProdBack">Geri</button>
      </div>
      <div class="hint">Sadece isim. Sonrası işlemlerden oluşacak.</div>
      <div class="hr"></div>

      <input id="prodName" placeholder="Ürün adı">
      <div class="stickyBottom">
        <div class="grid2">
          <button class="ghost" id="btnProdCancel">Vazgeç</button>
          <button class="primary" id="btnProdSave">Kaydet</button>
        </div>
      </div>
    </div>
  </section>

  <!-- SCREEN: ADD OP -->
  <section class="screen" id="scrOp">
    <div class="card">
      <div class="row between">
        <div>
          <div class="h1" id="opTitle">İşlem Ekle</div>
          <div class="hint" id="opHint"></div>
        </div>
        <button class="ghost" id="btnOpBack">Geri</button>
      </div>

      <div class="hr"></div>

      <div class="hint">1) İşlem türünü seç</div>
      <div class="seg" style="margin-top:10px">
        <button class="ghost" data-type="SIPARIS">Sipariş (+)</button>
        <button class="ghost" data-type="DAGITIM">Dağılım (+)</button>
        <button class="ghost" data-type="SATIS">Satış (-)</button>
        <button class="ghost" data-type="SKT">SKT (-)</button>
        <button class="ghost" data-type="IADE">İade (-)</button>
      </div>

      <div id="subBox" style="display:none;margin-top:12px">
        <div class="hint">2) Alt tür</div>
        <div class="subseg" id="subSeg" style="margin-top:10px"></div>
      </div>

      <div id="extraBox" style="display:none;margin-top:12px">
        <div class="hint" id="extraHint">3) Ek bilgi</div>
        <input id="extraText" placeholder="örn: Insert adı / tarih aralığı">
      </div>

      <div style="margin-top:12px">
        <div class="hint">4) Adet</div>
        <input id="qty" type="number" inputmode="numeric" min="1" step="1" placeholder="örn: 2">
      </div>

      <div class="stickyBottom">
        <div class="grid2">
          <button class="ghost" id="btnOpClear">Sıfırla</button>
          <button class="primary" id="btnOpSave" disabled>Kaydet</button>
        </div>
      </div>
    </div>
  </section>

  <!-- SCREEN: TOOLS -->
  <section class="screen" id="scrTools">
    <div class="card">
      <div class="row between">
        <div class="h1">Araçlar</div>
        <button class="ghost" id="btnToolsBack">Geri</button>
      </div>
      <div class="hint">Şimdilik sadece sıfırlama. Export/import sonra.</div>
      <div class="hr"></div>
      <button class="danger" id="btnReset">Tüm veriyi sil</button>
      <div class="hint" style="margin-top:10px">
        Bu buton localStorage içindeki <span class="kbd">stok_kontrol_v06</span> anahtarını temizler.
      </div>
    </div>
  </section>

</main>

<script>
(() => {
  const KEY="stok_kontrol_v06";
  const $=id=>document.getElementById(id);

  const LS={
    get:(k,d)=>{ try{ return JSON.parse(localStorage.getItem(k)||"null") ?? d }catch(_){ return d } },
    set:(k,v)=>localStorage.setItem(k, JSON.stringify(v))
  };

  const uid=()=>Math.random().toString(16).slice(2)+Date.now().toString(16);
  const now=()=>Date.now();

  // db:
  // products: [{id,name,ts}]
  // ops: [{id,prodId,dir,type,sub,extra,qty,ts}]
  let db = LS.get(KEY, { products:[], ops:[] });

  function save(){ LS.set(KEY, db); }

  function esc(s){
    return String(s||"").replace(/[&<>"']/g,m=>({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[m]));
  }

  function screen(id){
    for(const el of document.querySelectorAll(".screen")) el.classList.remove("on");
    $(id).classList.add("on");
  }

  function calcStock(prodId){
    let v=0;
    for(const o of db.ops){
      if(o.prodId!==prodId) continue;
      v += (o.dir||0) * (o.qty||0);
    }
    return v;
  }

  function opCount(prodId){
    let c=0;
    for(const o of db.ops) if(o.prodId===prodId) c++;
    return c;
  }

  function renderHome(){
    const q = ($("q").value||"").trim().toLowerCase();
    const rows = db.products.slice()
      .filter(p => !q || (p.name||"").toLowerCase().includes(q))
      .sort((a,b)=> (b.ts||0)-(a.ts||0));

    $("info").textContent = rows.length ? (rows.length+" ürün") : "Boş";
    const box = $("prodList");
    box.innerHTML = "";

    if(!rows.length){
      box.innerHTML = '<div class="item"><div style="flex:1"><div class="name">Henüz ürün yok</div><div class="hint">+ Ürün ile başla.</div></div></div>';
      return;
    }

    for(const p of rows){
      const st = calcStock(p.id);
      const ops = opCount(p.id);
      const el = document.createElement("div");
      el.className="item";
      el.innerHTML = `
        <div style="flex:1">
          <div class="name">${esc(p.name)}</div>
          <div class="row" style="margin-top:8px;gap:8px;flex-wrap:wrap">
            <span class="pill">Stok: <b>${st}</b></span>
            <span class="pill">İşlem: <b>${ops}</b></span>
          </div>
        </div>
        <div class="row" style="flex-direction:column;gap:8px">
          <button class="primary" data-addop="${p.id}" style="padding:12px 12px">İşlem</button>
          <button class="ghost" data-del="${p.id}" style="padding:12px 12px">Sil</button>
        </div>
      `;
      el.querySelector("[data-addop]").onclick = ()=> openOp(p.id);
      el.querySelector("[data-del]").onclick = ()=>{
        if(!confirm("Ürün silinsin mi? (İşlemler de silinir)")) return;
        db.products = db.products.filter(x=>x.id!==p.id);
        db.ops = db.ops.filter(o=>o.prodId!==p.id);
        save(); renderHome();
      };
      box.appendChild(el);
    }
  }

  // PRODUCT
  function openNewProd(){
    $("prodName").value="";
    screen("scrProd");
    setTimeout(()=> $("prodName").focus(), 50);
  }

  function saveNewProd(){
    const name = ($("prodName").value||"").trim();
    if(!name){ alert("Ürün adı yaz."); $("prodName").focus(); return; }
    db.products.unshift({ id:uid(), name, ts:now() });
    save();
    $("q").value = "";
    screen("scrHome");
    renderHome();
  }

  // OP SCREEN state
  let currentProdId = null;
  let op = { type:null, sub:null, extra:null, dir:0 };

  const SUBS = {
    SIPARIS: [
      {k:"FIRMA_MAGAZAYA", t:"Firma: mağazaya geldi"},
      {k:"FIRMA_TEL_GELDI", t:"Firma: telefon geldi"},
      {k:"FIRMA_TEL_EDILDI", t:"Firma: telefon edildi"},
      {k:"DEPO_MERKEZ", t:"Depo: merkez depoya"},
      {k:"DEPO_SARKUTERI", t:"Depo: şarküteri depoya"},
    ],
    DAGITIM: [
      {k:"MERKEZ", t:"Merkez dağılımı"},
      {k:"NORMAL", t:"Normal dağılım"},
      {k:"ISKONTO", t:"İskonto dağılım"},
      {k:"INSERT", t:"Insert dağılımı"},
    ],
    IADE: [
      {k:"MUSTERI", t:"Müşteri iadesi"},
      {k:"TARIHI_GECMIS", t:"Tarihi geçmiş"},
      {k:"FABRIKA", t:"Fabrika kaynaklı"},
      {k:"RAF", t:"Raf kaynaklı"},
    ],
    SATIS: [
      {k:"SATIS", t:"Satış"},
    ],
    SKT: [
      {k:"SKT", t:"SKT"},
    ],
  };

  function openOp(prodId){
    currentProdId = prodId;
    const p = db.products.find(x=>x.id===prodId);
    $("opTitle").textContent = "İşlem Ekle";
    $("opHint").textContent = p ? ("Ürün: " + p.name) : "";

    // reset selection
    op = { type:null, sub:null, extra:null, dir:0 };
    $("subBox").style.display="none";
    $("subSeg").innerHTML="";
    $("extraBox").style.display="none";
    $("extraText").value="";
    $("qty").value="";
    $("btnOpSave").disabled=true;

    // type buttons reset
    for(const b of document.querySelectorAll('[data-type]')) b.classList.remove("primary");
    screen("scrOp");
    setTimeout(()=> $("qty").blur(), 0);
  }

  function setType(t){
    op.type = t;
    op.sub = null;
    op.extra = null;

    // dir
    op.dir = (t==="SIPARIS" || t==="DAGITIM") ? +1 : -1;

    // ui highlight
    for(const b of document.querySelectorAll('[data-type]')){
      b.classList.toggle("primary", b.getAttribute("data-type")===t);
      b.classList.toggle("ghost", b.getAttribute("data-type")!==t);
    }

    // subs
    const list = SUBS[t] || [];
    const subBox = $("subBox");
    const subSeg = $("subSeg");
    subSeg.innerHTML = "";
    if(list.length){
      subBox.style.display = "block";
      for(const s of list){
        const btn = document.createElement("button");
        btn.className = "ghost";
        btn.textContent = s.t;
        btn.onclick = ()=> setSub(s.k, s.t);
        subSeg.appendChild(btn);
      }
    }else{
      subBox.style.display = "none";
    }

    // extra rules
    if(t==="DAGITIM"){
      $("extraHint").textContent = "3) Ek bilgi (opsiyonel)";
      $("extraText").placeholder = "örn: Insert adı / tarih aralığı";
      $("extraBox").style.display = "block";
    }else{
      $("extraBox").style.display = "none";
      $("extraText").value = "";
    }

    validateOp();
  }

  function setSub(k, label){
    op.sub = k;

    // select UI
    for(const b of $("subSeg").querySelectorAll("button")){
      b.classList.remove("primary");
      b.classList.add("ghost");
      if(b.textContent===label){
        b.classList.add("primary");
        b.classList.remove("ghost");
      }
    }

    // extra: only if DAGITIM + INSERT selected, make extra "required-ish" (we still allow empty but encourage)
    if(op.type==="DAGITIM" && op.sub==="INSERT"){
      $("extraHint").textContent = "3) Insert bilgisi (isim + tarih aralığı)";
      $("extraText").placeholder = "örn: Ramazan Insert 01-15 Mart";
      $("extraBox").style.display="block";
    }

    validateOp();
    setTimeout(()=> $("qty").focus(), 60);
  }

  function validateOp(){
    const qty = parseInt(($("qty").value||"").trim(),10);
    const okQty = Number.isFinite(qty) && qty>0;
    const okType = !!op.type;
    const needSub = (SUBS[op.type]||[]).length>0;
    const okSub = !needSub || !!op.sub;

    $("btnOpSave").disabled = !(okType && okSub && okQty);
  }

  function saveOp(){
    const qty = parseInt(($("qty").value||"").trim(),10);
    if(!(Number.isFinite(qty) && qty>0)){ alert("Adet gir."); $("qty").focus(); return; }
    if(!op.type){ alert("İşlem türü seç."); return; }
    const needSub = (SUBS[op.type]||[]).length>0;
    if(needSub && !op.sub){ alert("Alt tür seç."); return; }

    const prod = db.products.find(x=>x.id===currentProdId);
    db.ops.push({
      id: uid(),
      prodId: currentProdId,
      dir: op.dir,
      type: op.type,
      sub: op.sub || null,
      extra: ($("extraText").value||"").trim() || null,
      qty,
      ts: now(),
      prodName: prod ? prod.name : null
    });
    save();

    // back
    screen("scrHome");
    renderHome();
  }

  // TOOLS
  function openTools(){ screen("scrTools"); }
  function resetAll(){
    if(!confirm("TÜM VERİ SİLİNSİN Mİ?")) return;
    localStorage.removeItem(KEY);
    db = { products:[], ops:[] };
    renderHome();
    screen("scrHome");
  }

  // EVENTS
  $("btnNewProd").onclick = openNewProd;
  $("btnProdBack").onclick = ()=>{ screen("scrHome"); renderHome(); };
  $("btnProdCancel").onclick = ()=>{ screen("scrHome"); renderHome(); };
  $("btnProdSave").onclick = saveNewProd;
  $("prodName").addEventListener("keydown",(e)=>{ if(e.key==="Enter"){ e.preventDefault(); saveNewProd(); } });

  $("btnOpBack").onclick = ()=>{ screen("scrHome"); renderHome(); };
  $("btnOpClear").onclick = ()=> openOp(currentProdId);
  $("btnOpSave").onclick = saveOp;

  for(const b of document.querySelectorAll("[data-type]")){
    b.onclick = ()=> setType(b.getAttribute("data-type"));
  }
  $("qty").addEventListener("input", validateOp);
  $("extraText").addEventListener("input", ()=>{ /* extra optional */ });

  $("btnTools").onclick = openTools;
  $("btnToolsBack").onclick = ()=>{ screen("scrHome"); renderHome(); };
  $("btnReset").onclick = resetAll;

  $("q").addEventListener("input", renderHome);

  // INIT
  renderHome();

})();
</script>
</body>
</html>
HTML

git add index.html
git commit -m "v0.6: ürün + ayrı işlem ekle ekranı (sipariş/dağılım/satış/skt/iade)" || true
git push -u origin main

echo
echo "✅ v0.6 yüklendi."
echo "👉 Link (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
