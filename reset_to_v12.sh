set -e

cd "$(dirname "$0")"

echo "== FETCH =="
git fetch origin

echo "== RESET to v1.2 (11826c6) =="
git reset --hard 11826c6

echo "== PUSH (force-with-lease) =="
git push --force-with-lease origin main

echo
echo "OK ✅ Repo v1.2'ye döndü."
echo "LINK (cache kır): https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
