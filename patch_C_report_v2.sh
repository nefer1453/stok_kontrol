set -e

cd "$(dirname "$0")"
ts=$(date +%Y%m%d_%H%M%S)

cp -f index.html "index.html.bak.$ts"

python - <<'PY'
from pathlib import Path
import re

p = Path("index.html")
s = p.read_text(encoding="utf-8")

# --- 0) Zaten eklendiyse çık
if "/* REPORT_MANAGER_V2 */" in s:
    print("Zaten REPORT_MANAGER_V2 var. Çıkıyorum.")
    raise SystemExit(0)

# --- 1) CSS ekle (rapor kartları + KPI görünümü)
css_block = r"""
/* REPORT_MANAGER_V2 */
.reportGrid{
  display:grid;
  grid-template-columns:repeat(2,minmax(0,1fr));
  gap:10px;
}
@media (min-width:720px){
  .reportGrid{grid-template-columns:repeat(3,minmax(0,1fr));}
}
.kpi{
  border:1px solid rgba(148,163,184,.35);
  border-radius:16px;
  padding:12px;
  background:rgba(255,255,255,.04);
}
.kpi .k{font-size:12px; opacity:.85}
.kpi .v{font-size:22px; font-weight:900; margin-top:6px}
.kpi .s{font-size:12px; opacity:.85; margin-top:6px; line-height:1.25}
.reportTitle{font-size:18px; font-weight:950; margin:0 0 6px}
.reportSub{font-size:12px; opacity:.85; margin:0 0 12px; line-height:1.35}
.reportSectionTitle{font-weight:900; margin:14px 0 8px}
.reportList{display:flex; flex-direction:column; gap:10px}
.reportItem{border:1px solid rgba(148,163,184,.25); border-radius:14px; padding:12px}
.reportItem .t{font-weight:900}
.reportItem .m{font-size:12px; opacity:.85; margin-top:6px; line-height:1.25}
.reportBadgeRow{display:flex; gap:8px; flex-wrap:wrap; margin-top:8px}
.reportBadge{font-size:12px; padding:6px 10px; border-radius:999px; border:1px solid rgba(148,163,184,.25); opacity:.95}
.reportWarn{border-color: rgba(239,68,68,.45)}
"""

# style kapanmadan önce ekle
if "</style>" in s:
    s = s.replace("</style>", css_block + "\n</style>", 1)
else:
    # style yoksa head içine ekle
    s = re.sub(r"</head>", f"<style>{css_block}\n</style>\n</head>", s, count=1, flags=re.I)

# --- 2) Rapor alanı için HTML container ekle (varsa dokunma)
# Hedef: rapor ekranında (rapor sekmesi/modalı/alanı) bir #mgrReportV2 div'i olsun.
# Bulamazsak main'in sonuna gizli bir bölüm ekleriz (bozmayacak şekilde).
if 'id="mgrReportV2"' not in s:
    # Önce "Rapor" kelimesi geçen bir card/section yakınında eklemeye çalış
    # Çok agresif değil: "Rapor" başlığından sonra bir kere yerleştir.
    pat = r'(<div[^>]*>\s*Rapor\s*</div>)'
    if re.search(pat, s, flags=re.I):
        s = re.sub(pat, r'\1\n<div id="mgrReportV2"></div>', s, count=1, flags=re.I)
    else:
        # fallback: </main> öncesi ekle
        s = s.replace("</main>", '\n<div id="mgrReportV2" style="display:none"></div>\n</main>', 1)

