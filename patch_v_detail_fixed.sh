set -e

FILE="index.html"
cp "$FILE" "$FILE.bak_$(date +%s)"

echo "🔧 Applying fixed detail panel patch..."

python3 - <<'PY'
from pathlib import Path
import re

p = Path("index.html")
s = p.read_text(encoding="utf-8")

# 1) add CSS for detail panel
if "detail-panel" not in s:
    css = """
<style id="detail-style">
.detail-panel{
  position:fixed;left:0;right:0;bottom:0;height:75%;background:#fff;
  border-top-left-radius:20px;border-top-right-radius:20px;
  box-shadow:0 -10px 30px rgba(0,0,0,.15);
  transform:translateY(100%);transition:.3s ease;z-index:9999;
  padding:16px;overflow-y:auto;
}
.detail-panel.show{transform:translateY(0);}
.hidden{display:none;}
.detail-close{
  margin-top:12px;padding:12px;background:#ef4444;color:#fff;
  border:none;border-radius:10px;font-weight:700;width:100%;
}
</style>
"""
    s = re.sub(r"</head>", css + "\n</head>", s, flags=re.I)

# 2) add detail panel DOM at body end
if "id=\"productDetail\"" not in s:
    panel = """
<div id="productDetail" class="detail-panel hidden">
  <h3 id="detailTitle" style="margin:0 0 12px 0;font-size:18px;font-weight:800"></h3>
  <div id="detailOps" style="font-size:14px;line-height:1.5;"></div>
  <button id="detailClose" class="detail-close">Kapat</button>
</div>
"""
    s = re.sub(r"</body>", panel + "\n</body>", s, flags=re.I)

# 3) add JS block for opening/closing
if "function openDetail" not in s:
    js = """
<script>
function openDetail(pid){
  const prod = db.items.find(x=>x.id===pid);
  if(!prod) return;
  document.getElementById('detailTitle').textContent = prod.name;

  const ops = (db.ops||[]).filter(o=>o.id===pid||o.productId===pid);
  const box = document.getElementById('detailOps');
  box.innerHTML='';

  if(!ops.length){
    box.innerHTML = '<div>Bu ürünün hareketi yok.</div>';
  }
  ops.forEach(o=>{
    const line = document.createElement('div');
    line.textContent = `${new Date(o.ts).toLocaleString()} • ${o.type}${o.reason?(' • '+o.reason):''} • ${o.qty||0}`;
    box.appendChild(line);
  });

  const panel = document.getElementById('productDetail');
  panel.classList.remove('hidden');
  setTimeout(()=>panel.classList.add('show'),10);
}

document.getElementById('detailClose')?.addEventListener('click',()=>{
  const panel=document.getElementById('productDetail');
  panel.classList.remove('show');
  setTimeout(()=>panel.classList.add('hidden'),300);
});

// attach click on cards
document.addEventListener('click', function(e){
  let card = e.target.closest('.item');
  if(card && card.dataset && card.dataset.id){
    openDetail(card.dataset.id);
  }
});
</script>
"""
    s = re.sub(r"</body>", js + "\n</body>", s, flags=re.I)

# 4) ensure data-id is on product cards
# Replace <div class="item"> with data-id
s = re.sub(r'<div class="item"\s*>', r'<div class="item" data-id="${it.id}">', s)

p.write_text(s, encoding="utf-8")
print("OK: detail panel fixed and injected.")
PY
