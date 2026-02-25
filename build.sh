set -e
cd "$(dirname "$0")"

# 1) klasör düzeni
mkdir -p src

# 2) gitignore (repo şişmesin)
cat > .gitignore <<'GI'
_backup/
*.bak.*
index.html.BACKUP*
patch_*.sh
apply_*.sh
install*.sh
.trigger*
GI

# 3) KAYNAK (tek gerçek) — şimdilik buraya koyuyoruz
# Bundan sonra her geliştirmeyi src/app.html içinde yapacağız.
if [ ! -f src/app.html ]; then
cat > src/app.html <<'HTML'
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Stok Kontrol Motoru</title>
  <meta name="theme-color" content="#0b1220">
  <style>
    :root{
      --bg:#070b14; --card:#0b1220; --card2:#0d1730;
      --text:#e5e7eb; --muted:#94a3b8; --line:rgba(255,255,255,.08);
      --ok:#16a34a; --bad:#ef4444; --warn:#f59e0b; --blue:#2563eb;
      --r:20px; --pad:14px;
    }
    *{box-sizing:border-box}
    body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;background:linear-gradient(180deg,#070b14,#05070f);color:var(--text)}
    header{position:sticky;top:0;z-index:50;background:rgba(7,11,20,.72);backdrop-filter: blur(10px);border-bottom:1px solid var(--line)}
    .wrap{max-width:920px;margin:0 auto;padding:14px 14px 18px}
    .top{display:flex;align-items:flex-start;justify-content:space-between;gap:12px}
    h1{font-size:20px;margin:0}
    .sub{color:var(--muted);font-size:12px;margin-top:4px}
    .chip{display:inline-flex;gap:8px;align-items:center;padding:8px 10px;border:1px solid var(--line);border-radius:999px;background:rgba(255,255,255,.03);color:var(--muted);font-size:12px}
    .grid{display:grid;grid-template-columns:1fr;gap:14px;margin-top:14px}
    @media(min-width:900px){.grid{grid-template-columns:1.15fr .85fr}}
    .card{background:linear-gradient(180deg,rgba(255,255,255,.04),rgba(255,255,255,.02));border:1px solid var(--line);border-radius:var(--r);padding:var(--pad);box-shadow:0 10px 30px rgba(0,0,0,.25)}
    .card h2{margin:0 0 8px;font-size:15px}
    .hint{color:var(--muted);font-size:12px}
    .row{display:flex;gap:10px;align-items:center;flex-wrap:wrap}
    input,select,textarea{
      width:100%; background:rgba(255,255,255,.03); color:var(--text);
      border:1px solid var(--line); border-radius:16px; padding:12px 12px;
      outline:none; font-size:14px;
    }
    .btn{
      border:0; border-radius:16px; padding:12px 14px; font-weight:900;
      background:rgba(255,255,255,.06); color:var(--text); cursor:pointer;
      border:1px solid rgba(255,255,255,.08);
      user-select:none;
    }
    .btnOK{background:rgba(22,163,74,.18); border-color:rgba(22,163,74,.35)}
    .btnBAD{background:rgba(239,68,68,.16); border-color:rgba(239,68,68,.35)}
    .btnBLUE{background:rgba(37,99,235,.16); border-color:rgba(37,99,235,.35)}
    .hr{height:1px;background:var(--line);margin:12px 0}
    .list{display:flex;flex-direction:column;gap:10px;margin-top:10px}
    .item{padding:12px;border:1px solid var(--line);border-radius:18px;background:rgba(255,255,255,.03)}
    /* modal opak */
    #modal{position:fixed;inset:0;display:none;z-index:9999;background:rgba(0,0,0,.78);padding:14px}
  </style>
</head>
<body>
<header>
  <div class="wrap">
    <div class="top">
      <div>
        <h1>Stok Kontrol Motoru</h1>
        <div class="sub">Build sistemi aktif — artık patch yok ✅</div>
      </div>
      <div class="chip" id="chipMeta">Local • Hazır</div>
    </div>
  </div>
</header>

<main class="wrap">
  <div class="grid">
    <section class="card">
      <h2>Ürün</h2>
      <div class="row" style="margin-top:10px">
        <input id="inProd" placeholder="Ürün adı (Enter=ekle)" />
        <button class="btn btnOK" id="btnAddProd" type="button">Ekle</button>
      </div>

      <div class="row" style="margin-top:10px">
        <input id="inSearch" placeholder="Ara (sabit)" />
        <button class="btn" id="btnClearSearch" type="button">Temizle</button>
      </div>

      <div class="hr"></div>
      <div class="row" style="justify-content:space-between">
        <div class="hint">Toplam: <b id="pCount">0</b></div>
        <button class="btn btnBLUE" id="btnAddOp" type="button">İşlem Ekle</button>
      </div>

      <div class="list" id="prodList"></div>
    </section>

    <section class="card" id="cardReport">
      <h2>Rapor</h2>
      <div class="hint">Şimdilik iskelet (bir sonraki adımda dolduracağız)</div>
      <div class="hr"></div>
      <div class="item">Durum: Stabil</div>
    </section>
  </div>
</main>

<div id="modal">
  <div class="card" style="max-width:720px;margin:0 auto;max-height:85vh;overflow:auto;background:var(--card)">
    <div class="row" style="justify-content:space-between">
      <b>İşlem Ekle</b>
      <button class="btn" id="btnClose" type="button">Kapat</button>
    </div>
    <div class="hr"></div>

    <div class="row">
      <select id="opProd"></select>
      <button class="btn btnBLUE" id="btnModeAdet" type="button">Adet</button>
      <button class="btn" id="btnModeKoli" type="button">Koli</button>
    </div>

    <div class="row" style="margin-top:10px">
      <input id="opQty" inputmode="numeric" placeholder="Adet (örn 3)" />
    </div>

    <div class="row" style="margin-top:10px;justify-content:flex-end">
      <button class="btn btnOK" id="btnSaveOp" type="button">Kaydet</button>
    </div>
  </div>
</div>

<script>
const KEY="stok_kontrol_db_build_v1";
const $=id=>document.getElementById(id);

function loadDB(){
  let db=null;
  try{ db=JSON.parse(localStorage.getItem(KEY)||"null"); }catch(e){}
  if(!db || typeof db!=="object") db={products:[], ops:[]};
  if(!Array.isArray(db.products)) db.products=[];
  if(!Array.isArray(db.ops)) db.ops=[];
  return db;
}
function saveDB(db){ localStorage.setItem(KEY, JSON.stringify(db)); }
function uid(){ return Date.now().toString(16)+Math.random().toString(16).slice(2); }

function fillProdSelect(){
  const db=loadDB();
  const sel=$("opProd");
  sel.innerHTML="";
  for(const p of db.products){
    const opt=document.createElement("option");
    opt.value=p.id;
    opt.textContent=p.name;
    sel.appendChild(opt);
  }
}

function renderProducts(){
  const db=loadDB();
  const q=($("inSearch").value||"").trim().toLowerCase();
  const list=$("prodList");
  list.innerHTML="";
  $("pCount").textContent=String(db.products.length);

  const arr=db.products.filter(p=>!q || (p.name||"").toLowerCase().includes(q));
  if(!arr.length){
    list.innerHTML=`<div class="item"><div class="hint">Ürün yok / arama boş.</div></div>`;
    fillProdSelect();
    return;
  }
  for(const p of arr){
    const el=document.createElement("div");
    el.className="item";
    el.innerHTML=`<b>${p.name}</b><div class="hint">ID: ${p.id.slice(0,8)}</div>`;
    list.appendChild(el);
  }
  fillProdSelect();
}

function addProduct(){
  const name=($("inProd").value||"").trim();
  if(!name){ alert("Ürün adı yaz."); return; }
  const db=loadDB();
  db.products.push({id:uid(), name, ts:Date.now()});
  saveDB(db);
  $("inProd").value="";
  renderProducts();
}

function openModal(){
  $("modal").style.display="block";
  fillProdSelect();
}
function closeModal(){ $("modal").style.display="none"; }

function addOp(){
  const pid=$("opProd").value;
  const qty=Math.abs(parseInt(($("opQty").value||"").trim(),10))||0;
  if(!pid){ alert("Ürün seç."); return; }
  if(!qty){ alert("Adet gir."); $("opQty").focus(); return; }
  const db=loadDB();
  db.ops.push({id:uid(), pid, qty, ts:Date.now()});
  saveDB(db);
  closeModal();
  alert("Kaydedildi ✅ (build iskelet)");
}

document.addEventListener("DOMContentLoaded", ()=>{
  $("btnAddProd").onclick=addProduct;
  $("inProd").addEventListener("keydown",(e)=>{ if(e.key==="Enter"){ e.preventDefault(); addProduct(); }});
  $("btnAddOp").onclick=openModal;
  $("btnClose").onclick=closeModal;
  $("btnSaveOp").onclick=addOp;
  $("btnClearSearch").onclick=()=>{ $("inSearch").value=""; renderProducts(); };
  $("inSearch").addEventListener("input", renderProducts);
  renderProducts();
});
</script>
</body>
</html>
HTML
fi

# 4) build çıktısı: şimdilik src/app.html aynen index.html oluyor
cp -f src/app.html index.html

# 5) push
git add -A
git commit -m "build: regenerate index.html" || true
git push -u origin main

echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