# --- 3) JS tarafı: render rapora "yönetici sunumu" üret (var olan raporu bozma)
# Strateji:
# - Sayfada window.__SK_REPORT_V2__ diye global fonksiyon ekle.
# - Bu fonksiyon, db ve ops’tan özet çıkarır ve mümkünse rapor alanına basar.
# - Eğer projede "Rapor" ekranına girince renderReport() gibi bir fonksiyon çağrılıyorsa,
#   onu bulup sonuna __SK_REPORT_V2__() eklemeye çalışırız.
js_inject = r"""
/* REPORT_MANAGER_V2 */
(function(){
  function safeNum(x){ x=Number(x); return Number.isFinite(x)?x:0; }
  function toTRDate(ts){ try{return new Date(ts).toLocaleString("tr-TR")}catch(_){return ""} }
  function esc(s){ return String(s??"").replace(/[&<>"']/g,m=>({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[m])); }

  function getDB(){
    // Bu projede DB anahtarı farklı olabilir; global KEY varsa yakalarız.
    // En risksiz: localStorage içinde "stok_kontrol" ile başlayan ilk key'i bul.
    try{
      const keys = Object.keys(localStorage||{});
      let k = keys.find(k=>k==="stok_kontrol_v1") || keys.find(k=>k.startsWith("stok_kontrol_")) || keys.find(k=>k.includes("stok_kontrol"));
      if(!k) return {key:null, db:{products:[], ops:[]}};
      const raw = localStorage.getItem(k);
      const db = JSON.parse(raw||"null") || {};
      return {key:k, db};
    }catch(_){
      return {key:null, db:{products:[], ops:[]}};
    }
  }

  function normalize(db){
    // farklı sürümler için tolerans:
    const products = db.products || db.items || [];
    const ops = db.ops || db.operations || [];
    return {products:Array.isArray(products)?products:[], ops:Array.isArray(ops)?ops:[]};
  }

  function summarize({products, ops}){
    const now = Date.now();
    const day = 24*60*60*1000;

    const byRange = (ms)=> ops.filter(o => safeNum(o.ts||o.time||0) >= now - ms);

    const last1d = byRange(1*day);
    const last7d = byRange(7*day);
    const last30d = byRange(30*day);

    const countTypes = (arr)=>{
      const m = {};
      for(const o of arr){
        const t = String(o.type || o.kind || "Bilinmiyor");
        m[t] = (m[t]||0)+1;
      }
      return m;
    };

    const types30 = countTypes(last30d);

    // Top ürünler (30g) — hareket sayısına göre
    const prodMov = {};
    for(const o of last30d){
      const pid = o.pid || o.productId || o.itemId || "";
      const name = String(o.pname || o.name || o.productName || "");
      const key = pid || name || "Bilinmeyen";
      prodMov[key] = prodMov[key] || {name: name||key, n:0};
      prodMov[key].n += 1;
    }
    const topProducts = Object.values(prodMov).sort((a,b)=>b.n-a.n).slice(0,8);

    // “Uyarılar”: negatif stok görünen ürün, aşırı iade/SKT vs.
    // (stok hesabı projede farklı olabilir; sadece kaba kontrol)
    const warns = [];
    for(const p of products){
      const stock = safeNum(p.stock ?? p.qty ?? p.net ?? 0);
      if(stock < 0) warns.push(`Negatif stok: ${p.name||p.title||"Ürün"} (${stock})`);
    }
    // SKT / iade sayısı (30g)
    const sktCount = safeNum(types30["SKT"]);
    const iadeCount = safeNum(types30["İade"] || types30["IADE"] || types30["iade"]);
    if(sktCount >= 10) warns.push(`SKT işlemi yüksek (30g): ${sktCount}`);
    if(iadeCount >= 10) warns.push(`İade işlemi yüksek (30g): ${iadeCount}`);

    return {
      meta: { nowTR: new Date().toLocaleString("tr-TR"), prodCount: products.length, opsCount: ops.length },
      kpi: {
        ops1d: last1d.length,
        ops7d: last7d.length,
        ops30d: last30d.length,
        types30,
        topProducts,
        warns
      },
      lastOps: ops.slice().sort((a,b)=>safeNum(b.ts||b.time||0)-safeNum(a.ts||a.time||0)).slice(0,8)
    };
  }

  function mount(){
    const host = document.getElementById("mgrReportV2");
    if(!host) return;

    const {db} = getDB();
    const norm = normalize(db);
    const sum = summarize(norm);

    host.style.display = "block";
    host.innerHTML = `
      <div class="reportTitle">Yönetici Raporu</div>
      <div class="reportSub">${esc(sum.meta.nowTR)} • Ürün: <b>${sum.meta.prodCount}</b> • İşlem: <b>${sum.meta.opsCount}</b>
        <span style="opacity:.7"> (Bu özet son 30 gün ağırlıklı)</span>
      </div>

      <div class="reportGrid">
        <div class="kpi">
          <div class="k">Bugün işlem</div>
          <div class="v">${sum.kpi.ops1d}</div>
          <div class="s">Gün içi tempo göstergesi</div>
        </div>
        <div class="kpi">
          <div class="k">7 gün işlem</div>
          <div class="v">${sum.kpi.ops7d}</div>
          <div class="s">Haftalık hareketlilik</div>
        </div>
        <div class="kpi">
          <div class="k">30 gün işlem</div>
          <div class="v">${sum.kpi.ops30d}</div>
          <div class="s">Aylık hareketlilik</div>
        </div>
      </div>

      <div class="reportSectionTitle">Tür dağılımı (30g)</div>
      <div class="reportList">
        ${Object.entries(sum.kpi.types30).sort((a,b)=>b[1]-a[1]).slice(0,10).map(([t,n])=>`
          <div class="reportItem">
            <div class="t">${esc(t)}</div>
            <div class="reportBadgeRow">
              <span class="reportBadge">${n} işlem</span>
            </div>
          </div>
        `).join("") || `<div class="reportItem"><div class="m">Kayıt yok.</div></div>`}
      </div>

      <div class="reportSectionTitle">En hareketli ürünler (30g)</div>
      <div class="reportList">
        ${sum.kpi.topProducts.map(p=>`
          <div class="reportItem">
            <div class="t">${esc(p.name)}</div>
            <div class="reportBadgeRow">
              <span class="reportBadge">${p.n} hareket</span>
            </div>
          </div>
        `).join("") || `<div class="reportItem"><div class="m">Kayıt yok.</div></div>`}
      </div>

      <div class="reportSectionTitle">Uyarılar</div>
      <div class="reportList">
        ${(sum.kpi.warns||[]).map(w=>`
          <div class="reportItem reportWarn">
            <div class="t">Dikkat</div>
            <div class="m">${esc(w)}</div>
          </div>
        `).join("") || `<div class="reportItem"><div class="m">Şimdilik belirgin uyarı yok.</div></div>`}
      </div>

      <div class="reportSectionTitle">Son işlemler</div>
      <div class="reportList">
        ${sum.lastOps.map(o=>`
          <div class="reportItem">
            <div class="t">${esc(o.type||o.kind||"İşlem")}</div>
            <div class="m">${esc(o.pname||o.name||o.productName||"")} ${o.qty!=null?(" • adet: "+esc(o.qty)):""}</div>
            <div class="reportBadgeRow">
              <span class="reportBadge">${esc(toTRDate(o.ts||o.time||0))}</span>
            </div>
          </div>
        `).join("") || `<div class="reportItem"><div class="m">İşlem yok.</div></div>`}
      </div>
    `;
  }

  // dışarıdan da çağrılabilsin (debug)
  window.__SK_REPORT_V2__ = mount;

  // Sayfa yüklenince bir kez dene (Rapor sekmesi yoksa bile zarar vermez)
  window.addEventListener("load", ()=>{ try{ mount(); }catch(_){} }, {once:true});
})();
"""

# JS'i en sona ekle (</body> öncesi)
if "window.__SK_REPORT_V2__" not in s:
    if "</body>" in s:
        s = s.replace("</body>", "<script>\n"+js_inject+"\n</script>\n</body>", 1)
    else:
        s += "\n<script>\n"+js_inject+"\n</script>\n"

p.write_text(s, encoding="utf-8")
print("OK: C (Yönetici raporu) eklendi. Backup:", "index.html.bak."+__import__("datetime").datetime.now().strftime("%Y%m%d_%H%M%S"))
PY

git add index.html
git commit -m "C: yönetici raporu v2 (KPI + türler + top ürün + uyarılar)" || true
git push -u origin main

echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
