set -e

cd "$(dirname "$0")"
ts=$(date +%Y%m%d_%H%M%S)
cp -f index.html "index.html.bak.$ts"

python - <<'PY'
from pathlib import Path

p = Path("index.html")
s = p.read_text(encoding="utf-8")

# 1) CSS ekle (yoksa)
css_mark = "/* REPORT_COMPACT_V1 */"
if css_mark not in s:
    s = s.replace("</head>", f"""
<style>
{css_mark}
#reportDetailsV1 {{
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 10px 12px;
  margin-top: 12px;
  background: #fff;
}}
#reportDetailsV1 > summary {{
  list-style: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  font-weight: 900;
  user-select: none;
}}
#reportDetailsV1 > summary::-webkit-details-marker {{ display:none; }}
#reportDetailsV1 .hint {{ color:#64748b; font-size:12px; font-weight:600; }}
#reportDetailsV1[open] {{ box-shadow: 0 8px 20px rgba(0,0,0,.06); }}
#reportDetailsV1 .detailsBody {{
  margin-top: 10px;
  max-height: 52vh;          /* ekranı uzatmasın */
  overflow: auto;
  -webkit-overflow-scrolling: touch;
  padding-right: 4px;
}}
</style>
</head>""")

# 2) JS ekle (yoksa) — rapor ekranındaki kartları "Detaylar" içine toplar
js_mark = "/* REPORT_COMPACT_JS_V1 */"
if js_mark not in s:
    insert = "</body>"
    if insert not in s:
        raise SystemExit("HATA: </body> yok. index.html beklenenden farklı.")
    s = s.replace(insert, f"""
<script>
{js_mark}
(function(){
  function txt(el){ return (el && (el.textContent||"").trim()) || ""; }

  function findReportRoot(){
    // En olası id'ler / data-screen
    let r = document.querySelector('[data-screen="report"], #screenReport, #report, #rapor');
    if(r) return r;

    // Başlık metninden yakala
    const heads = Array.from(document.querySelectorAll("h1,h2,h3,div,strong"));
    const hit = heads.find(x => /rapor/i.test(txt(x)));
    if(!hit) return null;

    // En yakın "screen/page/main" gibi bir kapsayıcıyı seç
    return hit.closest("[data-screen], .screen, main, body") || null;
  }

  function compactReport(){
    const root = findReportRoot();
    if(!root) return;

    // Kartları topla
    const cards = Array.from(root.querySelectorAll(".card"));
    if(cards.length < 3) return; // zaten kısa

    // Zaten uygulanmış mı?
    if(root.querySelector("#reportDetailsV1")) return;

    // İlk 1-2 kart kalsın (özet gibi). Gerisini detaylara al.
    const keep = cards.slice(0, 2);
    const move = cards.slice(2);

    const details = document.createElement("details");
    details.id = "reportDetailsV1";
    details.open = false;

    const summary = document.createElement("summary");
    summary.innerHTML = '<span>Detaylar</span><span class="hint">Aç / Kapat</span>';
    details.appendChild(summary);

    const body = document.createElement("div");
    body.className = "detailsBody";
    details.appendChild(body);

    // Detay kartlarını taşı
    for(const c of move){
      body.appendChild(c);
    }

    // Detayları, özetin hemen altına yerleştir
    const after = keep[keep.length-1];
    after.insertAdjacentElement("afterend", details);
  }

  // İlk yükleme + ekran değişimi ihtimaline karşı birkaç kez dene
  function run(){
    try{ compactReport(); }catch(_){}
  }
  document.addEventListener("DOMContentLoaded", run);
  setTimeout(run, 200);
  setTimeout(run, 700);
  setTimeout(run, 1400);

  // Basit mutation watcher: UI ekran değiştiriyorsa yakalasın
  const mo = new MutationObserver(()=>run());
  mo.observe(document.documentElement, {subtree:true, childList:true});
})();
</script>
</body>""")

p.write_text(s, encoding="utf-8")
print("OK: Rapor kompakt modu eklendi (Detaylar kapağı). Yedek:", f"index.html.bak.{__import__('time').strftime('%Y%m%d_%H%M%S')}")
PY

git add index.html
git commit -m "UI: rapor tek ekrana (Detaylar kapağı)" || true
git push -u origin main

echo
echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
