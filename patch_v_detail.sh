set -e

FILE="index.html"

cp "$FILE" "$FILE.bak_$(date +%s)"

echo "🔧 Detail panel ekleniyor..."

python3 - << 'PY'
from pathlib import Path

p = Path("index.html")
s = p.read_text(encoding="utf-8")

if "detail-panel" in s:
    print("Zaten ekli. Çıkıyorum.")
    raise SystemExit

# CSS ekle
css_block = """
<style id="detailStyle">
.detail-panel{
  position:fixed;
  left:0;
  right:0;
  bottom:0;
  height:75%;
  background:#fff;
  border-top-left-radius:20px;
  border-top-right-radius:20px;
  box-shadow:0 -10px 30px rgba(0,0,0,.15);
  transform:translateY(100%);
  transition:.3s ease;
  z-index:9999;
  padding:20px;
  overflow:auto;
}
.detail-panel.show{
  transform:translateY(0);
}
.hidden{display:none;}
.detail-close{
  margin-top:20px;
  padding:12px;
  background:#ef4444;
  color:#fff;
  border:none;
  border-radius:12px;
  width:100%;
  font-weight:700;
}
</style>
"""

if "</head>" in s:
    s = s.replace("</head>", css_block + "\n</head>")

# HTML panel ekle
panel_html = """
<div id="productDetail" class="detail-panel hidden">
  <h3 id="detailTitle"></h3>
  <div id="detailOps"></div>
  <button id="detailClose" class="detail-close">Kapat</button>
</div>
"""

s = s.replace("</body>", panel_html + "\n</body>")

# JS ekle
js_block = """
<script>
function openDetail(productId){
  if(!window.db) return;
  const product=db.products.find(p=>p.id===productId);
  if(!product) return;

  const ops=db.ops.filter(o=>o.productId===productId);

  document.getElementById("detailTitle").textContent=product.name;

  const box=document.getElementById("detailOps");
  box.innerHTML="";

  if(!ops.length){
    box.innerHTML="<div>Bu ürüne ait işlem yok.</div>";
  }

  ops.forEach(o=>{
    const row=document.createElement("div");
    row.style.padding="8px 0";
    row.textContent=
      new Date(o.ts).toLocaleString() +
      " - " + o.type +
      " (" + o.qty + ")";
    box.appendChild(row);
  });

  const panel=document.getElementById("productDetail");
  panel.classList.remove("hidden");
  setTimeout(()=>panel.classList.add("show"),10);
}

document.addEventListener("click",function(e){
  if(e.target.dataset && e.target.dataset.pid){
    openDetail(e.target.dataset.pid);
  }
});

document.getElementById("detailClose")?.addEventListener("click",function(){
  const panel=document.getElementById("productDetail");
  panel.classList.remove("show");
  setTimeout(()=>panel.classList.add("hidden"),300);
});
</script>
"""

s = s.replace("</body>", js_block + "\n</body>")

# Ürün kartlarına data-pid ekle
s = s.replace(
    "class=\"product-card\"",
    "class=\"product-card\" data-pid=\"${p.id}\""
)

p.write_text(s, encoding="utf-8")
print("OK")
PY

echo "✅ Patch hazır."

