set -e

ts=$(date +%Y%m%d_%H%M%S)
mkdir -p _backup app

# 0) Yedek
if [ -f index.html ]; then
  cp -f index.html "_backup/index.html.$ts.bak"
fi

# 1) app.css
cat > app/app.css <<'CSS'
:root{
  --bg:#070b14;
  --card:#0b1220;
  --text:#e5e7eb;
  --muted:#94a3b8;
  --line:rgba(255,255,255,.10);
  --ok:#16a34a;
  --bad:#ef4444;
  --warn:#f59e0b;
  --blue:#2563eb;
  --r:18px;
  --pad:14px;
}
*{box-sizing:border-box}
html,body{height:100%}
body{
  margin:0;
  font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;
  background:linear-gradient(180deg,#070b14,#05070f);
  color:var(--text);
}
header{
  position:sticky; top:0; z-index:50;
  background:rgba(7,11,20,.72);
  backdrop-filter: blur(10px);
  border-bottom:1px solid var(--line);
}
.wrap{max-width:980px;margin:0 auto;padding:14px 14px 18px}
.top{display:flex;align-items:flex-start;justify-content:space-between;gap:12px}
h1{font-size:20px;margin:0}
.sub{color:var(--muted);font-size:12px;margin-top:4px}
.grid{display:grid;grid-template-columns:1fr;gap:14px}
@media(min-width:900px){.grid{grid-template-columns:1.15fr .85fr}}
.card{
  background:linear-gradient(180deg,rgba(255,255,255,.04),rgba(255,255,255,.02));
  border:1px solid var(--line);
  border-radius:var(--r);
  padding:var(--pad);
  box-shadow:0 10px 30px rgba(0,0,0,.25);
}
.card h2{margin:0 0 8px;font-size:15px}
.hint{color:var(--muted);font-size:12px}
.hr{height:1px;background:var(--line);margin:12px 0}
.row{display:flex;gap:10px;align-items:center;flex-wrap:wrap}
.col{display:flex;flex-direction:column;gap:10px}
input,select,button{
  font:inherit;
}
input,select{
  width:100%;
  background:rgba(255,255,255,.03);
  color:var(--text);
  border:1px solid var(--line);
  border-radius:14px;
  padding:12px 12px;
  outline:none;
}
button{
  border:0;
  border-radius:14px;
  padding:12px 14px;
  font-weight:850;
  color:#fff;
  background:rgba(255,255,255,.08);
}
button:active{transform:translateY(1px)}
.btnOK{background:linear-gradient(180deg,#16a34a,#15803d)}
.btnBAD{background:linear-gradient(180deg,#ef4444,#b91c1c)}
.btnBLUE{background:linear-gradient(180deg,#2563eb,#1d4ed8)}
.pill{
  display:inline-flex;align-items:center;gap:6px;
  padding:8px 10px;border:1px solid var(--line);
  border-radius:999px;background:rgba(255,255,255,.03);
  color:var(--muted);font-size:12px;
}
.list{display:flex;flex-direction:column;gap:10px;margin-top:10px}
.item{
  padding:12px;
  border:1px solid var(--line);
  border-radius:16px;
  background:rgba(255,255,255,.02);
}
.itemTop{display:flex;justify-content:space-between;gap:10px;align-items:flex-start}
.name{font-weight:900}
.mini{color:var(--muted);font-size:12px;margin-top:4px}
.kpiRow{display:flex;gap:8px;flex-wrap:wrap;margin-top:10px}
.kpi{display:flex;flex-direction:column;gap:2px;padding:10px;border:1px solid var(--line);border-radius:14px;background:rgba(255,255,255,.02);min-width:110px}
.k{color:var(--muted);font-size:11px}
.v{font-weight:950;font-size:18px}
.smallBtn{padding:10px 12px;border-radius:14px}
.footerNote{color:var(--muted);font-size:11px;margin-top:10px}
#errorGuardBox{
  position:fixed;left:0;right:0;bottom:0;
  background:#7f1d1d;color:#fff;
  padding:12px;font-size:12px;display:none;z-index:99999;
  max-height:40vh;overflow:auto;border-top:2px solid #ef4444;
}
CSS

# 2) app.js (temel motor + butonların asla donmaması için guard)
cat > app/app.js <<'JS'
/* Stok Kontrol Motoru — Clean v2 (tek dosya, stabil) */
(() => {
  "use strict";

  // ---- ERROR GUARD (en altta kırmızı bar) ----
  function installErrorGuard(){
    if(document.getElementById("errorGuardBox")) return;
    const box = document.createElement("div");
    box.id = "errorGuardBox";
    box.innerHTML = "<b>Sistem Hatası:</b><br><div id='errorGuardText'></div>";
    document.body.appendChild(box);
    function show(msg){
      box.style.display = "block";
      const t = document.getElementById("errorGuardText");
      if(t) t.textContent = msg;
    }
    window.addEventListener("error", (e)=>{
      show((e && e.message ? e.message : "error") + " @ " + (e.filename||"") + ":" + (e.lineno||""));
    });
    window.addEventListener("unhandledrejection", (e)=>{
      const r = e && e.reason;
      show("Promise Error: " + (r && r.message ? r.message : String(r)));
    });
  }

  // ---- Helpers ----
  const $ = (id) => document.getElementById(id);
  const now = () => Date.now();
  const KEY = "stok_kontrol_db_v2";

  function safeParse(s){
    try{ return JSON.parse(s); }catch(_){ return null; }
  }
  function loadDB(){
    const raw = localStorage.getItem(KEY);
    const db = safeParse(raw) || { v:2, products:[], ops:[] };
    if(!db.products) db.products=[];
    if(!db.ops) db.ops=[];
    return db;
  }
  function saveDB(db){
    localStorage.setItem(KEY, JSON.stringify(db));
  }

  function uid(){
    return (now().toString(16) + Math.random().toString(16).slice(2,8));
  }

  // Net stok = tüm ops toplamı (+/-)
  function calcNetForProduct(db, pid){
    let net = 0;
    for(const o of db.ops){
      if(o.pid !== pid) continue;
      net += (Number(o.delta)||0);
    }
    return net;
  }

  function fmtDT(ts){
    try{ return new Date(ts).toLocaleString("tr-TR"); }catch(_){ return ""; }
  }

  // ---- Render ----
  function render(){
    const db = loadDB();
    // ürün listesi
    const q = (($("search")?.value)||"").trim().toLowerCase();
    const box = $("productList");
    if(!box) return;

    let prods = db.products.slice();
    if(q){
      prods = prods.filter(p => (p.name||"").toLowerCase().includes(q));
    }

    if(!prods.length){
      box.innerHTML = `<div class="item">Henüz ürün yok. <div class="mini">Yukarıdan ürün ekle.</div></div>`;
      renderReport(db, 0);
      return;
    }

    // nete göre göster
    box.innerHTML = "";
    for(const p of prods){
      const net = calcNetForProduct(db, p.id);
      const el = document.createElement("div");
      el.className = "item";
      el.innerHTML = `
        <div class="itemTop">
          <div style="flex:1">
            <div class="name">${escapeHTML(p.name||"")}</div>
            <div class="mini">Net stok: <b>${net}</b> • Son güncelleme: ${fmtDT(p.ts||0)}</div>
          </div>
          <button class="smallBtn btnBLUE" type="button" data-pid="${p.id}">İşlem</button>
        </div>
      `;
      box.appendChild(el);
    }

    // işlem butonları
    box.querySelectorAll("button[data-pid]").forEach(btn=>{
      btn.addEventListener("click", ()=>{
        const pid = btn.getAttribute("data-pid");
        openOpModal(pid);
      });
    });

    // rapor
    renderReport(db, 30);
  }

  function escapeHTML(s){
    return String(s).replace(/[&<>"']/g, (c)=>({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[c]));
  }

  // ---- Modal (işlem ekleme) ----
  function openOpModal(pid){
    const db = loadDB();
    const p = db.products.find(x=>x.id===pid);
    if(!p) return;

    $("opTitle").textContent = p.name;
    $("opQty").value = "1";
    $("opType").value = "siparis";
    $("opSub").value = "";

    $("modal").style.display = "block";
    $("modal").setAttribute("data-pid", pid);

    // (flicker azaltmak için) autofocus yok. Kullanıcı isterse tıklayıp yazar.
  }

  function closeModal(){
    $("modal").style.display = "none";
    $("modal").removeAttribute("data-pid");
  }

  function opDeltaFromType(type){
    // Şimdilik temel: sipariş/dağılım artı; satış/skt/iade eksi
    if(type==="siparis") return +1;
    if(type==="dagilim") return +1;
    return -1;
  }

  function addOp(){
    const pid = $("modal").getAttribute("data-pid");
    if(!pid) return;

    const type = $("opType").value;
    const sub = ($("opSub").value||"").trim();
    const qty = Math.max(1, Number(($("opQty").value||"1").replace(",", ".")) || 1);

    const db = loadDB();
    const base = opDeltaFromType(type);
    const delta = base * qty;

    db.ops.push({
      id: uid(),
      pid,
      type,
      sub,
      qty,
      delta,
      ts: now()
    });

    // ürün ts güncelle
    const p = db.products.find(x=>x.id===pid);
    if(p) p.ts = now();

    saveDB(db);
    closeModal();
    render();
  }

  // ---- Report (bugün/7/30) ----
  function reportForDays(db, days){
    const since = now() - days*24*60*60*1000;
    const ops = db.ops.filter(o => (o.ts||0) >= since);

    let plus=0, minus=0;
    const byType = {};
    const byProd = {};
    for(const o of ops){
      if(o.delta>0) plus += o.delta;
      if(o.delta<0) minus += Math.abs(o.delta);
      byType[o.type] = (byType[o.type]||0) + 1;
      byProd[o.pid] = (byProd[o.pid]||0) + Math.abs(o.delta);
    }
    const net = plus - minus;

    // top ürünler
    const top = Object.entries(byProd).sort((a,b)=>b[1]-a[1]).slice(0,5).map(([pid,val])=>{
      const p = db.products.find(x=>x.id===pid);
      return `${p ? p.name : pid} (${val})`;
    });

    return { days, plus, minus, net, byType, top };
  }

  function renderReport(db, defaultDays){
    const r = reportForDays(db, defaultDays);
    $("rDays").textContent = String(r.days);
    $("rPlus").textContent = String(r.plus);
    $("rMinus").textContent = String(r.minus);
    $("rNet").textContent = String(r.net);

    const tBox = $("rTypes");
    tBox.innerHTML = "";
    const entries = Object.entries(r.byType).sort((a,b)=>b[1]-a[1]);
    if(!entries.length){
      tBox.innerHTML = `<div class="hint">Bu aralıkta işlem yok.</div>`;
    }else{
      for(const [k,v] of entries){
        const el = document.createElement("div");
        el.className="pill";
        el.textContent = `${k}: ${v}`;
        tBox.appendChild(el);
      }
    }

    const topBox = $("rTop");
    topBox.innerHTML = "";
    if(!r.top.length){
      topBox.innerHTML = `<div class="hint">Top ürün yok.</div>`;
    }else{
      for(const s of r.top){
        const el = document.createElement("div");
        el.className="pill";
        el.textContent = s;
        topBox.appendChild(el);
      }
    }

    // “Akıl” (şimdilik basit): net eksiye düşenleri uyar
    const warn = [];
    for(const p of db.products){
      const net = calcNetForProduct(db, p.id);
      if(net < 0) warn.push(`🟥 Negatif stok: ${p.name} (${net})`);
    }
    $("rBrain").innerHTML = warn.length ? warn.map(x=>`<div class="item">${escapeHTML(x)}</div>`).join("") : `<div class="hint">Risk yok gibi.</div>`;
  }

  // ---- Product add ----
  function addProduct(){
    const name = (($("prodName").value)||"").trim();
    if(!name){ alert("Ürün adı yaz."); return; }

    const db = loadDB();
    db.products.push({ id: uid(), name, ts: now() });
    saveDB(db);

    $("prodName").value = "";
    render();
  }

  // ---- Boot ----
  function hook(){
    installErrorGuard();

    $("btnAdd").addEventListener("click", addProduct);
    $("prodName").addEventListener("keydown", (e)=>{
      if(e.key==="Enter"){
        e.preventDefault();
        addProduct();
      }
    });

    $("btnClose").addEventListener("click", closeModal);
    $("btnOpSave").addEventListener("click", addOp);

    $("search").addEventListener("input", ()=>render());

    $("btnReportToday").addEventListener("click", ()=>{
      const db = loadDB(); renderReport(db, 1);
    });
    $("btnReport7").addEventListener("click", ()=>{
      const db = loadDB(); renderReport(db, 7);
    });
    $("btnReport30").addEventListener("click", ()=>{
      const db = loadDB(); renderReport(db, 30);
    });

    // modal dışına tıklayınca kapat
    $("modal").addEventListener("click", (e)=>{
      if(e.target && e.target.id==="modal") closeModal();
    });

    render();
  }

  if(document.readyState==="loading") document.addEventListener("DOMContentLoaded", hook);
  else hook();

})();
JS

# 3) index.html (temiz iskelet)
cat > index.html <<'HTML'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Stok Kontrol Motoru</title>
  <meta name="theme-color" content="#0b1220">
  <link rel="stylesheet" href="./app/app.css">
</head>
<body>

<header>
  <div class="wrap">
    <div class="top">
      <div>
        <h1>Stok Kontrol Motoru</h1>
        <div class="sub">Clean v2 — ürün + işlem + rapor (stabil temel)</div>
      </div>
      <div class="row">
        <span class="pill">Local DB: stok_kontrol_db_v2</span>
      </div>
    </div>
  </div>
</header>

<main class="wrap">
  <div class="grid">
    <!-- SOL: Ürünler -->
    <section class="card">
      <h2>Ürünler</h2>
      <div class="hint">Ürün ekle → ürün kartından “İşlem” aç.</div>
      <div class="hr"></div>

      <div class="row">
        <input id="prodName" placeholder="Ürün adı" inputmode="text" autocomplete="off">
        <button id="btnAdd" class="btnOK" type="button">Ekle</button>
      </div>

      <div class="row">
        <input id="search" placeholder="Ara (liste sabit kalsın)" inputmode="text" autocomplete="off">
      </div>

      <div id="productList" class="list"></div>

      <div class="footerNote">Not: Donma/boş ekran olursa alttaki kırmızı hata bandı mesaj verir.</div>
    </section>

    <!-- SAĞ: Rapor -->
    <section class="card" id="cardReport">
      <div class="row" style="justify-content:space-between">
        <div>
          <h2 style="margin-bottom:2px">Rapor</h2>
          <div class="hint">Özet (bugün / 7 gün / 30 gün)</div>
        </div>
        <div class="row">
          <button id="btnReportToday" class="btnBLUE smallBtn" type="button">Bugün</button>
          <button id="btnReport7" class="btnBLUE smallBtn" type="button">7g</button>
          <button id="btnReport30" class="btnBLUE smallBtn" type="button">30g</button>
        </div>
      </div>

      <div class="hr"></div>

      <div class="kpiRow">
        <div class="kpi"><div class="k">Pencere</div><div class="v"><span id="rDays">30</span>g</div></div>
        <div class="kpi"><div class="k">Artış</div><div class="v" id="rPlus">0</div></div>
        <div class="kpi"><div class="k">Azalış</div><div class="v" id="rMinus">0</div></div>
        <div class="kpi"><div class="k">Net</div><div class="v" id="rNet">0</div></div>
      </div>

      <div class="hr"></div>

      <div class="hint" style="margin-bottom:6px">Tür dağılımı</div>
      <div id="rTypes" class="row"></div>

      <div class="hr"></div>

      <div class="hint" style="margin-bottom:6px">Top ürünler</div>
      <div id="rTop" class="row"></div>

      <div class="hr"></div>

      <div class="hint" style="margin-bottom:6px">Akıl / risk</div>
      <div id="rBrain" class="list"></div>
    </section>
  </div>
</main>

<!-- Modal -->
<div id="modal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:9999;padding:16px">
  <div class="card" style="max-width:560px;margin:40px auto">
    <div class="row" style="justify-content:space-between">
      <div>
        <div class="hint">İşlem</div>
        <div class="name" id="opTitle">Ürün</div>
      </div>
      <button id="btnClose" type="button">Kapat</button>
    </div>

    <div class="hr"></div>

    <div class="row">
      <select id="opType">
        <option value="siparis">Sipariş (+)</option>
        <option value="dagilim">Dağılım (+)</option>
        <option value="satis">Satış (-)</option>
        <option value="skt">SKT (-)</option>
        <option value="iade">İade (-)</option>
      </select>
      <input id="opQty" inputmode="numeric" placeholder="Adet" value="1">
    </div>

    <div class="row">
      <input id="opSub" placeholder="Alt kırılım (opsiyonel): normal/iskonto/insert, sebep vb." autocomplete="off">
    </div>

    <div class="row" style="justify-content:flex-end">
      <button id="btnOpSave" class="btnOK" type="button">İşlem Ekle</button>
    </div>
  </div>
</div>

<script defer src="./app/app.js"></script>
</body>
</html>
HTML

# 4) commit + push
git add -A
git commit -m "refactor: clean v2 (index + app.js + app.css)" || true
git push -u origin main

echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
