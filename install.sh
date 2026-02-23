set -e

echo "📦 Stok Kontrol Motoru v0.5 kuruluyor..."
REPO="https://github.com/nefer1453/stok_kontrol.git"
DIR="$HOME/stok_kontrol"

if [ ! -d "$DIR/.git" ]; then
  rm -rf "$DIR"
  git clone "$REPO" "$DIR"
else
  cd "$DIR"
  git pull --rebase
fi

cd "$DIR"

cat > index.html <<'HTML'
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Stok Kontrol Motoru</title>
<style>
body{font-family:system-ui;margin:0;background:#fff;color:#0f172a}
main{padding:18px;max-width:520px;margin:auto}
.row{display:flex;gap:10px;margin:12px 0}
.input{flex:1;padding:14px;font-size:16px;border:1px solid #e5e7eb;border-radius:14px}
.btn{padding:14px 16px;font-size:16px;border:0;border-radius:14px;background:#16a34a;color:#fff;font-weight:800}
.list{margin-top:18px;display:flex;flex-direction:column;gap:10px}
.item{padding:14px;border:1px solid #e5e7eb;border-radius:14px;display:flex;flex-direction:column;gap:8px}
.stock{font-weight:900}
.actions{display:flex;gap:8px}
.small{padding:8px 10px;font-size:13px;border-radius:10px;border:0;cursor:pointer}
.plus{background:#16a34a;color:#fff}
.minus{background:#dc2626;color:#fff}
.hint{color:#64748b;font-size:12px}
</style>
</head>
<body>
<main>
<h2>Stok Kontrol Motoru</h2>
<div class="hint">v0.5 — event tabanlı stok</div>

<div class="row">
  <input id="prodName" class="input" placeholder="Ürün adı">
  <button id="btnAdd" class="btn">Ekle</button>
</div>

<div id="list" class="list"></div>
</main>

<script>
const KEY="stok_kontrol_v1";
const $=id=>document.getElementById(id);
let db=JSON.parse(localStorage.getItem(KEY)||"null")||{products:[],operations:[]};

function save(){localStorage.setItem(KEY,JSON.stringify(db))}

function stockOf(productId){
  return db.operations
    .filter(o=>o.productId===productId)
    .reduce((sum,o)=>sum + (o.qty * o.direction),0);
}

function render(){
  const box=$("list");
  box.innerHTML="";
  if(!db.products.length){
    box.innerHTML="<div class='item'>Henüz ürün yok.</div>";
    return;
  }

  for(const p of db.products){
    const el=document.createElement("div");
    el.className="item";
    const stock=stockOf(p.id);

    el.innerHTML=`
      <div><b>${p.name}</b></div>
      <div class="stock">Stok: ${stock}</div>
      <div class="actions">
        <button class="small plus">+10</button>
        <button class="small minus">-10</button>
      </div>
    `;

    const [plusBtn,minusBtn]=el.querySelectorAll("button");

    plusBtn.onclick=()=>{
      db.operations.push({
        id:Date.now().toString(16),
        productId:p.id,
        type:"dağılım",
        direction:1,
        qty:10,
        ts:Date.now()
      });
      save();
      render();
    };

    minusBtn.onclick=()=>{
      db.operations.push({
        id:Date.now().toString(16),
        productId:p.id,
        type:"satış",
        direction:-1,
        qty:10,
        ts:Date.now()
      });
      save();
      render();
    };

    box.appendChild(el);
  }
}

function add(){
  const name=($("prodName").value||"").trim();
  if(!name){ alert("Ürün adı yaz."); $("prodName").focus(); return; }

  db.products.push({
    id:Date.now().toString(16),
    name
  });

  save();
  $("prodName").value="";
  $("prodName").focus();
  render();
}

$("btnAdd").onclick=add;
$("prodName").addEventListener("keydown",(e)=>{
  if(e.key==="Enter"){
    e.preventDefault();
    add();
  }
});

render();
$("prodName").focus();
</script>
</body>
</html>
HTML

git add index.html
git commit -m "v0.5 event based stock model" || true
git push -u origin main

echo
echo "👉 Link:"
echo "https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
