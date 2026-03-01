set -e
cd "$(dirname "$0")/.."

echo "== ROLLBACK last commit =="
git log -1 --oneline
git revert --no-edit HEAD || {
  echo "Revert çatıştı. Güvenli yol: backup'tan geri koy."
  exit 1
}
git push
echo "OK. Link:"
echo "https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
