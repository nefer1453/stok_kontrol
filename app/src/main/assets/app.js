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
