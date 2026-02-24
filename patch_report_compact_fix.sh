set -e
cd "$(dirname "$0")"

ts=$(date +%Y%m%d_%H%M%S)
cp -f index.html "index.html.bak_report_compact_$ts"

python - <<'PY'
from pathlib import Path

p = Path("index.html")
s = p.read_text(encoding="utf-8")

# 1) CSS ekle (varsa tekrar ekleme)
if "/* REPORT_COMPACT_V1 */" not in s:
    css = r"""
/* REPORT_COMPACT_V1 */
:root{ --repMaxH: 220px; }
.miniScroll{
  max-height: var(--repMaxH);
  overflow:auto;
  -webkit-overflow-scrolling: touch;
}
.repCompactNote{ font-size:12px; color:#64748b; margin-top:6px; }
@media (max-height: 740px){
  :root{ --repMaxH: 180px; }
}
"""
    if "</style>" in s:
        s = s.replace("</style>", css + "\n</style>", 1)
    else:
        # style tag yoksa head içine basit style ekle
        s = s.replace("</head>", f"<style>{css}</style>\n</head>", 1)

# 2) JS ekle (rapor alanındaki listeleri kaydırmalı yap)
if "/* REPORT_COMPACT_V1_JS */" not in s:
    js = r"""
/* REPORT_COMPACT_V1_JS */
(function(){
  function apply(){
    // Rapor içinde olma ihtimali yüksek listeleri yakala:
    document.querySelectorAll(
      '#report .list, #screenReport .list, #viewReport .list, .report .list, [id^="rep"] .list, [id^="repList"], [id^="rep"]'
    ).forEach(el=>{
      // sadece gerçekten uzun olabilecek bloklara uygula
      if(el && el.classList && !el.classList.contains("miniScroll")){
        // İçinde çok item varsa veya zaten "list" ise
        const isListy = el.classList.contains("list") || el.querySelector(".item") || el.children.length >= 6;
        if(isListy) el.classList.add("miniScroll");
      }
    });

    // Rapor başına küçük not (varsa)
    const rep = document.querySelector("#report, #screenReport, #viewReport, .report");
    if(rep && !rep.querySelector(".repCompactNote")){
      const note = document.createElement("div");
      note.className = "repCompactNote";
      note.textContent = "Rapor: uzun listeler bu kutunun içinde kayar (tek ekranda kalır).";
      rep.prepend(note);
    }
  }

  window.addEventListener("load", ()=>setTimeout(apply, 200));
  document.addEventListener("click", ()=>setTimeout(apply, 50));
  document.addEventListener("input", ()=>setTimeout(apply, 80));

  // Eğer uygulamada render/yenileme fonksiyonu varsa yakalamaya çalış (zararsız)
  try{
    const oldRender = window.renderAll || window.render || null;
    if(typeof oldRender === "function"){
      const name = window.renderAll ? "renderAll" : "render";
      window[name] = function(){
        const r = oldRender.apply(this, arguments);
        setTimeout(apply, 0);
        return r;
      };
    }
  }catch(_){}
})();
"""
    if "</script>" in s:
        s = s.replace("</script>", js + "\n</script>", 1)
    else:
        s = s.replace("</body>", f"<script>{js}</script>\n</body>", 1)

p.write_text(s, encoding="utf-8")
print("OK: REPORT_COMPACT_V1 uygulandı (rapor listeleri kaydırmalı).")
PY

echo "OK: patch bitti."
