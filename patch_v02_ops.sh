set -e
cd ~/stok_kontrol

echo "v0.2 kuruluyor..."

cat > index.html <<'HTML'
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Stok Kontrol Motoru</title>
<style>
body{font-family:system-ui;margin:0;background:#fff}
main{padding:18px;max-width:520px;margin:auto}
.row{display:flex;gap:10px;margin:10px 0}
.input{flex:1;padding:14px;font-size:16px;border:1px solid #ddd;border-radius:12px}
.btn{padding:14px;border-radius:12px;border:0;font-weight:700;cursor:pointer}
.green{background:#16a34a;color:#fff}
.red{background:#dc2626;color:#fff}
.gray{background:#e5e7eb}
.list{display:flex;flex-direction:column;gap:10px;margin-top:20px}
.item{padding:14px;border:1px solid #ddd;border-radius:14px}
.small{font-size:12px;color:#64748b}
.modal{
 position:fixed;left:0;right:0;bottom:0;background:#fff;
 border-top-left-radius:20px;border-top-right-radius:20px;
 padding:18px;box-shadow:0 -4px 20px rgba(0,0,0,.1);
 display:none
}
</style>
</head>
<body>
<main>
<h2>Stok Kontrol</h2>

<div class="row">
  <input id="prodName" class="input" placeholder="Ürün adı">
  <button id="btnAdd" class="btn green">Ekle</button>
</div>

<div id="list" class="list"></div>
</main>

<div id="modal" class="modal">
  <div class="row">
    <button id="plusBtn" class="btn green">Artış</button>
    <button id="minusBtn" class="btn red">Azalış</button>
  </div>

  <div class="row">
    <select id="type" class="input">
      <option value="">Tip seç</option>
      <option value="siparis">Sipariş</option>
      <option value="dagitim">Dağılım</option>
      <option value="satis">Satış</option>
      <option value="skt">SKT</option>
      <option value="iade">İade</option>
    </select>
  </div>

  <div class="row">
    <input id="qty" type="number" class="input" placeholder="Adet">
    <button id="saveOp" class="btn gray">Kaydet</button>
  </div>
</div>

<script>
const KEY="stok_kontrol_v2";
const $=id=>document.getElementById(id);
let db=JSON.parse(localStorage.getItem(KEY)||"null")||{items:[],ops:[]};
let activeId=null;
let activeDir=null;

function save(){localStorage.setItem(KEY,JSON.stringify(db))}

function stockOf(id){
  let total=0;
  for(const op of db.ops){
    if(op.productId===id){
      total += op.dir==="+" ? op.qty : -op.qty;
    }
  }
  return total;
}

function render(){
  const box=$("list");
  box.innerHTML="";
  for(const it of db.items){
    const el=document.createElement("div");
    el.className="item";
    el.innerHTML=
      "<b>"+it.name+"</b><br>"+
      "<span class='small'>Stok: "+stockOf(it.id)+"</span>";
    el.onclick=()=>{
      activeId=it.id;
      $("modal").style.display="block";
    };
    box.appendChild(el);
  }
}

function add(){
  const name=($("prodName").value||"").trim();
  if(!name){alert("Ürün adı yaz.");return;}
  db.items.push({id:Date.now().toString(16),name});
  save();
  $("prodName").value="";
  render();
}

$("btnAdd").onclick=add;

$("plusBtn").onclick=()=>activeDir="+";
$("minusBtn").onclick=()=>activeDir="-";

$("saveOp").onclick=()=>{
  const type=$("type").value;
  const qty=parseInt($("qty").value||0);
  if(!activeDir||!type||!qty){alert("Eksik alan");return;}
  db.ops.push({
    productId:activeId,
    dir:activeDir,
    type,
    qty,
    ts:Date.now()
  });
  save();
  $("modal").style.display="none";
  $("qty").value="";
  $("type").value="";
  activeDir=null;
  render();
};

render();
</script>
</body>
</html>
HTML

git add index.html
git commit -m "v0.2 ops engine"
git push

echo "Bitti"
echo "Link:"
echo "https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
