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
