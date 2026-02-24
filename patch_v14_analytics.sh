#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "v1.4 Analitik Çekirdek Ekleniyor..."

cp index.html index.html.bak_v14_analytics

cat >> index.html << 'EOF'

<script>
/* ================================
   v1.4 ANALYTICS ENGINE
================================ */

function analyzeProduct(productId){
  const now = Date.now();
  const days30 = now - (30*24*60*60*1000);

  const ops = db.ops.filter(o => o.productId === productId);

  let totalIn = 0;
  let totalOut = 0;
  let totalSales = 0;
  let last30Sales = 0;
  let insertSales = 0;
  let totalReturn = 0;

  for(const o of ops){
    const qty = Number(o.qty)||0;

    if(o.direction === "in") totalIn += qty;
    if(o.direction === "out") totalOut += qty;

    if(o.type === "satış"){
      totalSales += qty;
      if(o.ts >= days30) last30Sales += qty;
      if(o.subtype && o.subtype.toLowerCase().includes("insert")){
        insertSales += qty;
      }
    }

    if(o.type === "iade"){
      totalReturn += qty;
    }
  }

  const netStock = totalIn - totalOut;

  const salesPower = totalIn > 0 ? last30Sales / totalIn : 0;
  const returnRate = totalOut > 0 ? totalReturn / totalOut : 0;
  const insertImpact = totalSales > 0 ? insertSales / totalSales : 0;

  const score =
      (salesPower * 50)
    + (insertImpact * 20)
    - (returnRate * 20)
    + (netStock > 0 ? 10 : -10);

  return {
    totalIn,
    totalOut,
    netStock,
    last30Sales,
    insertImpact,
    returnRate,
    score: Math.round(score)
  };
}

function analyzeAllProducts(){
  return db.items.map(it => ({
    id: it.id,
    name: it.name,
    ...analyzeProduct(it.id)
  })).sort((a,b)=>b.score-a.score);
}
</script>

EOF

echo "v1.4 Analitik Çekirdek Eklendi."
