set -e
ts=$(date +%Y%m%d_%H%M%S)

# 0) Yedek
mkdir -p _backup
cp -f app/app.js "_backup/app.js.$ts.bak"
cp -f index.html "_backup/index.html.$ts.bak" 2>/dev/null || true
cp -f app/app.css "_backup/app.css.$ts.bak" 2>/dev/null || true

python - <<'PY'
from pathlib import Path
import re, sys

p = Path("app/app.js")
s = p.read_text(encoding="utf-8")

MARK = "/* SUBTYPES_V1 */"
if MARK in s:
    print("Zaten ekli: SUBTYPES_V1. Çıkıyorum.")
    sys.exit(0)

# 1) Uygun ankraj arıyoruz (bulamazsak dokunmadan çık)
anchors = [
  r"const\s+OP_TYPES\s*=",
  r"const\s+TYPE_LABELS\s*=",
  r"function\s+openOpModal\s*\(",
  r"function\s+addOp\s*\(",
  r"function\s+saveOp\s*\(",
  r"id=['\"]opType['\"]",
]
hit = None
for a in anchors:
    if re.search(a, s):
        hit = a
        break

if not hit:
    print("ANKRAJ YOK: app/app.js içinde beklenen yapı bulunamadı. Hiçbir değişiklik yapılmadı.")
    sys.exit(2)

# 2) Şema: tür -> alt türler (zorunlu)
subtypes = r"""
/* SUBTYPES_V1 */
const OP_SUBTYPES = {
  // Artma
  "siparis": [
    "firma_ziyaret",          // firma yetkilisi mağazaya geldi
    "firma_telefon_geldi",    // firma yetkilisi aradı
    "firma_telefon_edildi",   // biz aradık
    "depo_merkez",            // merkez depoya
    "depo_sarkuteri"          // şarküteri depoya
  ],
  "dagilim": [
    "merkez_dagilim",
    "iskonto_dagilim",
    "insert_dagilim"
  ],

  // Eksilme
  "satis": [
    "normal_satis",
    "insert_satis",
    "iskonto_satis"
  ],
  "skt": [
    "skt_cikti"
  ],
  "iade": [
    "musteri_iadesi",
    "tarihi_gecmis",
    "fabrika_sorun",
    "raf_sorun"
  ]
};

const OP_SUBTYPE_LABEL = {
  "firma_ziyaret":"Firma ziyareti",
  "firma_telefon_geldi":"Firma telefon geldi",
  "firma_telefon_edildi":"Firma telefon edildi",
  "depo_merkez":"Depoya sipariş (Merkez)",
  "depo_sarkuteri":"Depoya sipariş (Şarküteri)",

  "merkez_dagilim":"Merkez dağılımı",
  "iskonto_dagilim":"İskonto dağılımı",
  "insert_dagilim":"İnsert dağılımı",

  "normal_satis":"Normal satış",
  "insert_satis":"İnsert satış",
  "iskonto_satis":"İskonto satış",

  "skt_cikti":"SKT çıktı",

  "musteri_iadesi":"Müşteri iadesi",
  "tarihi_gecmis":"Tarihi geçmiş",
  "fabrika_sorun":"Fabrika sorunu",
  "raf_sorun":"Raf sorunu"
};

// İnsert detayları sadece insert_* seçimlerinde açılacak
function isInsertSubtype(sub){ return String(sub||"").indexOf("insert_") === 0; }

// Zorunluluk kontrolü: type seçildi mi + subtype seçildi mi
function requireSubtypeOrThrow(type, subtype){
  const t = String(type||"").trim();
  const sub = String(subtype||"").trim();
  if(!t) throw new Error("İşlem türü seçilmedi.");
  const list = OP_SUBTYPES[t];
  if(list && list.length){
    if(!sub) throw new Error("Alt kırılım seçilmedi.");
    if(!list.includes(sub)) throw new Error("Alt kırılım geçersiz: "+sub);
  }
  return true;
}
"""

# 3) En güvenlisi: ilk büyük "const ..." bloğunun yakınına ekle
# OP_TYPES veya TYPE_LABELS görürsek hemen öncesine koyarız.
m = re.search(r"(const\s+OP_TYPES\s*=|const\s+TYPE_LABELS\s*=)", s)
if m:
    ins = m.start()
    s = s[:ins] + subtypes + "\n\n" + s[ins:]
else:
    # yoksa dosyanın en üst import/baş tarafının altına ekle
    s = subtypes + "\n\n" + s

p.write_text(s, encoding="utf-8")
print("OK: SUBTYPES_V1 şeması eklendi. (UI bağlama bir sonraki adım)")
PY

git add app/app.js
git commit -m "v1.x: add subtype schema + required check (SUBTYPES_V1)" || true
git push -u origin main

echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
