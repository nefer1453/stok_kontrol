set -e
f="index.html"
[ -f "$f" ] || { echo "index.html yok"; exit 1; }

# 0) Yedek al
cp -f "$f" "$f.bak_before_focus_$(date +%Y%m%d_%H%M%S)"

python - <<'PY'
from pathlib import Path
import re
p=Path("index.html")
s=p.read_text(encoding="utf-8", errors="ignore")

marker="/* FOCUS_GUARD_V1 */"
if marker not in s:
    # 1) focus() varsa: preventScroll ile ve güvenli fonksiyonla değiştir
    # önce helper ekle
    helper = """
<script>
/* FOCUS_GUARD_V1 */
function safeFocus(el){
  try{
    if(!el) return;
    // klavye/viewport zıplamasını azaltır
    el.focus({preventScroll:true});
  }catch(e){
    try{ el && el.focus(); }catch(_){}
  }
}
// Global: otomatik focus'u varsayılan kapalı tut
let AUTO_FOCUS = false;
</script>
"""
    if "</head>" in s:
        s = s.replace("</head>", helper + "\n</head>")
    else:
        s = helper + s

# 2) $(...).focus() -> safeFocus($(...)) olacak şekilde dönüştür
# (basit dönüşüm; bozma riskini düşük tutmak için sadece ".focus()" çağrılarını sarar)
s2 = re.sub(r'(\$\("[^"]+"\)|\$\([^)]+\)|document\.getElementById\([^)]+\))\.focus\(\s*\)\s*;',
            r'safeFocus(\1);', s)

# 3) sayfa açılışındaki focus'u koru ama AUTO_FOCUS kontrolüne bağla:
# safeFocus(...) satırlarını AUTO_FOCUS ile koşullandır
# (bütün safeFocus çağrılarını değil, sadece "render(); safeFocus(...)" gibi tipik yerleri yakalamaya çalışır)
s3 = s2.replace("safeFocus($(", "if(AUTO_FOCUS) safeFocus($(")

p.write_text(s3, encoding="utf-8")
print("OK: focus azaltma patch uygulandı")
PY

git add index.html
git commit -m "Reduce flicker: disable aggressive autofocus" || true
git push

echo
echo "✅ Test linki (cache kır):"
echo "https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
echo
echo "🧯 Geri almak istersen (tek komut):"
echo "cd ~/stok_kontrol && git revert --no-edit HEAD && git push"
