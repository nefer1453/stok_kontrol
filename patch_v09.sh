set -e
cd "$(dirname "$0")"

ts="$(date +%Y%m%d_%H%M%S)"
cp -f index.html "index.html.bak.$ts" 2>/dev/null || true

cat > index.html <<'HTML'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Stok Kontrol • v0.9</title>
  <style>
    :root{
      --bg:#0b1220;
      --card:#0f172a;
      --line:rgba(255,255,255,.10);
      --text:#e5e7eb;
      --muted:#94a3b8;
      --ok:#16a34a;
      --warn:#f59e0b;
      --bad:#ef4444;
      --btn:#1f2937;
      --btn2:#111827;
      --pill:rgba(255,255,255,.08);
      --radius:18px;
    }
    *{box-sizing:border-box}
    body{
      margin:0;
      font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;
      background:linear-gradient(180deg,#070b13,#0b1220 40%,#070b13);
      color:var(--text);
    }
    header{
      position:sticky; top:0; z-index:20;
      background:rgba(7,11,19,.92);
      backdrop-filter: blur(8px);
      border-bottom:1px solid var(--line);
      padding:12px 14px;
      display:flex; align-items:center; justify-content:space-between; gap:10px;
    }
    .brand{font-weight:900; letter-spacing:.2px}
    .seg{
      display:flex; gap:8px;
    }
    .seg button{
      border:1px solid var(--line);
      background:var(--btn2);
      color:var(--text);
      padding:10px 12px;
      border-radius:14px;
      font-weight:800;
      min-width:92px;
    }
    .seg button.active{outline:2px solid rgba(22,163,74,.45); border-color:rgba(22,163,74,.45)}
    main{max-width:560px; margin:0 auto; padding:14px 14px 110px}
    .card{
      background:rgba(15,23,42,.92);
      border:1px solid var(--line);
      border-radius:var(--radius);
      padding:14px;
      box-shadow:0 10px 30px rgba(0,0,0,.25);
    }
    .h{font-size:18px; font-weight:950}
    .hint{color:var(--muted); font-size:12px; line-height:1.35}
    .row{display:flex; align-items:center; gap:10px}
    .between{justify-content:space-between}
    .grid{display:grid; gap:10px}
    .input, select{
      width:100%;
      padding:14px 14px;
      border-radius:16px;
      border:1px solid var(--line);
      background:rgba(0,0,0,.18);
      color:var(--text);
      font-size:16px;
      outline:none;
    }
    .input:focus, select:focus{outline:2px solid rgba(22,163,74,.35)}
    .btn{
      border:1px solid var(--line);
      background:var(--btn);
      color:var(--text);
      padding:14px 14px;
      border-radius:16px;
      font-weight:900;
      font-size:15px;
      cursor:pointer;
    }
    .btn.primary{background:linear-gradient(180deg,#22c55e,#16a34a); border-color:rgba(34,197,94,.35); color:#04130a}
    .btn.danger{background:linear-gradient(180deg,#fb7185,#ef4444); border-color:rgba(239,68,68,.35); color:#1a0507}
    .btn.ghost{background:transparent}
    .btn:disabled{opacity:.45; cursor:not-allowed}
    .pill{
      display:inline-flex; align-items:center; gap:8px;
      padding:8px 10px;
      border-radius:999px;
      border:1px solid var(--line);
      background:var(--pill);
      font-size:12px;
      color:var(--text);
      font-weight:800;
    }
    .list{display:flex; flex-direction:column; gap:10px}
    .item{
      border:1px solid var(--line);
      border-radius:16px;
      padding:12px;
      background:rgba(0,0,0,.14);
    }
    .name{font-weight:950}
    .kpis{display:flex; gap:8px; flex-wrap:wrap}
    .hr{height:1px; background:var(--line); margin:12px 0}
    /* Liste ekranında arama sabit kalsın */
    .stickySearch{
      position:sticky; top:58px; z-index:15;
      margin-top:12px;
      background:rgba(7,11,19,.70);
      backdrop-filter: blur(8px);
      padding:10px 0 8px;
      border-bottom:1px solid rgba(255,255,255,.06);
    }

    /* Alt işlem paneli (klavyeyle kavga etmesin) */
    .dock{
      position:fixed; left:0; right:0; bottom:0; z-index:50;
      background:rgba(7,11,19,.92);
      border-top:1px solid var(--line);
      padding:12px 12px calc(12px + env(safe-area-inset-bottom));
    }
    .dock .inner{max-width:560px; margin:0 auto}
    .dock .row{gap:10px}
    .dock .btn{flex:1}

    /* Modal */
    .modal{
      position:fixed; inset:0; z-index:100;
      background:rgba(0,0,0,.55);
      display:none;
      padding:14px;
    }
    .modal.open{display:block}
    .sheet{
      max-width:560px; margin:0 auto;
      background:rgba(15,23,42,.96);
      border:1px solid var(--line);
      border-radius:22px;
      padding:14px;
    }
    .choiceGrid{display:grid; grid-template-columns:1fr 1fr; gap:10px}
    .tag{font-weight:950}
  </style>
</head>
<body>
<header>
  <div class="brand">Stok Kontrol</div>
  <div class="seg" role="tablist" aria-label="Mod">
    <button id="tabOps" class="active" aria-selected="true">İşlem</button>
    <button id="tabList" aria-selected="false">Liste</button>
  </div>
</header>

<main>
  <!-- OPS -->
  <section id="viewOps" class="grid" style="gap:12px">
    <div class="card">
      <div class="h">İşlem Kaydı</div>
      <div class="hint">Mantık: önce <b>işlem türü</b> seçilir, sonra ürün + adet girilir. Böylece “ürün ekledim = otomatik satış/dağılım” saçmalığı biter.</div>
      <div class="hr"></div>

      <div class="grid" style="gap:10px">
        <div class="row between">
          <span class="pill" id="opPill">İşlem seç</span>
          <button class="btn ghost" id="btnPickOp" type="button">İşlem Türü</button>
        </div>

        <input id="prod" class="input" placeholder="Ürün adı" autocomplete="off">
        <div class="row">
          <input id="qty" class="input" type="number" min="1" step="1" inputmode="numeric" placeholder="Adet">
          <button class="btn primary" id="btnAdd" type="button" style="min-width:120px">Kaydet</button>
        </div>

        <div class="hint" id="miniHint">Kaydet’ten sonra imleç tekrar ürün adına döner.</div>
      </div>
    </div>

    <div class="card">
      <div class="row between">
        <div>
          <div class="h">Bugün Özet</div>
          <div class="hint">Son 30 işlem üzerinden hızlı görünüm.</div>
        </div>
        <button class="btn danger" id="btnClearOps" type="button" style="padding:12px 14px">Log Temizle</button>
      </div>
      <div class="hr"></div>
      <div class="kpis" id="kpis"></div>
      <div class="hr"></div>
      <div class="list" id="opsTail"></div>
    </div>
  </section>

  <!-- LIST -->
  <section id="viewList" style="display:none">
    <div class="stickySearch">
      <div class="card" style="padding:12px">
        <div class="row between">
          <div class="h" style="font-size:16px">Ürün Listesi</div>
          <span class="hint" id="listInfo"></span>
        </div>
        <div style="margin-top:10px">
          <input id="q" class="input" type="search" placeholder="Ara... (sabit kalır)" autocomplete="off">
        </div>
      </div>
    </div>

    <div class="card" style="margin-top:12px">
      <div class="hint">Stok = işlemlerin toplamı (artı/eksi). Burada ürün eklemek yok; ürünler zaten işlemlerden doğar.</div>
      <div class="hr"></div>
      <div class="list" id="prodList"></div>
    </div>
  </section>
</main>

<!-- Alt sabit aksiyonlar -->
<div class="dock" id="dock">
  <div class="inner">
    <div class="row">
      <button class="btn" id="btnQuickPlus" type="button">+ Sipariş / Dağılım</button>
      <button class="btn" id="btnQuickMinus" type="button">- Satış / SKT / İade</button>
    </div>
  </div>
</div>

<!-- İşlem seçici -->
<div class="modal" id="dlgOp">
  <div class="sheet">
    <div class="row between">
      <div class="h">İşlem Türü</div>
      <button class="btn" id="opClose" type="button" style="padding:12px 14px">Kapat</button>
    </div>
    <div class="hint" style="margin-top:6px">Önce ana tür, sonra alt kırılım.</div>
    <div class="hr"></div>

    <div class="choiceGrid">
      <button class="btn primary" data-main="ARTI">ARTI (Giriş)</button>
      <button class="btn danger" data-main="EKSI">EKSİ (Çıkış)</button>
    </div>

    <div id="opSub" style="margin-top:12px; display:none">
      <div class="hr"></div>
      <div class="h" style="font-size:15px">Alt Kırılım</div>
      <div class="hint" id="opSubHint"></div>
      <div class="grid" id="opSubBtns" style="margin-top:10px; gap:10px"></div>
    </div>
  </div>
</div>

<script>
(() => {
  // ===== DB =====
  const KEY = "stok_kontrol_v1"; // veriyi kaybetmemek için aynı key
  const $ = (id) => document.getElementById(id);

  const LS = {
    get(k, d){
      try { return JSON.parse(localStorage.getItem(k) || "null") ?? d; }
      catch(_) { return d; }
    },
    set(k, v){ localStorage.setItem(k, JSON.stringify(v)); }
  };

  const uid = () => Math.random().toString(16).slice(2) + Date.now().toString(16);

  let db = LS.get(KEY, { ops: [] });
  if (!db.ops) db.ops = [];

  function save(){ LS.set(KEY, db); }

  // ===== MODEL =====
  // op schema:
  // { id, ts, main:"ARTI"|"EKSI", type:"Siparis"|"Dagilim"|"Satis"|"SKT"|"Iade", sub, name, qty, note }
  const SUBS = {
    ARTI: [
      { type:"Siparis", subs:[
        "Firma • Ziyaret (geldi)",
        "Firma • Telefon geldi",
        "Firma • Telefon edildi",
        "Depo • Merkez depoya",
        "Depo • Şarküteri depoya"
      ]},
      { type:"Dagilim", subs:[
        "Merkez dağılımı • Normal",
        "Merkez dağılımı • İskonto",
        "Merkez dağılımı • Insert"
      ]}
    ],
    EKSI: [
      { type:"Satis", subs:["Normal satış","Insert satış","İskonto satış"]},
      { type:"SKT", subs:["Tarihi geldi","Uyarı (yaklaşan)","İmha"]},
      { type:"Iade", subs:[
        "Müşteri iadesi",
        "Tarihi geçmiş",
        "Fabrika kaynaklı",
        "Raf kaynaklı"
      ]}
    ]
  };

  let currentOp = null; // {main,type,sub}

  function setOp(op){
    currentOp = op;
    const pill = $("opPill");
    if (!op){
      pill.textContent = "İşlem seç";
      pill.style.outline = "none";
      return;
    }
    pill.textContent = (op.main==="ARTI" ? "+ " : "- ") + op.type + (op.sub ? " • " + op.sub : "");
    pill.style.outline = op.main==="ARTI" ? "2px solid rgba(22,163,74,.35)" : "2px solid rgba(239,68,68,.35)";
  }

  // ===== RENDER (flicker azalt: sadece gerektiğinde) =====
  let raf = 0;
  function scheduleRender(){
    if (raf) return;
    raf = requestAnimationFrame(() => { raf = 0; render(); });
  }

  function esc(s){
    return String(s||"").replace(/[&<>"']/g, m => ({
      "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"
    }[m]));
  }

  function calcStocks(){
    // name -> qty
    const m = new Map();
    for (const o of db.ops){
      const name = String(o.name||"").trim();
      if(!name) continue;
      const q = Number(o.qty||0) || 0;
      const sign = (o.main==="ARTI") ? +1 : -1;
      m.set(name, (m.get(name)||0) + sign*q);
    }
    return m;
  }

  function renderOpsTail(){
    const box = $("opsTail");
    box.innerHTML = "";
    const tail = db.ops.slice().sort((a,b)=> (b.ts||0) - (a.ts||0)).slice(0,30);
    if (!tail.length){
      box.innerHTML = `<div class="hint">Henüz işlem yok.</div>`;
      return;
    }
    for (const o of tail){
      const dt = new Date(o.ts||Date.now()).toLocaleString("tr-TR");
      const sign = (o.main==="ARTI")?"+":"-";
      const pillCls = (o.main==="ARTI") ? "pill" : "pill";
      const el = document.createElement("div");
      el.className = "item";
      el.innerHTML = `
        <div class="row between">
          <div class="name">${esc(o.name)} <span class="hint">(${sign}${o.qty})</span></div>
          <span class="${pillCls}">${esc(o.type)}${o.sub?(" • "+esc(o.sub)):""}</span>
        </div>
        <div class="hint" style="margin-top:8px">${esc(dt)}</div>
      `;
      box.appendChild(el);
    }
  }

  function renderKpis(){
    const k = $("kpis");
    const tail = db.ops.slice().sort((a,b)=> (b.ts||0) - (a.ts||0)).slice(0,30);
    const cnt = { ARTI:0, EKSI:0, Siparis:0, Dagilim:0, Satis:0, SKT:0, Iade:0 };
    for (const o of tail){
      if(o.main==="ARTI") cnt.ARTI++;
      if(o.main==="EKSI") cnt.EKSI++;
      if(cnt[o.type]!==undefined) cnt[o.type]++;
    }
    k.innerHTML = `
      <span class="pill">+ ${cnt.ARTI}</span>
      <span class="pill">- ${cnt.EKSI}</span>
      <span class="pill">Sipariş ${cnt.Siparis}</span>
      <span class="pill">Dağılım ${cnt.Dagilim}</span>
      <span class="pill">Satış ${cnt.Satis}</span>
      <span class="pill">SKT ${cnt.SKT}</span>
      <span class="pill">İade ${cnt.Iade}</span>
    `;
  }

  function renderProducts(){
    const q = ($("q").value||"").trim().toLowerCase();
    const stocks = calcStocks();
    const items = Array.from(stocks.entries())
      .map(([name,qty])=>({name,qty}))
      .filter(x=>!q || x.name.toLowerCase().includes(q))
      .sort((a,b)=> b.qty - a.qty);

    $("listInfo").textContent = items.length ? (items.length + " ürün") : "Boş";

    const box = $("prodList");
    box.innerHTML = "";
    if(!items.length){
      box.innerHTML = `<div class="hint">Ürün yok. (Önce işlem girmen lazım)</div>`;
      return;
    }
    for (const it of items){
      const el = document.createElement("div");
      el.className = "item";
      const badge = it.qty < 0 ? `<span class="pill" style="border-color:rgba(239,68,68,.35)">Negatif (${it.qty})</span>`
                  : `<span class="pill" style="border-color:rgba(34,197,94,.35)">Stok ${it.qty}</span>`;
      el.innerHTML = `
        <div class="row between">
          <div class="name">${esc(it.name)}</div>
          ${badge}
        </div>
      `;
      box.appendChild(el);
    }
  }

  function render(){
    renderKpis();
    renderOpsTail();
    renderProducts();
  }

  // ===== FLOW =====
  function addOp(){
    const name = ($("prod").value||"").trim();
    const qty  = Number(($("qty").value||"").trim());
    if(!currentOp){
      alert("Önce işlem türü seç.");
      $("btnPickOp").focus();
      return;
    }
    if(!name){
      alert("Ürün adı yaz.");
      $("prod").focus();
      return;
    }
    if(!qty || qty<1){
      alert("Adet (1+) yaz.");
      $("qty").focus();
      return;
    }

    db.ops.push({
      id: uid(),
      ts: Date.now(),
      main: currentOp.main,
      type: currentOp.type,
      sub: currentOp.sub || null,
      name,
      qty
    });
    // log çok büyümesin
    if(db.ops.length > 5000) db.ops = db.ops.slice(-5000);
    save();

    $("prod").value = "";
    $("qty").value = "";
    // klavyeyle savaşmamak için sadece focus (render önce/sonra değil)
    $("prod").focus({preventScroll:true});
    scheduleRender();
  }

  // ===== TABS =====
  function setTab(which){
    const isOps = which==="ops";
    $("viewOps").style.display = isOps ? "" : "none";
    $("viewList").style.display = isOps ? "none" : "";
    $("tabOps").classList.toggle("active", isOps);
    $("tabList").classList.toggle("active", !isOps);
    $("tabOps").setAttribute("aria-selected", isOps ? "true":"false");
    $("tabList").setAttribute("aria-selected", !isOps ? "true":"false");
    // listeye geçince arama sabit, scroll bozulmasın
    if(!isOps) setTimeout(()=> $("q").focus({preventScroll:true}), 60);
  }

  $("tabOps").onclick = () => setTab("ops");
  $("tabList").onclick = () => setTab("list");

  // ===== OP PICKER =====
  function openDlg(){
    $("dlgOp").classList.add("open");
    $("opSub").style.display = "none";
  }
  function closeDlg(){
    $("dlgOp").classList.remove("open");
  }

  $("btnPickOp").onclick = openDlg;
  $("opClose").onclick = closeDlg;
  $("dlgOp").addEventListener("click",(e)=>{
    if(e.target === $("dlgOp")) closeDlg();
  });

  function showSubs(main){
    const list = SUBS[main] || [];
    const subWrap = $("opSub");
    const subHint = $("opSubHint");
    const subBtns = $("opSubBtns");
    subWrap.style.display = "";
    subBtns.innerHTML = "";

    subHint.textContent = (main==="ARTI")
      ? "Sipariş veya Dağılım seç."
      : "Satış / SKT / İade seç.";

    // önce type seçtir, sonra subs
    for (const g of list){
      const b = document.createElement("button");
      b.className = "btn";
      b.type = "button";
      b.textContent = g.type;
      b.onclick = () => {
        // subs ekranı
        subBtns.innerHTML = "";
        for(const sub of g.subs){
          const sb = document.createElement("button");
          sb.className = (main==="ARTI") ? "btn primary" : "btn danger";
          sb.type = "button";
          sb.textContent = sub;
          sb.onclick = () => {
            setOp({ main, type:g.type, sub });
            closeDlg();
            $("prod").focus({preventScroll:true});
          };
          subBtns.appendChild(sb);
        }
      };
      subBtns.appendChild(b);
    }
  }

  // modal main buttons
  $("dlgOp").querySelectorAll("[data-main]").forEach(btn=>{
    btn.addEventListener("click", ()=>{
      const main = btn.getAttribute("data-main");
      showSubs(main);
    });
  });

  // ===== QUICK BUTTONS =====
  $("btnQuickPlus").onclick = () => { openDlg(); showSubs("ARTI"); };
  $("btnQuickMinus").onclick = () => { openDlg(); showSubs("EKSI"); };

  // ===== EVENTS =====
  $("btnAdd").onclick = addOp;
  $("prod").addEventListener("keydown",(e)=>{
    if(e.key==="Enter"){ e.preventDefault(); $("qty").focus({preventScroll:true}); }
  });
  $("qty").addEventListener("keydown",(e)=>{
    if(e.key==="Enter"){ e.preventDefault(); addOp(); }
  });
  $("q").addEventListener("input", ()=>scheduleRender());

  $("btnClearOps").onclick = ()=>{
    if(!confirm("Log temizlensin mi? (işlemler silinir)")) return;
    db.ops = [];
    save();
    scheduleRender();
  };

  // ===== INIT =====
  setOp(null);
  render();
  $("prod").focus({preventScroll:true});
})();
</script>
</body>
</html>
HTML

git add index.html
git commit -m "v0.9: işlem türü (sipariş/dağılım/satış/skt/iade) + alt kırılım + flicker azalt" || true
git push -u origin main

echo
echo "AÇ (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
