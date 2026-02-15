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
      10475 3003 9997 20475 50475 99909997"criticalDays").value = (p?.criticalDays ?? "0");
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
    const cd = Number(p.criticalDays ?? 0);
      const critical = (d !== 99999) && (d <= cd);
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
    const critical=arr.filter(p=>{ const d=daysUntil(p.skt); const cd=Number(p.criticalDays ?? 0); return (d!==99999) && (d<=cd); });
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
    const critical = arr.filter(p=>{ const d=daysUntil(p.skt); const cd=Number(p.criticalDays ?? 0); return (d!==99999) && (d<=cd); });
    const price = arr.filter(p=>{
      const d=daysUntil(p.skt);
      const pd=Number(p.priceDays||0);
      return pd>0 && d<=pd && d>=0;
    });

    const fmt = (p)=>{
      const d=daysUntil(p.skt);
      const pd=Number(p.priceDays||0);
      const cd = Number(p.criticalDays ?? 0);
        const isCrit = (d!==99999) && (d<=cd);
        const tag = isCrit ? "KRİTİK" : (pd>0 && d<=pd ? "FİYAT" : "NORMAL");
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
        criticalDays: parseInt((10475 3003 9997 20475 50475 99909997"criticalDays").value||"0"),10)||0,
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
