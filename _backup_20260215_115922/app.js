/* stok_kontrol - offline (localStorage)
   FIX A: Modal açıkken Paylaş FAB gizlenir + modal scroll/padding ile Kaydet kapanmaz.
*/
(() => {
  const $ = (id) => document.getElementById(id);

  // Elements
  const screenTitle = $('screenTitle');
  const listEl = $('list');
  const chipsEl = $('chips');

  const btnMenu = $('btnMenu');
  const drawer = $('drawer');
  const drawerBackdrop = $('drawerBackdrop');
  const btnDrawerClose = $('btnDrawerClose');
  const btnAddFromMenu = $('btnAddFromMenu');

  const btnSearch = $('btnSearch');
  const searchWrap = $('searchWrap');
  const q = $('q');
  const btnClear = $('btnClear');

  const shareFab = $('shareFab');
  const shareHint = $('shareHint');

  const modalBackdrop = $('modalBackdrop');
  const modal = $('modal');
  const modalTitle = $('modalTitle');
  const btnModalClose = $('btnModalClose');

  const mode = $('mode');
  const nameInp = $('name');
  const qtyInp = $('qty');
  const teminSel = $('temin');
  const distReasonSel = $('distReason');
  const insertNameInp = $('insertName');
  const price30Sel = $('price30');
  const noteInp = $('note');

  const wSkt = $('w_skt');
  const wInsert = $('w_insert');

  const btnSave = $('btnSave');
  const btnDelete = $('btnDelete');

  const toast = $('toast');

  // State
  let state = {
    view: 'dashboard',   // dashboard | all | skt10 | removed
    searchOn: false,
    query: '',
    editingId: null
  };

  const STORE_KEY = 'stok_kontrol_v2_items';
  const REMOVED_KEY = 'stok_kontrol_v2_removed';

  const today = () => {
    const d = new Date();
    d.setHours(0,0,0,0);
    return d;
  };

  const toYMD = (d) => {
    const y = d.getFullYear();
    const m = String(d.getMonth()+1).padStart(2,'0');
    const day = String(d.getDate()).padStart(2,'0');
    return `${y}-${m}-${day}`;
  };

  const fromYMD = (s) => {
    const [y,m,d] = s.split('-').map(n => parseInt(n,10));
    const dt = new Date(y, (m-1), d);
    dt.setHours(0,0,0,0);
    return dt;
  };

  const fmtTR = (ymd) => {
    const d = fromYMD(ymd);
    const dd = String(d.getDate()).padStart(2,'0');
    const mm = String(d.getMonth()+1).padStart(2,'0');
    const yy = d.getFullYear();
    return `${dd}.${mm}.${yy}`;
  };

  const diffDays = (a, b) => {
    // a-b in days
    const ms = 24*60*60*1000;
    return Math.round((a.getTime()-b.getTime())/ms);
  };

  const load = (key, fallback) => {
    try{
      const raw = localStorage.getItem(key);
      if(!raw) return fallback;
      return JSON.parse(raw);
    }catch(_){ return fallback; }
  };

  const save = (key, val) => localStorage.setItem(key, JSON.stringify(val));

  const getItems = () => load(STORE_KEY, []);
  const setItems = (items) => save(STORE_KEY, items);

  const getRemoved = () => load(REMOVED_KEY, []);
  const setRemoved = (items) => save(REMOVED_KEY, items);

  const uid = () => Math.random().toString(16).slice(2) + Date.now().toString(16);

  function showToast(msg){
    toast.textContent = msg;
    toast.style.display = 'block';
    clearTimeout(showToast._t);
    showToast._t = setTimeout(()=> toast.style.display='none', 1800);
  }

  // Wheel builders
  function buildWheel(container, { monthNumeric=false }){
    container.innerHTML = '';
    const daySel = document.createElement('select');
    const monSel = document.createElement('select');
    const yearSel = document.createElement('select');

    daySel.setAttribute('aria-label','Gün');
    monSel.setAttribute('aria-label','Ay');
    yearSel.setAttribute('aria-label','Yıl');

    for(let d=1; d<=31; d++){
      const o=document.createElement('option');
      o.value=String(d).padStart(2,'0');
      o.textContent=String(d).padStart(2,'0');
      daySel.appendChild(o);
    }

    if(monthNumeric){
      for(let m=1; m<=12; m++){
        const o=document.createElement('option');
        o.value=String(m).padStart(2,'0');
        o.textContent=String(m).padStart(2,'0'); // SKT: numara
        monSel.appendChild(o);
      }
    } else {
      const monthsTR = ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];
      for(let m=1; m<=12; m++){
        const o=document.createElement('option');
        o.value=String(m).padStart(2,'0');
        o.textContent=monthsTR[m-1]; // Insert/Temin: isim olabilir
        monSel.appendChild(o);
      }
    }

    const nowY = new Date().getFullYear();
    for(let y=nowY-1; y<=nowY+15; y++){
      const o=document.createElement('option');
      o.value=String(y);
      o.textContent=String(y);
      yearSel.appendChild(o);
    }

    container.appendChild(daySel);
    container.appendChild(monSel);
    container.appendChild(yearSel);

    function setFromYMD(ymd){
      const [yy,mm,dd] = ymd.split('-');
      daySel.value = dd;
      monSel.value = mm;
      yearSel.value = yy;
    }
    function getYMD(){
      const yy = yearSel.value;
      const mm = monSel.value;
      const dd = daySel.value;
      return `${yy}-${mm}-${dd}`;
    }

    // Default today
    setFromYMD(toYMD(today()));

    return { setFromYMD, getYMD, daySel, monSel, yearSel };
  }

  const wheelSKT = buildWheel(wSkt, { monthNumeric:true });
  const wheelINS = buildWheel(wInsert, { monthNumeric:false });

  // Drawer
  function openDrawer(){
    drawer.classList.add('open');
    drawerBackdrop.classList.add('open');
  }
  function closeDrawer(){
    drawer.classList.remove('open');
    drawerBackdrop.classList.remove('open');
  }

  // Modal (FIX A here)
  function openModal(editId=null){
    state.editingId = editId;

    document.body.classList.add('modal-open'); // <<< FIX A
    modalBackdrop.style.display = 'block';
    modal.style.display = 'block';

    if(editId){
      modalTitle.textContent = 'Düzenle';
      btnDelete.style.display = 'inline-flex';
      fillFormForEdit(editId);
    } else {
      modalTitle.textContent = 'Ürün / Parti Ekle';
      btnDelete.style.display = 'none';
      clearForm();
    }

    // focus
    setTimeout(()=> nameInp.focus(), 50);
  }

  function closeModal(){
    document.body.classList.remove('modal-open'); // <<< FIX A
    modalBackdrop.style.display = 'none';
    modal.style.display = 'none';
    state.editingId = null;
  }

  function clearForm(){
    mode.value = 'new';
    nameInp.value = '';
    qtyInp.value = '';
    teminSel.value = 'Sipariş';
    distReasonSel.value = 'Inserte hazırlık';
    insertNameInp.value = '';
    price30Sel.value = '0';
    noteInp.value = '';
    wheelSKT.setFromYMD(toYMD(today()));
    wheelINS.setFromYMD(toYMD(today()));
  }

  function fillFormForEdit(id){
    const items = getItems();
    const it = items.find(x=>x.id===id);
    if(!it) return;

    mode.value = 'new';
    nameInp.value = it.name || '';
    qtyInp.value = String(it.qty ?? '');
    teminSel.value = it.temin || 'Sipariş';
    distReasonSel.value = it.distReason || 'Inserte hazırlık';
    insertNameInp.value = it.insertName || '';
    price30Sel.value = it.price30 ? '1' : '0';
    noteInp.value = it.note || '';

    wheelSKT.setFromYMD(it.skt || toYMD(today()));
    wheelINS.setFromYMD(it.insertDate || toYMD(today()));
  }

  // Views / filters
  function setView(v){
    state.view = v;
    state.query = '';
    q.value = '';
    render();
  }

  function filteredItems(){
    const items = getItems().filter(x => !x.removed);
    const t = today();

    let arr = items;

    if(state.query.trim()){
      const s = state.query.trim().toLowerCase();
      arr = arr.filter(x =>
        (x.name||'').toLowerCase().includes(s) ||
        (x.temin||'').toLowerCase().includes(s) ||
        (x.insertName||'').toLowerCase().includes(s)
      );
    }

    if(state.view === 'skt10'){
      arr = arr.filter(x => {
        if(!x.skt) return false;
        const d = fromYMD(x.skt);
        const left = diffDays(d, t); // d - today
        return left >= 0 && left <= 10;
      }).sort((a,b)=> fromYMD(a.skt)-fromYMD(b.skt));
    } else if(state.view === 'dashboard'){
      // dashboard: show alerts first (expired + price30)
      arr = arr.slice().sort((a,b)=>{
        const aD = a.skt ? diffDays(fromYMD(a.skt), t) : 99999;
        const bD = b.skt ? diffDays(fromYMD(b.skt), t) : 99999;
        return aD - bD;
      });
    } else if(state.view === 'all'){
      arr = arr.slice().sort((a,b)=> (a.name||'').localeCompare(b.name||'', 'tr'));
    }

    return arr;
  }

  function chipsForView(){
    const items = getItems().filter(x => !x.removed);
    const t = today();

    const total = items.length;

    const expired = items.filter(x => x.skt && diffDays(fromYMD(x.skt), t) <= 0).length;
    const near10 = items.filter(x => x.skt && (()=>{
      const left = diffDays(fromYMD(x.skt), t);
      return left >=0 && left<=10;
    })()).length;
    const price30 = items.filter(x => x.price30 && x.skt && diffDays(fromYMD(x.skt), t) <= 30 && diffDays(fromYMD(x.skt), t) >= 0).length;

    return [
      { label:'Toplam', val: total },
      { label:'SKT geçti/bugün', val: expired },
      { label:'Son 10 gün', val: near10 },
      { label:'Fiyat(30g)', val: price30 }
    ];
  }

  function screenLabel(){
    if(state.view==='dashboard') return 'Ana';
    if(state.view==='all') return 'Tüm Ürünler';
    if(state.view==='skt10') return 'SKT: Son 10 Gün';
    if(state.view==='removed') return 'Kaldırılanlar';
    return 'Ekran';
  }

  function render(){
    const label = screenLabel();
    screenTitle.textContent = `Ekran: ${label}`;
    shareHint.textContent = label;

    // chips
    chipsEl.innerHTML = '';
    const chips = chipsForView();
    for(const c of chips){
      const el = document.createElement('div');
      el.className = 'chip';
      el.innerHTML = `<strong>${c.val}</strong> ${c.label}`;
      chipsEl.appendChild(el);
    }

    // list
    listEl.innerHTML = '';
    if(state.view === 'removed'){
      renderRemoved();
      return;
    }

    const arr = filteredItems();
    if(arr.length === 0){
      const empty = document.createElement('div');
      empty.className = 'card';
      empty.innerHTML = `<div class="name">Liste boş</div><div class="hint">Menüden “Ürün / Parti Ekle” ile kayıt gir.</div>`;
      listEl.appendChild(empty);
      return;
    }

    const frag = document.createDocumentFragment();
    const t = today();

    for(const it of arr){
      const card = document.createElement('div');
      card.className = 'card';
      card.dataset.id = it.id;

      // alert styles
      let blinkClass = '';
      let tags = [];

      if(it.skt){
        const left = diffDays(fromYMD(it.skt), t);
        if(left <= 0){
          blinkClass = 'blink-red'; // SKT geldi/geçti
          tags.push(`<span class="tag red">SKT: ${fmtTR(it.skt)}</span>`);
        } else if(left <= 10){
          tags.push(`<span class="tag dark">SKT: ${fmtTR(it.skt)} (${left}g)</span>`);
        } else {
          tags.push(`<span class="tag">SKT: ${fmtTR(it.skt)}</span>`);
        }

        if(it.price30 && left <= 30 && left >= 0){
          blinkClass = blinkClass || 'blink-green';
          tags.push(`<span class="tag green">Fiyat iste: ${left}g</span>`);
        }
      }

      if(it.temin){
        tags.push(`<span class="tag">Temin: ${it.temin}</span>`);
      }
      if(it.temin === 'Dağılım'){
        tags.push(`<span class="tag">Dağılım/Insert</span>`);
        if(it.insertName) tags.push(`<span class="tag">Insert: ${escapeHtml(it.insertName)}</span>`);
        if(it.insertDate) tags.push(`<span class="tag">Tarih: ${fmtTR(it.insertDate)}</span>`);
      }

      card.classList.add(blinkClass);

      card.innerHTML = `
        <div class="cardTop">
          <div>
            <div class="name">${escapeHtml(it.name || '(İsimsiz)')}</div>
          </div>
          <div class="qty">${Number(it.qty||0)} adet</div>
        </div>
        <div class="meta">${tags.join('')}</div>
        <div class="actionsRow">
          <button class="btn ghost" data-act="edit">Düzenle</button>
          <button class="btn ghost" data-act="remove">Kaldır</button>
        </div>
      `;

      frag.appendChild(card);
    }
    listEl.appendChild(frag);
  }

  function renderRemoved(){
    const arr = getRemoved().slice().reverse();
    if(arr.length===0){
      const empty = document.createElement('div');
      empty.className = 'card';
      empty.innerHTML = `<div class="name">Kaldırılan yok</div><div class="hint">Kaldırdıkların burada görünür.</div>`;
      listEl.appendChild(empty);
      return;
    }

    const frag=document.createDocumentFragment();
    for(const it of arr){
      const card=document.createElement('div');
      card.className='card';
      card.innerHTML = `
        <div class="cardTop">
          <div>
            <div class="name">${escapeHtml(it.name||'(İsimsiz)')}</div>
            <div class="hint">Kaldırma nedeni: <b>${escapeHtml(it.removeReason||'-')}</b> • ${it.removedAt ? fmtTR(it.removedAt) : ''}</div>
          </div>
          <div class="qty">${Number(it.qty||0)} adet</div>
        </div>
        <div class="meta">
          ${it.skt ? `<span class="tag">SKT: ${fmtTR(it.skt)}</span>` : ''}
          ${it.note ? `<span class="tag">Not: ${escapeHtml(it.note)}</span>` : ''}
        </div>
      `;
      frag.appendChild(card);
    }
    listEl.appendChild(frag);
  }

  // Share
  async function shareCurrent(){
    const label = screenLabel();
    let text = `stok_kontrol • ${label}\n`;

    if(state.view==='removed'){
      const arr = getRemoved().slice().reverse().slice(0, 60);
      for(const it of arr){
        text += `• ${it.name} — ${it.qty} adet — Neden: ${it.removeReason || '-'}\n`;
      }
    } else {
      const arr = filteredItems().slice(0, 80);
      for(const it of arr){
        let line = `• ${it.name} — ${it.qty} adet`;
        if(it.skt) line += ` — SKT: ${fmtTR(it.skt)}`;
        if(it.temin) line += ` — ${it.temin}`;
        if(it.temin==='Dağılım' && it.insertName) line += ` — Insert: ${it.insertName}`;
        text += line + '\n';
      }
    }

    try{
      if(navigator.share){
        await navigator.share({ text });
      } else {
        await navigator.clipboard.writeText(text);
        showToast('Paylaşım metni kopyalandı');
      }
    }catch(_){
      // fallback
      try{
        await navigator.clipboard.writeText(text);
        showToast('Paylaşım metni kopyalandı');
      }catch(__){
        alert(text);
      }
    }
  }

  // CRUD
  function upsertItem(){
    const nm = nameInp.value.trim();
    const qty = parseInt(qtyInp.value.trim() || '0', 10);

    if(!nm){
      showToast('Ürün adı gerekli');
      nameInp.focus();
      return;
    }
    if(!Number.isFinite(qty) || qty < 0){
      showToast('Adet sayısı geçersiz');
      qtyInp.focus();
      return;
    }

    const it = {
      id: state.editingId || uid(),
      name: nm,
      qty,
      skt: wheelSKT.getYMD(),
      temin: teminSel.value,
      distReason: distReasonSel.value,
      insertName: insertNameInp.value.trim(),
      insertDate: wheelINS.getYMD(),
      price30: price30Sel.value === '1',
      note: noteInp.value.trim(),
      updatedAt: toYMD(today())
    };

    const items = getItems();
    const idx = items.findIndex(x => x.id === it.id);

    if(idx >= 0){
      items[idx] = { ...items[idx], ...it };
      setItems(items);
      showToast('Güncellendi');
    }else{
      items.push(it);
      setItems(items);
      showToast('Kaydedildi');
    }

    closeModal();
    render();
  }

  function askRemove(id){
    const items = getItems();
    const it = items.find(x=>x.id===id);
    if(!it) return;

    // mini reason picker (prompt)
    const reason = prompt(
`Kaldırma nedeni yaz:
- skt
- fabrika kaynaklı
- kırık, zarar gördü
- diğer`
    );

    if(reason === null) return; // cancel

    const cleaned = reason.trim() || 'diğer';

    // remove from active
    const next = items.filter(x=>x.id!==id);
    setItems(next);

    // push to removed
    const rem = getRemoved();
    rem.push({
      ...it,
      removeReason: cleaned,
      removedAt: toYMD(today())
    });
    setRemoved(rem);

    showToast('Kaldırıldı');
    render();
  }

  // Helpers
  function escapeHtml(s){
    return String(s).replace(/[&<>"']/g, (c)=>({
      '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
    })[c]);
  }

  // Events
  btnMenu.addEventListener('click', openDrawer);
  btnDrawerClose.addEventListener('click', closeDrawer);
  drawerBackdrop.addEventListener('click', closeDrawer);

  drawer.addEventListener('click', (e)=>{
    const b = e.target.closest('button[data-nav]');
    if(!b) return;
    closeDrawer();
    setView(b.dataset.nav);
  });

  btnAddFromMenu.addEventListener('click', ()=>{
    closeDrawer();
    openModal(null);
  });

  btnSearch.addEventListener('click', ()=>{
    state.searchOn = !state.searchOn;
    searchWrap.style.display = state.searchOn ? 'flex' : 'none';
    if(state.searchOn) setTimeout(()=>q.focus(), 50);
    else { state.query=''; q.value=''; render(); }
  });

  q.addEventListener('input', ()=>{
    state.query = q.value;
    render();
  });

  btnClear.addEventListener('click', ()=>{
    state.query='';
    q.value='';
    render();
  });

  shareFab.addEventListener('click', shareCurrent);

  btnModalClose.addEventListener('click', closeModal);
  modalBackdrop.addEventListener('click', closeModal);

  btnSave.addEventListener('click', upsertItem);

  btnDelete.addEventListener('click', ()=>{
    if(!state.editingId) return;
    askRemove(state.editingId);
    closeModal();
  });

  // card actions
  listEl.addEventListener('click', (e)=>{
    const actBtn = e.target.closest('button[data-act]');
    if(!actBtn) return;
    const card = e.target.closest('.card');
    if(!card) return;
    const id = card.dataset.id;
    const act = actBtn.dataset.act;

    if(act==='edit') openModal(id);
    if(act==='remove') askRemove(id);
  });

  // Enter flow: name -> qty -> save
  nameInp.addEventListener('keydown', (e)=>{
    if(e.key==='Enter'){
      e.preventDefault();
      qtyInp.focus();
    }
  });
  qtyInp.addEventListener('keydown', (e)=>{
    if(e.key==='Enter'){
      e.preventDefault();
      btnSave.click();
    }
  });

  // Boot
  setView('dashboard');
})();
