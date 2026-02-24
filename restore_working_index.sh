set -e

cd "$(dirname "$0")"

echo "== 1) Mevcut index'in ilk satırları =="
head -n 5 index.html 2>/dev/null || true
echo

echo "== 2) En güncel yedeği bul =="
cand="$(ls -1t index.html.bak.* _backup/index.html* 2>/dev/null | head -n 1 || true)"
if [ -z "$cand" ]; then
  echo "HATA: Yedek bulunamadı. (index.html.bak.* veya _backup/ altında yok)"
  exit 1
fi
echo "Yedek seçildi: $cand"
echo

echo "== 3) Yedeği index.html olarak geri yükle =="
cp -f "$cand" index.html

echo "== 4) Kontrol: index.html DOCTYPE var mı? =="
head -n 3 index.html
echo
grep -n -m1 -E "<!DOCTYPE html|<html" index.html && echo "OK: HTML gibi duruyor." || {
  echo "HATA: Bu yedek de HTML değil. Bir önceki yedeği denememiz gerekebilir."
  exit 1
}

echo
echo "== 5) Git commit + push =="
git add index.html
git commit -m "restore: working index.html from backup" || true
git push -u origin main

echo
echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
