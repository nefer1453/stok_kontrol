set -e

cd "$(dirname "$0")"
test -f index.html || { echo "index.html yok"; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp -f index.html "index.html.bak_${ts}"
echo "✅ Backup: index.html.bak_${ts}"

python - <<'PY'
from pathlib import Path

p = Path("index.html")
s = p.read_text(encoding="utf-8", errors="ignore")

needle = "function analyzeProduct(productId){"
if needle in s:
    print("ℹ️ analyzeProduct zaten var. Değişiklik yapmadım.")
    raise SystemExit(0)

block = r'''
// ===== v1.6 ANALYTICS CORE (auto-insert) =====
function analyzeProduct(productId){
  const now = Date.now();
  const days30 = 30 * 24 * 60 * 60 * 1000;

  const ops = (db.ops || []).filter(o => o.productId === productId);

  let totalIn = 0;
  let totalOut = 0;

  let last30Sales = 0;
  let insertSales = 0;
  let normalSales = 0;

  let returnQty = 0;
  let distributionQty = 0;

  for(const o of ops){
    const qty = Number(o.qty || 0);

    if(o.direction === "in") totalIn += qty;
    if(o.direction === "out") totalOut += qty;

    const t = String(o.type || "");

    // Son 30 gün satış
    if(o.direction === "out" && t.includes("Satış")){
      if(now - (Number(o.ts||0)) <= days30){
        last30Sales += qty;
      }
    }

    // Insert satış
    if(o.direction === "out" && t.includes("Satış") && t.includes("Insert")){
      insertSales += qty;
    }

    // Normal satış (Insert değilse)
    if(o.direction === "out" && t.includes("Satış") && !t.includes("Insert")){
      normalSales += qty;
    }

    // İade
    if(o.direction === "out" && t.includes("İade")){
      returnQty += qty;
    }

    // Dağılım (stok artış kaynaklarından biri)
    if(o.direction === "in" && t.includes("Dağılım")){
      distributionQty += qty;
    }
  }

  const netStock = totalIn - totalOut;

  // Oranlar
  const returnRate = totalOut > 0 ? (returnQty / totalOut) : 0;
  const distributionEfficiency = distributionQty > 0 ? (normalSales / distributionQty) : 0;
  const insertShare = (normalSales + insertSales) > 0 ? (insertSales / (normalSales + insertSales)) : 0;

  // Skor (0-100): basit ama yönetici bakışına uygun başlangıç
  // + satış (last30Sales) iyi
  // + dağılım verimi iyi
  // - iade oranı kötü
  // - net stok çok şişikse hafif kırp
  let score = 0;

  // satış katkısı: 0..40
  score += Math.min(40, last30Sales * 2);

  // verim katkısı: 0..35
  score += Math.max(0, Math.min(35, distributionEfficiency * 35));

  // iade cezası: 0..20
  score -= Math.min(20, returnRate * 100 * 0.4);

  // stok şişmesi cezası: 0..10
  if(netStock > 20) score -= Math.min(10, (netStock - 20) * 0.2);

  // insert payı şu an nötr (ileride “insert dönemi” tarih aralığı eklenince anlam kazanacak)
  // score += 0;

  score = Math.max(0, Math.min(100, Math.round(score)));

  return {
    totalIn, totalOut, netStock,
    last30Sales, insertSales, normalSales,
    returnQty, distributionQty,
    returnRate, distributionEfficiency, insertShare,
    score,
    opsCount: ops.length
  };
}
// ===== /v1.6 ANALYTICS CORE =====
'''.lstrip("\n")

# En güvenli yer: </script> kapanmadan hemen önce ekle
idx = s.rfind("</script>")
if idx == -1:
    print("❌ </script> bulunamadı. index.html beklenmeyen formatta.")
    raise SystemExit(1)

s2 = s[:idx] + "\n\n" + block + "\n" + s[idx:]
p.write_text(s2, encoding="utf-8")
print("✅ analyzeProduct eklendi (</script> öncesine).")
PY

echo "✅ Patch bitti."
