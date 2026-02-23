set -e

f="index.html"
[ -f "$f" ] || { echo "index.html yok"; exit 1; }

# 1) Tüm <button ...> etiketlerine type="button" ekle (yoksa)
python - <<'PY'
from pathlib import Path
import re
p=Path("index.html")
s=p.read_text(encoding="utf-8", errors="ignore")

# button taglerinde type yoksa ekle
def add_type(m):
    tag=m.group(0)
    if re.search(r'\btype\s*=', tag, re.I):
        return tag
    return tag[:-1] + ' type="button">'

s2=re.sub(r'<button\b[^>]*>', add_type, s, flags=re.I)

# 2) form varsa: form submit'i öldür (onsubmit="return false")
# (form etiketinde onsubmit yoksa ekler)
def kill_submit(m):
    tag=m.group(0)
    if re.search(r'\bonsubmit\s*=', tag, re.I):
        return tag
    return tag[:-1] + ' onsubmit="return false;">'

s3=re.sub(r'<form\b[^>]*>', kill_submit, s2, flags=re.I)

# 3) JS tarafına ekstra güvenlik: submit eventini globalde engelle
marker="/* SUBMIT_GUARD_V1 */"
if marker not in s3:
    guard = """
<script>
/* SUBMIT_GUARD_V1 */
(function(){
  // Herhangi bir form submit'i asla sayfayı yenilemesin
  window.addEventListener("submit", function(e){
    e.preventDefault();
    e.stopPropagation();
    return false;
  }, true);
})();
</script>
"""
    # </body> önüne ekle
    if "</body>" in s3:
        s3 = s3.replace("</body>", guard + "\n</body>")
    else:
        s3 += guard

p.write_text(s3, encoding="utf-8")
print("OK: patch_fix_submit uygulandı")
PY

git add index.html
git commit -m "Fix: prevent submit refresh (button type + submit guard)" || true
git push

echo
echo "✅ Bitti. Test linki (cache kırmak için):"
echo "https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
