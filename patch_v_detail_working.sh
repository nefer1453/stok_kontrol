set -e
FILE="index.html"
cp "$FILE" "$FILE.bak_$(date +%Y%m%d_%H%M%S)"

echo "🔧 Applying B: product detail panel script..."

python3 - << 'PY'
from pathlib import Path
import re

p = Path("index.html")
s = p.read_text(encoding="utf-8")

# 1) CSS panel
if "detail-panel" not in s:
    css = """
<style id="detail-ui">
.detail-panel{position:fixed;left:0;right:0;bottom:0;height:70%;background:#fff;border-top-left-radius:20px;border-top-right-radius:20px;box-shadow:0 -10px 30px rgba(0,0,0,.15);transform:translateY(100%);transition:.3s ease;z-index:9999;padding:20px;overflow:auto;}
.detail-panel.show{transform:translateY(0);}
.hidden{display:none;}
.detail-close{margin-top:12px;padding:12px;background:#ef4444;color:#fff;border:none;border-radius:10px;font-weight:700;width:100%;}
</style>
"""
    s = re.sub(r"</head>", css + "\n</head>", s, flags=re.IGNORECASE)

# 2) detail panel HTML
if "id=\"productDetail\"" not in s:
    panel_html = """
<div id="productDetail" class="detail-panel hidden">
  <h3 id="detailTitle" style="margin:0 0 12px 0;font-size:18px;font-weight:800"></h3>
  <div id="detailOps" style="font-size:14px;line-height:1.5;margin-top:10px;"></div>
  <button id="detailClose" class="detail-close">Kapat</button>
</div>
"""
    s = re.sub(r"</body>", panel_html + "\n</body>", s, flags=re.IGNORECASE)

# 3) script openDetail
if "function openDetail" not in s:
    js = """
<script>
function openDetail(id){
  if(!window.db) return;
  const prod = db.items.find(x=>x.id===id);
  if(!prod) return;

  document.getElementById('detailTitle').textContent = prod.name;

  const ops = (db.ops||[]).filter(o=>o.productId===id);
  const box = document.getElementById('detailOps');
  box.innerHTML='';

  if(!ops.length){
    box.innerHTML = '<div>Bu ürünün hareketi yok.</div>';
  }
  ops.forEach(o=>{
    const row = document.createElement('div');
    row.textContent = `${new Date(o.ts).toLocaleString()} • ${o.type}${o.reason?(' • '+o.reason):''} • ${o.qty||0}`;
    box.appendChild(row);
  });

  const panel=document.getElementById('productDetail');
  panel.classList.remove('hidden');
  setTimeout(()=>panel.classList.add('show'),10);
}

document.getElementById('detailClose')?.addEventListener('click',()=>{
  const panel=document.getElementById('productDetail');
  panel.classList.remove('show');
  setTimeout(()=>panel.classList.add('hidden'),300);
});
</script>
"""
    s = re.sub(r"</body>", js + "\n</body>", s, flags=re.IGNORECASE)

# 4) add onclick to items
# Search repeated pattern and insert attribute
s = re.sub(
    r'<div class="item"',
    r'<div class="item" onclick="openDetail(\'${it.id}\')"',
    s
)

p.write_text(s, encoding="utf-8")
print("OK: detail panel logic injected.")
PY
