(() => {
  "use strict";

  const $ = (id) => document.getElementById(id);
  const pad2 = (n) => String(n).padStart(2, "0");
  const isoToday = () => {
    const d = new Date();
    return `${d.getFullYear()}-${pad2(d.getMonth()+1)}-${pad2(d.getDate())}`;
  };
  const parseISO = (iso) => {
    if (!iso) return null;
    const d = new Date(iso + "T00:00:00");
    return isNaN(d) ? null : d;
  };
  const daysBetween = (a, b) => {
    // b - a (days)
    const ms = 24*60*60*1000;
    const da = new Date(a.getFullYear(), a.getMonth(), a.getDate()).getTime();
    const db = new Date(b.getFullYear(), b.getMonth(), b.getDate()).getTime();
    return Math.round((db - da) / ms);
  };

  const monthTr = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"];

  // -----------------------------
  // Storage
  // -----------------------------
  const KEY = "stok_kontrol_v1";
  const SETKEY = "stok_kontrol_settings_v1";

  const defaultSettings = {
    warnDays: 7,     // yakın
    critDays: 0,     // kritik (0 ve altı)
    sktWindow: 10,   // son X gün listesi
  };

  const loadSettings = () => {
    try {
      const s = JSON.parse(localStorage.getItem(SETKEY) || "null");
      return { ...defaultSettings, ...(s||{}) };
    } catch { return { ...defaultSettings }; }
  };

  const saveSettings = (s) => localStorage.setItem(SETKEY, JSON.stringify(s));

  const loadData = () => {
    try {
      const d = JSON.parse(localStorage.getItem(KEY) || "null");
      if (!d || !Array.isArray(d.items)) return { items: [] };
      return d;
    } catch {
      return { items: [] };
    }
  };

  const saveData = () => localStorage.setItem(KEY, JSON.stringify(state.db));

  // -----------------------------
  // State
  // -----------------------------
  const state = {
    view: "all",
    q: "",
    selectedId: null,
    editingId: null,
    settings: loadSettings(),
    db: loadData(),
  };

  // If empty, seed a couple samples (optional)
  if (state.db.items.length === 0) {
    state.db.items.push(
      mkItem({ name:"Hzbz", qty:5, sktISO:addDaysISO(isoToday(), -0), temin:"Temin", note:"" }),
      mkItem({ name:"Hshs", qty:5, sktISO:addDaysISO(isoToday(), 7), temin:"Temin", note:"" })
    );
    saveData();
  }

  function addDaysISO(iso, days) {
    const d = parseISO(iso) || new Date();
    d.setDate(d.getDate() + days);
    return `${d.getFullYear()}-${pad2(d.getMonth()+1)}-${pad2(d.getDate())}`;
  }

  function uid() {
    return Math.random().toString(16).slice(2) + "-" + Date.now().toString(16);
  }

  function mkItem(p) {
    const now = new Date().toISOString();
    return {
      id: uid(),
      name: (p.name || "").trim(),
      qty: Number(p.qty || 0),
      sktISO: p.sktISO || isoToday(),
      temin: p.temin || "Sipariş",
      dagitimNedeni: p.dagitimNedeni || "",
      insertAdi: (p.insertAdi || "").trim(),
      insertISO: p.insertISO || "",
      note: (p.note || "").trim(),
      createdISO: now,
      updatedISO: now,
    };
  }

  // -----------------------------
  // UI refs
  // -----------------------------
  const listEl = $("list");
  const qEl = $("q");
  const searchRow = $("searchRow");
  const btnSearch = $("btnSearch");
  const btnMenu = $("btnMenu");
  const drawer = $("drawer");
  const menuClose = $("menuClose");
  const menuAdd = $("menuAdd");
  const menuExport = $("menuExport");

  const tabs = Array.from(document.querySelectorAll(".tab"));

  const selectBanner = $("selectBanner");
  const selName = $("selName");
  const selMeta = $("selMeta");
  const btnShareTop = $("btnShareTop");
  const btnClearSel = $("btnClearSel");
  const fabShare = $("fabShare");

  // Modal
  const modal = $("modal");
  const btnCloseModal = $("btnCloseModal");
  const modalTitle = $("modalTitle");
  const modeEl = $("mode");
  const nameEl = $("name");
  const qtyEl = $("qty");
  const teminEl = $("temin");
  const dagitimNedeniEl = $("dagitimNedeni");
  const insertAdiEl = $("insertAdi");
  const noteEl = $("note");
  const btnSave = $("btnSave");
  const btnDelete = $("btnDelete");

  // Date selects (wheel-like)
  const sktD = $("sktD"), sktM = $("sktM"), sktY = $("sktY");
  const insD = $("insD"), insM = $("insM"), insY = $("insY");

  // Titles
  const mainTitle = $("mainTitle");
  const subTitle = $("subTitle");
  const hint = $("hint");

  // -----------------------------
  // Date wheel builders
  // -----------------------------
  function fillSelect(sel, arr, fmt = (x)=>String(x)) {
    sel.innerHTML = "";
    for (const v of arr) {
      const o = document.createElement("option");
      o.value = String(v);
      o.textContent = fmt(v);
      sel.appendChild(o);
    }
  }

  function bindDateWheel({ dSel, mSel, ySel, monthMode }) {
    const years = [];
    const y0 = new Date().getFullYear() - 1;
    const y1 = new Date().getFullYear() + 12;
    for (let y=y0; y<=y1; y++) years.push(y);

    fillSelect(dSel, Array.from({length:31}, (_,i)=>i+1), (v)=>pad2(v));

    fillSelect(mSel, Array.from({length:12}, (_,i)=>i+1), (v)=>{
      if (monthMode === "num") return pad2(v);        // ✅ SKT numara
      return monthTr[v-1];                           // ✅ Insert isim
    });

    fillSelect(ySel, years, (v)=>String(v));

    const api = {
      getISO(){
        const dd = Number(dSel.value);
        const mm = Number(mSel.value);
        const yy = Number(ySel.value);
        // clamp day
        const maxDay = new Date(yy, mm, 0).getDate();
        const day = Math.min(dd, maxDay);
        if (day !== dd) dSel.value = String(day);
        return `${yy}-${pad2(mm)}-${pad2(day)}`;
      },
      setISO(iso){
        const d = parseISO(iso) || new Date();
        dSel.value = String(d.getDate());
        mSel.value = String(d.getMonth()+1);
        ySel.value = String(d.getFullYear());
      }
    };

    // keep day valid when month/year change
    const fix = ()=>{ api.getISO(); };
    mSel.addEventListener("change", fix);
    ySel.addEventListener("change", fix);

    return api;
  }

  const wheelSKT = bindDateWheel({ dSel:sktD, mSel:sktM, ySel:sktY, monthMode:"num" });
  const wheelINS = bindDateWheel({ dSel:insD, mSel:insM, ySel:insY, monthMode:"name" });

  // -----------------------------
  // View helpers
  // -----------------------------
  function setView(v) {
    state.view = v;
    state.selectedId = null;
    syncSelectionUI();
    render();
  }

  function setTitles() {
    const map = {
      all:   { t:"Tüm Ürünler", s:"Ekran" },
      skt10: { t:`SKT: Son ${state.settings.sktWindow} Gün`, s:"Ekran" },
      report:{ t:"Günlük Rapor", s:"Ekran" },
      settings:{ t:"Ayarlar", s:"Ekran" },
    };
    mainTitle.textContent = map[state.view].t;
    subTitle.textContent = map[state.view].s;

    if (state.view === "all") hint.textContent = "Ürüne dokun → seç/düzenle. Menüden “Ürün/Parti Ekle”.";
    if (state.view === "skt10") hint.textContent = "Yakın SKT listesi. Ürüne dokun → seç/düzenle.";
    if (state.view === "report") hint.textContent = "Bugün eklenen/düzenlenen ve SKT yaklaşanlar.";
    if (state.view === "settings") hint.textContent = "Kritik renk eşikleri burada.";
  }

  function badgeForDaysLeft(daysLeft) {
    if (daysLeft <= state.settings.critDays) return { cls:"crit", txt:`Kritik (${daysLeft}g)` };
    if (daysLeft <= state.settings.warnDays) return { cls:"warn", txt:`Yakın (${daysLeft}g)` };
    return { cls:"ok", txt:`İyi (${daysLeft}g)` };
  }

  function fmtTR(iso) {
    const d = parseISO(iso);
    if (!d) return "—";
    return `${pad2(d.getDate())}.${pad2(d.getMonth()+1)}.${d.getFullYear()}`;
  }

  function todayKey() {
    const d = new Date();
    return `${d.getFullYear()}-${pad2(d.getMonth()+1)}-${pad2(d.getDate())}`;
  }

  // -----------------------------
  // Selection + Share
  // -----------------------------
  function getSelected() {
    return state.db.items.find(x => x.id === state.selectedId) || null;
  }

  function syncSelectionUI() {
    const it = getSelected();
    const on = !!it;

    selectBanner.classList.toggle("show", on);
    fabShare.classList.toggle("show", on);

    if (!it) {
      selName.textContent = "Seçim yok";
      selMeta.textContent = "—";
      return;
    }
    selName.textContent = it.name || "(isimsiz)";
    selMeta.textContent = `Adet: ${it.qty} • SKT: ${fmtTR(it.sktISO)} • Temin: ${it.temin || "—"}`;
  }

  function shareTextForItem(it) {
    const daysLeft = daysBetween(new Date(), parseISO(it.sktISO) || new Date());
    const b = badgeForDaysLeft(daysLeft);
    return [
      `Ürün: ${it.name}`,
      `Adet: ${it.qty}`,
      `SKT: ${fmtTR(it.sktISO)} (${b.txt})`,
      `Temin: ${it.temin || ""}`,
      it.dagitimNedeni ? `Dağılım nedeni: ${it.dagitimNedeni}` : "",
      it.insertAdi ? `Insert: ${it.insertAdi}` : "",
      it.insertISO ? `Insert tarihi: ${fmtTR(it.insertISO)}` : "",
      it.note ? `Not: ${it.note}` : "",
    ].filter(Boolean).join("\n");
  }

  function exportCSV(items) {
    const cols = ["id","name","qty","sktISO","temin","dagitimNedeni","insertAdi","insertISO","note","createdISO","updatedISO"];
    const esc = (s) => `"${String(s??"").replaceAll('"','""')}"`;
    const lines = [cols.join(",")];
    for (const it of items) {
      lines.push(cols.map(c => esc(it[c])).join(","));
    }
    return lines.join("\n");
  }

  async function doShareSelectedOrAll(preferSelected=true) {
    const it = getSelected();
    if (preferSelected && it) {
      const text = shareTextForItem(it);
      await shareOrCopy(text);
      return;
    }
    const csv = exportCSV(filteredItemsAll());
    await shareOrCopy(csv, "stok_kontrol.csv");
  }

  async function shareOrCopy(text, filename) {
    try {
      if (navigator.share) {
        // Some webviews require files; fallback to text share.
        await navigator.share({ text });
        toast("Paylaşıldı");
        return;
      }
    } catch {}
    try {
      await navigator.clipboard.writeText(text);
      toast("Panoya kopyalandı");
    } catch {
      // last fallback
      prompt("Kopyala:", text);
    }
  }

  // mini toast
  let toastTimer = null;
  function toast(msg) {
    clearTimeout(toastTimer);
    let t = document.getElementById("toast");
    if (!t) {
      t = document.createElement("div");
      t.id = "toast";
      t.style.position = "fixed";
      t.style.left = "50%";
      t.style.bottom = "84px";
      t.style.transform = "translateX(-50%)";
      t.style.padding = "10px 12px";
      t.style.borderRadius = "999px";
      t.style.border = "1px solid rgba(250,204,21,.25)";
      t.style.background = "rgba(11,47,36,.92)";
      t.style.boxShadow = "0 10px 30px rgba(0,0,0,.35)";
      t.style.zIndex = "99";
      document.body.appendChild(t);
    }
    t.textContent = msg;
    t.style.display = "block";
    toastTimer = setTimeout(()=>{ t.style.display="none"; }, 1200);
  }

  // -----------------------------
  // Filtering + rendering
  // -----------------------------
  function filteredItemsAll() {
    const q = state.q.trim().toLowerCase();
    let arr = state.db.items.slice();

    if (q) {
      arr = arr.filter(it => (it.name||"").toLowerCase().includes(q));
    }

    // default sort: soonest SKT first then name
    arr.sort((a,b) => {
      const da = parseISO(a.sktISO) || new Date(0);
      const db = parseISO(b.sktISO) || new Date(0);
      const x = da.getTime() - db.getTime();
      if (x !== 0) return x;
      return (a.name||"").localeCompare(b.name||"");
    });

    return arr;
  }

  function filteredItemsSKTWindow() {
    const win = Number(state.settings.sktWindow || 10);
    const now = new Date();
    return filteredItemsAll().filter(it => {
      const d = parseISO(it.sktISO);
      if (!d) return false;
      const left = daysBetween(now, d);
      return left <= win;
    });
  }

  function reportData() {
    const today = todayKey();
    const items = state.db.items;

    const createdToday = items.filter(it => (it.createdISO||"").slice(0,10) === today);
    const updatedToday = items.filter(it => (it.updatedISO||"").slice(0,10) === today && (it.createdISO||"").slice(0,10) !== today);

    const now = new Date();
    const soon = items
      .map(it => ({ it, left: daysBetween(now, parseISO(it.sktISO)||now) }))
      .filter(x => x.left <= state.settings.sktWindow)
      .sort((a,b)=>a.left-b.left)
      .slice(0, 30);

    return { createdToday, updatedToday, soon };
  }

  function render() {
    setTitles();
    tabs.forEach(t => t.classList.toggle("active", t.dataset.view === state.view));

    if (state.view === "settings") {
      renderSettings();
      return;
    }
    if (state.view === "report") {
      renderReport();
      return;
    }

    const items = (state.view === "skt10") ? filteredItemsSKTWindow() : filteredItemsAll();

    // fast render with fragment
    listEl.innerHTML = "";
    const frag = document.createDocumentFragment();

    if (items.length === 0) {
      const empty = document.createElement("div");
      empty.className = "card";
      empty.innerHTML = `<div class="h">Liste boş</div><div class="muted" style="margin-top:8px">Menüden “Ürün/Parti Ekle”.</div>`;
      frag.appendChild(empty);
      listEl.appendChild(frag);
      return;
    }

    for (const it of items) {
      const now = new Date();
      const sktD = parseISO(it.sktISO) || now;
      const left = daysBetween(now, sktD);
      const b = badgeForDaysLeft(left);

      const card = document.createElement("div");
      card.className = "card";
      card.dataset.id = it.id;

      const selected = (it.id === state.selectedId);
      const border = selected ? "rgba(250,204,21,.45)" : "rgba(250,204,21,.16)";
      card.style.borderColor = border;

      card.innerHTML = `
        <div class="row space">
          <div class="h">${escapeHtml(it.name || "(isimsiz)")}</div>
          <div class="pill badge">${escapeHtml(String(it.qty))} adet</div>
        </div>

        <div class="row" style="margin-top:10px; flex-wrap:wrap">
          <div class="pill ${b.cls}">${escapeHtml(b.txt)}</div>
          <div class="pill">SKT: ${escapeHtml(fmtTR(it.sktISO))}</div>
          <div class="pill">${escapeHtml(it.temin || "—")}</div>
          ${it.dagitimNedeni ? `<div class="pill">Dağılım/Insert</div>` : ``}
          ${it.insertAdi ? `<div class="pill">Insert: ${escapeHtml(it.insertAdi)}</div>` : ``}
          ${it.insertISO ? `<div class="pill">Tarih: ${escapeHtml(fmtTR(it.insertISO))}</div>` : ``}
        </div>

        <div class="row space" style="margin-top:12px; gap:10px; flex-wrap:wrap">
          <button class="btn danger btnRemove">Kaldır</button>
          <div class="muted" style="font-size:12px">Dokun: seç/düzenle</div>
        </div>
      `;

      // interactions
      card.addEventListener("click", (e) => {
        const btn = e.target.closest("button");
        if (btn) return; // buttons handled below
        // first tap: select, second tap: edit
        if (state.selectedId !== it.id) {
          state.selectedId = it.id;
          syncSelectionUI();
          render();
        } else {
          openModalForEdit(it.id);
        }
      });

      card.querySelector(".btnRemove").addEventListener("click", (e) => {
        e.stopPropagation();
        removeItem(it.id);
      });

      frag.appendChild(card);
    }

    listEl.appendChild(frag);
  }

  function renderSettings() {
    listEl.innerHTML = "";
    const c = document.createElement("div");
    c.className = "card";
    c.innerHTML = `
      <div class="h">Ayarlar</div>
      <div class="muted" style="margin-top:6px; font-size:12px">Renk eşikleri ve SKT penceresi.</div>

      <div class="grid two" style="margin-top:12px">
        <div>
          <label>Yakın gün eşiği (warnDays)</label>
          <input class="inp" id="setWarn" inputmode="numeric" value="${escapeHtml(String(state.settings.warnDays))}" />
        </div>
        <div>
          <label>Kritik gün eşiği (critDays)</label>
          <input class="inp" id="setCrit" inputmode="numeric" value="${escapeHtml(String(state.settings.critDays))}" />
        </div>
      </div>

      <div style="margin-top:10px">
        <label>SKT penceresi (Son X gün)</label>
        <input class="inp" id="setWin" inputmode="numeric" value="${escapeHtml(String(state.settings.sktWindow))}" />
      </div>

      <div class="footRow">
        <button class="btn" id="btnSaveSet">Kaydet</button>
      </div>
    `;
    listEl.appendChild(c);

    c.querySelector("#btnSaveSet").addEventListener("click", () => {
      const warn = Number(c.querySelector("#setWarn").value || 7);
      const crit = Number(c.querySelector("#setCrit").value || 0);
      const win = Number(c.querySelector("#setWin").value || 10);

      state.settings.warnDays = isFinite(warn) ? warn : 7;
      state.settings.critDays = isFinite(crit) ? crit : 0;
      state.settings.sktWindow = isFinite(win) ? win : 10;

      saveSettings(state.settings);
      toast("Ayarlar kaydedildi");
      render();
    });
  }

  function renderReport() {
    listEl.innerHTML = "";
    const r = reportData();

    const c = document.createElement("div");
    c.className = "card";
    c.innerHTML = `
      <div class="h">Günlük Rapor</div>
      <div class="muted" style="margin-top:6px; font-size:12px">${escapeHtml(todayKey())}</div>

      <div style="margin-top:12px" class="row" >
        <div class="pill ok">Bugün eklenen: ${r.createdToday.length}</div>
        <div class="pill warn">Bugün düzenlenen: ${r.updatedToday.length}</div>
      </div>

      <div class="muted" style="margin-top:12px; font-size:12px">SKT yaklaşan (ilk 30):</div>
      <div id="repSoon" style="margin-top:8px"></div>

      <div class="footRow">
        <button class="btn" id="btnShareReport">Raporu Paylaş</button>
      </div>
    `;
    listEl.appendChild(c);

    const repSoon = c.querySelector("#repSoon");
    if (r.soon.length === 0) {
      repSoon.innerHTML = `<div class="muted">Yakın SKT yok.</div>`;
    } else {
      const f = document.createDocumentFragment();
      for (const x of r.soon) {
        const it = x.it;
        const b = badgeForDaysLeft(x.left);
        const row = document.createElement("div");
        row.style.marginBottom = "8px";
        row.innerHTML = `
          <div class="row space" style="gap:10px">
            <div style="min-width:0">
              <div class="h" style="font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis">${escapeHtml(it.name)}</div>
              <div class="muted" style="font-size:12px">SKT: ${escapeHtml(fmtTR(it.sktISO))}</div>
            </div>
            <div class="pill ${b.cls}">${escapeHtml(b.txt)}</div>
          </div>
        `;
        row.addEventListener("click", () => {
          state.selectedId = it.id;
          syncSelectionUI();
          setView("all");
        });
        f.appendChild(row);
      }
      repSoon.appendChild(f);
    }

    c.querySelector("#btnShareReport").addEventListener("click", async () => {
      const txt = buildReportText(r);
      await shareOrCopy(txt);
    });
  }

  function buildReportText(r) {
    const lines = [];
    lines.push(`Günlük Rapor (${todayKey()})`);
    lines.push(`Bugün eklenen: ${r.createdToday.length}`);
    lines.push(`Bugün düzenlenen: ${r.updatedToday.length}`);
    lines.push("");
    lines.push(`SKT yaklaşan (ilk 30):`);
    if (r.soon.length === 0) lines.push("—");
    else {
      for (const x of r.soon) {
        const it = x.it;
        const b = badgeForDaysLeft(x.left);
        lines.push(`- ${it.name} | ${it.qty} adet | SKT ${fmtTR(it.sktISO)} (${b.txt})`);
      }
    }
    return lines.join("\n");
  }

  function escapeHtml(s) {
    return String(s)
      .replaceAll("&","&amp;")
      .replaceAll("<","&lt;")
      .replaceAll(">","&gt;")
      .replaceAll('"',"&quot;")
      .replaceAll("'","&#39;");
  }

  // -----------------------------
  // CRUD
  // -----------------------------
  function removeItem(id) {
    const i = state.db.items.findIndex(x => x.id === id);
    if (i < 0) return;
    state.db.items.splice(i, 1);
    if (state.selectedId === id) state.selectedId = null;
    saveData();
    syncSelectionUI();
    render();
  }

  function upsertItem(item) {
    const i = state.db.items.findIndex(x => x.id === item.id);
    if (i >= 0) state.db.items[i] = item;
    else state.db.items.push(item);
    saveData();
  }

  // -----------------------------
  // Modal open/close
  // -----------------------------
  function openModalForNew() {
    state.editingId = null;
    modalTitle.textContent = "Ürün / Parti Ekle";
    btnDelete.style.display = "none";

    modeEl.value = "new";
    nameEl.value = "";
    qtyEl.value = "";
    teminEl.value = "Sipariş";
    dagitimNedeniEl.value = "";
    insertAdiEl.value = "";
    noteEl.value = "";

    wheelSKT.setISO(isoToday());
    wheelINS.setISO(isoToday());

    showModal();
    setTimeout(() => nameEl.focus(), 80);
  }

  function openModalForEdit(id) {
    const it = state.db.items.find(x => x.id === id);
    if (!it) return;
    state.editingId = id;
    modalTitle.textContent = "Düzenle";
    btnDelete.style.display = "inline-block";

    modeEl.value = "new";
    nameEl.value = it.name || "";
    qtyEl.value = String(it.qty ?? "");
    teminEl.value = it.temin || "Sipariş";
    dagitimNedeniEl.value = it.dagitimNedeni || "";
    insertAdiEl.value = it.insertAdi || "";
    noteEl.value = it.note || "";

    wheelSKT.setISO(it.sktISO || isoToday());
    wheelINS.setISO(it.insertISO || isoToday());

    showModal();
    setTimeout(() => nameEl.focus(), 80);
  }

  function showModal() { modal.classList.add("show"); }
  function closeModal() { modal.classList.remove("show"); }

  // -----------------------------
  // Save from modal
  // -----------------------------
  function saveFromModal() {
    const name = (nameEl.value || "").trim();
    const qty = Number(qtyEl.value || 0);
    if (!name) { toast("İsim boş olamaz"); nameEl.focus(); return; }

    const sktISO = wheelSKT.getISO();
    const temin = teminEl.value || "Sipariş";
    const dagitimNedeni = dagitimNedeniEl.value || "";
    const insertAdi = (insertAdiEl.value || "").trim();
    const insertISO = insertAdi || dagitimNedeni ? wheelINS.getISO() : ""; // only meaningful when distribution/insert used
    const note = (noteEl.value || "").trim();

    const now = new Date().toISOString();

    if (state.editingId) {
      const old = state.db.items.find(x => x.id === state.editingId);
      if (!old) return;
      const updated = { ...old, name, qty, sktISO, temin, dagitimNedeni, insertAdi, insertISO, note, updatedISO: now };
      upsertItem(updated);
      state.selectedId = updated.id;
    } else {
      const it = mkItem({ name, qty, sktISO, temin, dagitimNedeni, insertAdi, insertISO, note });
      it.updatedISO = now;
      upsertItem(it);
      state.selectedId = it.id;
    }

    closeModal();
    syncSelectionUI();
    render();
    toast("Kaydedildi");
  }

  // -----------------------------
  // Events
  // -----------------------------
  btnSearch.addEventListener("click", () => {
    searchRow.classList.toggle("show");
    if (searchRow.classList.contains("show")) setTimeout(()=>qEl.focus(), 50);
    else { state.q=""; qEl.value=""; render(); }
  });

  qEl.addEventListener("input", () => {
    state.q = qEl.value || "";
    render();
  });

  btnMenu.addEventListener("click", () => drawer.classList.add("show"));
  menuClose.addEventListener("click", () => drawer.classList.remove("show"));
  drawer.addEventListener("click", (e) => { if (e.target === drawer) drawer.classList.remove("show"); });

  menuAdd.addEventListener("click", () => {
    drawer.classList.remove("show");
    openModalForNew();
  });

  menuExport.addEventListener("click", async () => {
    drawer.classList.remove("show");
    await doShareSelectedOrAll(true);
  });

  btnCloseModal.addEventListener("click", closeModal);
  modal.addEventListener("click", (e) => { if (e.target === modal) closeModal(); });

  btnSave.addEventListener("click", saveFromModal);

  btnDelete.addEventListener("click", () => {
    if (!state.editingId) return;
    removeItem(state.editingId);
    closeModal();
    toast("Silindi");
  });

  btnClearSel.addEventListener("click", () => {
    state.selectedId = null;
    syncSelectionUI();
    render();
  });

  btnShareTop.addEventListener("click", async () => {
    await doShareSelectedOrAll(true);
  });

  fabShare.addEventListener("click", async () => {
    await doShareSelectedOrAll(true);
  });

  // Enter flow: name -> qty -> save
  nameEl.addEventListener("keydown", (e) => {
    if (e.key === "Enter") { e.preventDefault(); qtyEl.focus(); }
  });
  qtyEl.addEventListener("keydown", (e) => {
    if (e.key === "Enter") { e.preventDefault(); saveFromModal(); }
  });

  tabs.forEach(t => t.addEventListener("click", () => setView(t.dataset.view)));

  // Initial
  syncSelectionUI();
  render();

})();
