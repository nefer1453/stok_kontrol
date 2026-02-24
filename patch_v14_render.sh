#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "v1.4 Analitik Render Bağlanıyor..."

cp index.html index.html.bak_v14_render

cat >> index.html << 'EOF'

<script>
/* ================================
   v1.4 RENDER ANALYTICS
================================ */

function renderManagerInsights(){
  const results = analyzeAllProducts();
  if(!results.length) return;

  const container = document.getElementById("manager-insights");
  if(!container) return;

  const top = results[0];
  const weak = results[results.length-1];

  container.innerHTML = `
    <div style="margin-top:16px;padding:14px;border:1px solid #1e293b;border-radius:14px;background:#0f172a">
      <div style="font-weight:700;font-size:16px;margin-bottom:8px">Yönetici Bakışı</div>
      <div style="font-size:14px;margin-bottom:6px">
        🔥 En güçlü ürün: <b>${top.name}</b> (Skor: ${top.score})
      </div>
      <div style="font-size:14px;margin-bottom:6px">
        ⚠️ En zayıf ürün: <b>${weak.name}</b> (Skor: ${weak.score})
      </div>
    </div>
  `;
}

/* mevcut render çağrısına ekle */
const oldRender = window.render;
window.render = function(){
  oldRender();
  renderManagerInsights();
};
</script>

EOF

echo "v1.4 Render Bağlandı."
