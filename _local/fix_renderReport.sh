set -e
cd "$(dirname "$0")"

ts="$(date +%Y%m%d_%H%M%S)"
cp -f index.html "index.html.bak.RENDERREPORT.$ts"

python - <<'PY'
from pathlib import Path
p=Path("index.html")
s=p.read_text(encoding="utf-8")

# renderReport("today");  -> reportToday();
s2 = s.replace('renderReport("today");', 'reportToday();')
s2 = s2.replace("renderReport('today');", "reportToday();")

# ekstra güvenlik: başka renderReport(...) kaldıysa onları da reportToday(); yap
# (bizde renderReport diye fonksiyon yok, kalması risk)
import re
s2 = re.sub(r'^\s*renderReport\([^)]*\)\s*;\s*$', '  reportToday();', s2, flags=re.M)

p.write_text(s2, encoding="utf-8")
print("OK: patched renderReport -> reportToday")
PY

# kontrol: renderReport kaldı mı?
if grep -n "renderReport" index.html; then
  echo "HATA: renderReport hala var (yukarıdaki satırlara bak)."
  exit 1
fi

git add index.html
git commit -m "fix: remove undefined renderReport calls" || true
git push -u origin main

echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
