set -e

cd "$(dirname "$0")"
ts=$(date +%Y%m%d_%H%M%S)

# yedek
mkdir -p _backup
[ -f index.html ] && cp -f index.html "_backup/index.html.bak.$ts" || true

# v0.7 index.html (tam dosya)
cat > index.html <<'HTML'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Stok Kontrol Motoru</title>
  <style>
    :root{
      --bg:#0b1220; --card:#0f172a; --card2:#0b1530;
      --text:#e5e7eb; --muted:#94a3b8; --line:rgba(148,163,184,.18);
      --green:#16a34a; --red:#ef4444; --amber:#f59e0b; --blue:#3b82f6;
      --r:18px;
    }
    *{box-sizing:border-box}
    body{margin:0;background:linear-gradient(180deg,#050914 0%, #0b1220 60%, #050914 100%);color:var(--text);
      font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial}
    header{
      position:sticky; top:0; z-index:50;
      background:rgba(5,9,20,.72); backdrop-filter: blur(10px);
      border-bottom:1px solid var(--line);
      padding:14px 14px 10px;
    }
    .h1{font-weight:950;font-size:18px}
    .hint{color:var(--muted);font-size:12px;line-height:1.35}
    main{max-width:680px;margin:0 auto;padding:14px 14px 120px}
    .card{background:linear-gradient(180deg,rgba(15,23,42,.92),rgba(11,21,48,.92));
      border:1px solid var(--line); border-radius:var(--r); padding:14px}
    .row{display:flex;align-items:center;gap:10px}
    .between{justify-content:space-between}
    .grid2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
    .grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px}
    input,select,textarea{
      width:100%; padding:14px 14px; border-radius:16px;
      border:1px solid var(--line); outline:none;
      background:rgba(2,6,23,.55); color:var(--text); font-size:16px;
    }
    textarea{min-height:80px; resize:none}
    .btn{
      user-select:none; -webkit-tap-highlight-color:transparent;
      padding:14px 14px; border-radius:16px;
      border:1px solid rgba(148,163,184,.22);
      background:rgba(2,6,23,.35);
      color:var(--text); font-weight:900; letter-spacing:.2px;
      cursor:pointer;
    }
    .btn.primary{background:linear-gradient(180deg,rgba(22,163,74,.95),rgba(16,120,58,.95)); border-color:rgba(34,197,94,.35)}
    .btn.danger{background:linear-gradient(180deg,rgba(239,68,68,.92),rgba(185,28,28,.92)); border-color:rgba(248,113,113,.35)}
    .btn.secondary{background:rgba(2,6,23,.55)}
    .pill{display:inline-flex;align-items:center;gap:6px;padding:6px 10px;border-radius:999px;
      border:1px solid var(--line); color:var(--muted); font-size:12px; font-weight:800}
    .pill.g{color:#bbf7d0;border-color:rgba(34,197,94,.25)}
    .pill.r{color:#fecaca;border-color:rgba(248,113,113,.25)}
    .pill.b{color:#bfdbfe;border-color:rgba(59,130,246,.25)}
    .sep{height:1px;background:var(--line);margin:10px 0}
    .list{display:flex;flex-direction:column;gap:10px}
    .item{padding:12px;border:1px solid var(--line);border-radius:16px;background:rgba(2,6,23,.25)}
    .name{font-weight:950}
    .tiny{font-size:11px;color:var(--muted)}
    .mono{font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace}
    .bottomDock{
      position:fixed; left:0; right:0; bottom:0; z-index:80;
      background:rgba(5,9,20,.75); backdrop-filter: blur(12px);
      border-top:1px solid var(--line);
      padding:10px 12px calc(10px + env(safe-area-inset-bottom, 0px));
    }
    .bottomDock .wrap{max-width:680px;margin:0 auto;display:grid;grid-template-columns:1fr 1fr;gap:10px}
    .view{display:none}
    .view.on{display:block}
    /* küçük ekranda rahat */
    @media (max-width:420px){ input,select,textarea,.btn{font-size:16px} }
  </style>
</head>
<body>
<header>
  <div class="row between">
    <div>
      <div class="h1">Stok Kontrol Motoru</div>
      <div class="hint">v0.7 — ürün + işlem kaydı + özet analiz (net stok / artış / azalış / son işlemler)</div>
    </div>
    <div class="pill b" id="topInfo">0 ürün</div>
  </div>
</header>

<main>
  <!-- ÜRÜN -->
  <section class="card view on" id="vProducts">
    <div class="row between">
      <div>
        <div class="name">Ürünler</div>
        <div class="hint">Ürün ekle, sonra işlem gir (satış/sipariş/dağılım/skt/iade).</div>
      </div>
      <button class="btn secondary" id="btnGoOps">İşlem</button>
    </div>

    <div class="sep"></div>

    <div class="row">
      <input id="prodName" placeholder="Ürün adı (örn: Kaşar 700g)" autocomplete="off" />
      <button class="btn primary" id="btnAddProd">Ekle</button>
    </div>

    <div class="row">
      <input id="q" placeholder="Ara... (sabit)" autocomplete="off" />
      <span class="pill" id="prodInfo">Boş</span>
    </div>

    <div class="list" id="prodList"></div>
  </section>

  <!-- İŞLEM -->
  <section class="card view" id="vOps" style="margin-top:12px">
    <div class="row between">
      <div>
        <div class="name">İşlem Girişi</div>
        <div class="hint">İşlem seç → alt kırılım → adet → kaydet.</div>
      </div>
      <button class="btn secondary" id="btnGoProducts">Ürün</button>
    </div>

    <div class="sep"></div>

    <div class="grid2">
      <select id="opProduct"></select>
      <input id="opQty" type="number" min="1" step="1" placeholder="Adet (örn: 2)" />
    </div>

    <div class="grid2" style="margin-top:10px">
      <select id="opType">
        <option value="siparis">Sipariş (ARTI)</option>
        <option value="dagitim">Dağılım (ARTI)</option>
        <option value="satis">Satış (EKSİ)</option>
        <option value="skt">SKT (EKSİ)</option>
        <option value="iade">İade (EKSİ)</option>
      </select>
      <select id="opSub"></select>
    </div>

    <div style="margin-top:10px">
      <input id="opNote" placeholder="Not (opsiyonel) — örn: insert adı / tarih aralığı" />
    </div>

    <div class="grid2" style="margin-top:10px">
      <button class="btn primary" id="btnAddOp">Kaydet</button>
      <button class="btn danger" id="btnClearOps">Log temizle</button>
    </div>

    <div class="sep"></div>

    <div class="row between">
      <div class="name">Son işlemler</div>
      <span class="pill" id="opsInfo">0</span>
    </div>
    <div class="list" id="opsList"></div>
  </section>
</main>

<!-- ALT SABİT NAV -->
<nav class="bottomDock" aria-label="Alt menü">
  <div class="wrap">
    <button class="btn secondary" id="dockProducts">Ürünler</button>
    <button class="btn primary" id="dockOps">İşlem</button>
  </div>
</nav>

<script>
(() => {
  const KEY = "stok_kontrol_v1";
  const $ = (id) => document.getElementById(id);

  const LS = {
    get(k, d){
      try{ return JSON.parse(localStorage.getItem(k)||"null") ?? d; }
      catch(_){ return d; }
    },
    set(k, v){ localStorage.setItem(k, JSON.stringify(v)); }
  };

  // --- DB normalize (eski formatları da kırmadan) ---
  function normDB(raw){
    const d = raw && typeof raw === "object" ? raw : {};
    const items = Array.isArray(d.items) ? d.items : (Array.isArray(d.products) ? d.products : []);
    const ops = Array.isArray(d.ops) ? d.ops : [];
    // ürün objesi: {id,name,ts}
    return { items: items.map(x => ({
      id: String(x.id ?? (Math.random().toString(16).slice(2)+Date.now().toString(16))),
      name: String(x.name ?? x.title ?? "").trim(),
      ts: Number(x.ts ?? Date.now())
    })).filter(x => x.name),
    ops: ops.map(o => ({
      id: String(o.id ?? (Math.random().toString(16).slice(2)+Date.now().toString(16))),
      ts: Number(o.ts ?? Date.now()),
      pid: String(o.pid ?? o.itemId ?? ""),
      name: String(o.name ?? ""),
      type: String(o.type ?? ""),
      sub: String(o.sub ?? o.reason ?? ""),
      qty: Number(o.qty ?? 0),
      note: o.note ? String(o.note) : ""
    })).filter(o => o.pid && o.qty > 0 && o.type)
    };
  }

  let db = normDB(LS.get(KEY, {items:[], ops:[]}));
  function save(){ LS.set(KEY, db); }

  function uid(){ return Math.random().toString(16).slice(2) + Date.now().toString(16); }
  function esc(s){ return String(s||"").replace(/[&<>"']/g,m=>({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[m])); }
  function fmtDT(ts){ try{ return new Date(ts).toLocaleString("tr-TR"); }catch(_){ return ""; } }

  // --- SUB seçenekleri ---
  const SUB = {
    siparis: [
      ["firma_ziyaret","Firma siparişi: mağazaya ziyareti"],
      ["firma_geldi","Firma siparişi: telefon geldi"],
      ["firma_arandi","Firma siparişi: telefon edildi"],
      ["depo_merkez","Depoya sipariş: merkez depo"],
      ["depo_sarkuteri","Depoya sipariş: şarküteri depo"],
    ],
    dagitim: [
      ["dag_merkez","Dağılım: merkez dağılımı"],
      ["dag_iskonto","Dağılım: iskonto"],
      ["dag_insert","Dağılım: insert dağılımı"],
    ],
    satis: [
      ["satis_normal","Satış: normal"],
      ["satis_insert","Satış: insert"],
      ["satis_iskonto","Satış: iskonto"],
    ],
    skt: [
      ["skt_tarihi_gecti","SKT: tarihi geçti"],
      ["skt_rafsorun","SKT: raf kaynaklı sorun"],
    ],
    iade: [
      ["iade_musteri","İade: müşteri iadesi"],
      ["iade_fabrika","İade: fabrika kaynaklı sorun"],
      ["iade_bozo","İade: bozuldu/ayıp"],
    ],
  };

  function opSign(type){
    // ARTI tetikleyiciler
    if(type === "siparis" || type === "dagitim") return +1;
    // EKSİ tetikleyiciler
    return -1; // satis, skt, iade
  }

  function computeStatsFor(pid){
    const ops = db.ops.filter(o => o.pid === pid).sort((a,b)=> (a.ts||0)-(b.ts||0));
    let plus = 0, minus = 0;
    const countByType = {};
    for(const o of ops){
      const s = opSign(o.type) * (o.qty||0);
      if(s >= 0) plus += s; else minus += (-s);
      countByType[o.type] = (countByType[o.type]||0) + 1;
    }
    let topType = "";
    let topN = 0;
    for(const k in countByType){
      if(countByType[k] > topN){ topN = countByType[k]; topType = k; }
    }
    const last = ops.slice(-5).reverse();
    return {
      net: plus - minus,
      plus, minus,
      topType, topN,
      last
    };
  }

  // --- Views ---
  function show(viewId){
    for(const el of document.querySelectorAll(".view")) el.classList.remove("on");
    $(viewId).classList.add("on");
  }

  // --- Render products ---
  function renderProducts(){
    $("topInfo").textContent = db.items.length + " ürün";
    const q = ($("q").value||"").trim().toLowerCase();
    const rows = db.items
      .filter(it => !q || it.name.toLowerCase().includes(q))
      .slice()
      .sort((a,b)=> b.ts - a.ts);

    $("prodInfo").textContent = rows.length ? (rows.length+" gösterim") : "Boş";

    const box = $("prodList");
    box.innerHTML = "";
    if(!rows.length){
      box.innerHTML = `<div class="item"><div class="hint">Henüz ürün yok.</div></div>`;
      return;
    }

    for(const it of rows){
      const st = computeStatsFor(it.id);

      const el = document.createElement("div");
      el.className = "item";

      const netPill = st.net >= 0
        ? `<span class="pill g">Net: +${st.net}</span>`
        : `<span class="pill r">Net: -${Math.abs(st.net)}</span>`;

      const topLabel = st.topType ? st.topType.toUpperCase() : "-";
      const lastHtml = st.last.length
        ? st.last.map(o => {
            const sign = opSign(o.type) > 0 ? "+" : "-";
            return `<div class="tiny mono">${esc(fmtDT(o.ts))} • ${esc(o.type)} • ${esc(o.sub||"-")} • ${sign}${o.qty}${o.note?` • ${esc(o.note)}`:""}</div>`;
          }).join("")
        : `<div class="tiny">İşlem yok.</div>`;

      el.innerHTML = `
        <div class="row between" style="gap:12px">
          <div style="min-width:0;flex:1">
            <div class="name">${esc(it.name)}</div>
            <div class="row" style="margin-top:8px;flex-wrap:wrap">
              ${netPill}
              <span class="pill b">Artış: +${st.plus}</span>
              <span class="pill r">Azalış: -${st.minus}</span>
              <span class="pill">Top: ${esc(topLabel)} (${st.topN||0})</span>
            </div>
          </div>
          <button class="btn secondary" data-pick="${esc(it.id)}">Seç</button>
        </div>

        <div class="sep"></div>
        <div class="hint" style="margin-bottom:6px">Son 5 işlem</div>
        ${lastHtml}
      `;

      el.querySelector("[data-pick]").onclick = () => {
        $("opProduct").value = it.id;
        show("vOps");
        setTimeout(() => $("opQty").focus(), 80);
      };

      box.appendChild(el);
    }
  }

  // --- Render ops ---
  function renderOps(){
    $("opsInfo").textContent = String(db.ops.length);
    const rows = db.ops.slice().sort((a,b)=> (b.ts||0)-(a.ts||0)).slice(0, 40);
    const box = $("opsList");
    box.innerHTML = "";
    if(!rows.length){
      box.innerHTML = `<div class="item"><div class="hint">Log boş.</div></div>`;
      return;
    }
    for(const o of rows){
      const sign = opSign(o.type) > 0 ? "+" : "-";
      const el = document.createElement("div");
      el.className = "item";
      el.innerHTML = `
        <div class="row between" style="gap:12px">
          <div style="flex:1;min-width:0">
            <div class="name">${esc(o.name || "-")}</div>
            <div class="tiny mono">${esc(fmtDT(o.ts))} • ${esc(o.type)} • ${esc(o.sub||"-")} • ${sign}${o.qty}${o.note?` • ${esc(o.note)}`:""}</div>
          </div>
          <button class="btn secondary" data-del="${esc(o.id)}">Sil</button>
        </div>
      `;
      el.querySelector("[data-del]").onclick = () => {
        if(!confirm("Bu işlem silinsin mi?")) return;
        db.ops = db.ops.filter(x => x.id !== o.id);
        save(); renderOps(); renderProducts();
      };
      box.appendChild(el);
    }
  }

  function fillProductSelect(){
    const sel = $("opProduct");
    sel.innerHTML = "";
    const items = db.items.slice().sort((a,b)=> a.name.localeCompare(b.name, "tr"));
    for(const it of items){
      const opt = document.createElement("option");
      opt.value = it.id;
      opt.textContent = it.name;
      sel.appendChild(opt);
    }
  }

  function fillSubSelect(){
    const t = $("opType").value;
    const sel = $("opSub");
    sel.innerHTML = "";
    const rows = SUB[t] || [["-", "—"]];
    for(const [v, label] of rows){
      const opt = document.createElement("option");
      opt.value = v;
      opt.textContent = label;
      sel.appendChild(opt);
    }
  }

  function addProduct(){
    const name = ($("prodName").value || "").trim();
    if(!name){ alert("Ürün adı yaz."); $("prodName").focus(); return; }
    db.items.push({id: uid(), name, ts: Date.now()});
    save();
    $("prodName").value = "";
    $("prodName").focus();
    fillProductSelect();
    renderProducts();
  }

  function addOp(){
    if(!db.items.length){ alert("Önce ürün ekle."); show("vProducts"); $("prodName").focus(); return; }
    const pid = $("opProduct").value;
    const qty = Number(($("opQty").value || "").trim());
    if(!pid){ alert("Ürün seç."); return; }
    if(!qty || qty <= 0){ alert("Adet yaz (1+)."); $("opQty").focus(); return; }
    const type = $("opType").value;
    const sub = $("opSub").value;
    const note = ($("opNote").value || "").trim();

    const p = db.items.find(x => x.id === pid);
    const name = p ? p.name : "";

    db.ops.push({id: uid(), ts: Date.now(), pid, name, type, sub, qty, note});
    // log şişmesin
    if(db.ops.length > 3000) db.ops = db.ops.slice(-3000);

    save();
    $("opQty").value = "";
    $("opNote").value = "";
    $("opQty").focus();
    renderOps();
    renderProducts();
  }

  // --- Events ---
  $("btnAddProd").onclick = addProduct;
  $("prodName").addEventListener("keydown", (e) => {
    if(e.key === "Enter"){ e.preventDefault(); addProduct(); }
  });
  $("q").addEventListener("input", renderProducts);

  $("btnGoOps").onclick = () => { show("vOps"); setTimeout(() => $("opQty").focus(), 80); };
  $("btnGoProducts").onclick = () => { show("vProducts"); setTimeout(() => $("prodName").focus(), 80); };

  $("dockProducts").onclick = () => { show("vProducts"); setTimeout(() => $("prodName").focus(), 80); };
  $("dockOps").onclick = () => { show("vOps"); setTimeout(() => $("opQty").focus(), 80); };

  $("opType").addEventListener("change", fillSubSelect);

  $("btnAddOp").onclick = addOp;
  $("opQty").addEventListener("keydown", (e) => {
    if(e.key === "Enter"){ e.preventDefault(); addOp(); }
  });

  $("btnClearOps").onclick = () => {
    if(!confirm("Tüm işlem logu silinsin mi?")) return;
    db.ops = [];
    save();
    renderOps(); renderProducts();
  };

  // --- init ---
  fillProductSelect();
  fillSubSelect();
  renderProducts();
  renderOps();

  // ilk açılış fokus
  setTimeout(() => { try{ $("prodName").focus(); }catch(_){} }, 120);
})();
</script>
</body>
</html>
HTML

# commit + push
git add index.html
git commit -m "v0.7 analytics: net/plus/minus + last ops + top type" || true
git push -u origin main

echo
echo "✅ v0.7 hazır."
echo "👉 Link (kopyalanabilir): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
