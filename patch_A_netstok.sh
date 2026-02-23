set -e
cd "$(dirname "$0")"

ts="$(date +%Y%m%d_%H%M%S)"
cp -f index.html "index.html.bak.$ts"

python - <<'PY'
from pathlib import Path
import re

p = Path("index.html")
s = p.read_text(encoding="utf-8")

# --- 1) CSS: Net stok görünümünü büyüt/güçlendir (UI-only) ---
CSS_MARK = "/* UI_NET_STOK_V1 */"
if CSS_MARK not in s:
    # style bloğu varsa içine ekle
    m = re.search(r"</style>", s, flags=re.I)
    if not m:
        raise SystemExit("HATA: </style> bulunamadı. index.html farklı olabilir.")
    css = f"""
    {CSS_MARK}
    /* Net stok: büyük ve vurucu */
    .pill.netstok{{
      font-weight: 950 !important;
      font-size: 18px !important;
      line-height: 1 !important;
      padding: 10px 14px !important;
      border-radius: 999px !important;
      transform: translateZ(0);
    }}
    /* Kart içindeki net stok daha da öne çıksın */
    .netstokWrap{{ display:flex; align-items:center; gap:10px; flex-wrap:wrap; }}
    .netstokLabel{{ font-size:12px; color:#64748b; font-weight:800; letter-spacing:.2px; }}
    """
    s = s[:m.start()] + css + "\n" + s[m.start():]

# --- 2) HTML/JS: Net stok pill'i yakalayıp class ekle ---
# Biz burada risk almadan yaklaşacağız:
# - Zaten render edilen "Net" / "NET" / "Net Stok" gibi pill'leri 'pill netstok' yapacağız.
# - Hiç bulamazsa yine de app çalışır; sadece UI değişmez.

def add_net_class(text):
    # <span class="pill">NET: 12</span> gibi şeyleri dönüştürür
    text = re.sub(r'class="pill"\s*>\s*(NET|Net|Net\s*Stok)\b', r'class="pill netstok"> \1', text)
    text = re.sub(r'class="pill"\s*>\s*(NET\s*STOK|NET\s*Stok)\b', r'class="pill netstok"> \1', text)
    return text

s2 = add_net_class(s)

# Net etiketi hiç yoksa: yine de ürün kartında "stok" yazan pill'lerden birini büyütmeye kalkışmayalım.
# Çünkü yanlış şeyi büyütür. Bu patch sadece NET etiketini hedefliyor.
s = s2

# --- 3) Eğer net stok label yoksa (bazı sürümlerde), küçük bir "post-process" JS ekle ---
# Bu JS, sayfa render sonrası DOM'da "Net" kelimesi içeren pill'lere netstok class'ı takar.
JS_MARK = "/* UI_NET_STOK_DOM_PATCH_V1 */"
if JS_MARK not in s:
    # En sona, </body> öncesi ufak script enjekte edelim.
    ins = re.search(r"</body>", s, flags=re.I)
    if not ins:
        raise SystemExit("HATA: </body> bulunamadı.")
    js = f"""
<script>
{JS_MARK}
(function(){{
  function apply(){{
    try{{
      const pills = document.querySelectorAll('.pill');
      for(const el of pills){{
        const t = (el.textContent||"").trim().toLowerCase();
        if(t.startsWith("net") || t.startsWith("net stok") || t.startsWith("net:") || t.startsWith("netstok")){{
          el.classList.add("netstok");
        }}
      }}
    }}catch(_e){{}}
  }}
  // İlk yükleme + ufak gecikme (render sonra)
  apply();
  setTimeout(apply, 120);
  setTimeout(apply, 500);
}})();
</script>
"""
    s = s[:ins.start()] + js + "\n" + s[ins.start():]

p.write_text(s, encoding="utf-8")
print("OK: A) Net stok pill'i büyütüldü (UI-only). Yedek: index.html.bak.*")
PY

git add index.html
git commit -m "A) UI: Net stok kartını güçlendir" || true
git push -u origin main

echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
