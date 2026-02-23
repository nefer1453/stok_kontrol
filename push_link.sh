set -e

cd "$(dirname "$0")"

echo "== Git durum =="
git status -sb || true

echo
echo "== Commit + Push =="
git add -A

# Değişiklik yoksa commit atlamasın
if git diff --cached --quiet; then
  echo "Değişiklik yok. (commit yok)"
else
  git commit -m "update: $(date +%Y-%m-%d_%H:%M:%S)"
fi

git push -u origin main

echo
echo "== Link (cache kır) =="
echo "https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
