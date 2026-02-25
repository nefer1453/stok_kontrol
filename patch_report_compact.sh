set -e

ts=$(date +%Y%m%d_%H%M%S)
cp -f index.html "index.html.bak.$ts" 2>/dev/null || true

python - <<'PY'
from pathlib import Path
import re

p=Path("index.html")
s=p.read_text(encoding="utf-8")

# 1) Report ekranını (yönetici bakışı) tek kartta toplamak için küçük CSS ekleyelim
if "/* REPORT_COMPACT_V1 */" not in s:
    s = s.replace("</style>", """
/* REPORT_COMPACT_V1 */
.reportGrid{display:grid;gap:10px}
@media (min-width:520px){ .reportGrid{grid-template-columns:1fr 1fr} }
.reportKpi{display:flex;gap:8px;flex-wrap:wrap}
.reportKpi .pill{font-weight:900}
.reportSectionTitle{font-weight:950;margin:6px 0 2px 0}
</style>""")

# 2) HTML tarafında "Rapor" alanını bulup (varsa) kompakt bir wrapper ekle.
# Not: Projede rapor alanı farklı isimde olabilir. O yüzden "id=report" / "Rapor" etiketlerini yakalıyoruz.
# En güvenlisi: var olan rapor container'ının içeriğini bozmadan içine wrapper koymak.
patterns = [
    r'(<div[^>]*id="report"[^>]*>)(.*?)</div>\s*<!--\s*/report\s*-->',
    r'(<section[^>]*id="report"[^>]*>)(.*?)</section>'
]

done=False
for pat in patterns:
    m=re.search(pat, s, flags=re.S|re.I)
    if not m:
        continue
    head=m.group(1)
    body=m.group(2)

    # Zaten kompakt yapılmışsa dokunma
    if "reportGrid" in body and "REPORT_COMPACT_V1" in s:
        done=True
        break

    new_body = f"""
<div class="reportSectionTitle">Yönetici Özeti</div>
<div class="reportKpi" id="reportKpi"></div>
<div class="hr"></div>
<div class="reportGrid">
  <div class="card" style="margin:0">
    <div class="reportSectionTitle">Bugün / 7g / 30g</div>
    <div id="reportWindow"></div>
  </div>
  <div class="card" style="margin:0">
    <div class="reportSectionTitle">En Çok Ürünler</div>
    <div id="reportTop"></div>
  </div>
</div>
<div class="hr"></div>
<div class="reportGrid">
  <div class="card" style="margin:0">
    <div class="reportSectionTitle">Tür Dağılımı</div>
    <div id="reportTypes"></div>
  </div>
  <div class="card" style="margin:0">
    <div class="reportSectionTitle">Notlar / Akıl</div>
    <div id="reportBrain"></div>
  </div>
</div>
"""
    # body içindeki eski elemanları aynen bırakıp sadece bir "kompakt hedef alan" oluşturuyoruz.
    # JS tarafı bu id'lere yazabiliyorsa zaten otomatik dolacak.
    # Yazamıyorsa da en azından UI bozulmaz.
    body2 = new_body + "\n" + body

    s = s[:m.start()] + head + body2 + s[m.end():]
    done=True
    break

if not done:
    # Rapor alanı bulunamadıysa güvenli şekilde hiç dokunma.
    print("UYARI: report alanı bulunamadı. Dosyaya dokunulmadı.")
else:
    p.write_text(s, encoding="utf-8")
    print("OK: Rapor kompakt yerleşime alındı (REPORT_COMPACT_V1).")
PY

git add index.html
git commit -m "UI: report compact (tek ekrana toplama)" || true
git push -u origin main

echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
