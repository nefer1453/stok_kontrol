set -e

# 1) .gitignore yaz
cat > .gitignore <<'GI'
# --- local backups / generated ---
_backup/
_backup*/
*.bak.*
index.html.BACKUP.*
index.html.bak.*
*.BACKUP.*
*.tgz

# --- local helper scripts ---
patch_*.sh
install*.sh
push_link.sh
step2_*.sh

# --- captures ---
*.mp4
frame_*.png

# --- misc ---
.DS_Store
Thumbs.db
GI

git add .gitignore

# 2) Eğer bu dosyalar daha önce git'e girmişse takipten çıkar (dosyaları silmez!)
git rm -r --cached _backup _backup* 2>/dev/null || true
git rm -r --cached *.tgz 2>/dev/null || true
git rm -r --cached *.mp4 frame_*.png 2>/dev/null || true
git rm -r --cached index.html.BACKUP.* index.html.bak.* *.bak.* *.BACKUP.* 2>/dev/null || true
git rm -r --cached patch_*.sh install*.sh push_link.sh step2_*.sh 2>/dev/null || true

# 3) Commit + push
git commit -m "chore: repo clean (.gitignore + untrack generated files)" || true
git push -u origin main

echo "PAGES: https://nefer1453.github.io/stok_kontrol/"
echo "CACHE-KIR: https://nefer1453.github.io/stok_kontrol/?v=$(date +%s)"
