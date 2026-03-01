set -e
cd "$(dirname "$0")/.."

echo "== HEALTHCHECK =="
echo "[1] index.html var mı?"
test -f index.html && echo "OK" || (echo "YOK"; exit 1)

echo "[2] renderOpsVirtual var mı?"
if grep -q "function renderOpsVirtual" index.html; then
  echo "OK"
else
  echo "YOK (ops virtual yoksa normal olabilir)"
fi

echo "[3] renderOpsVirtual içinde çıplak packCount/packSize var mı? (asıl tehlike bu)"
set +e
python - <<'PY'
import re, sys
s=open("index.html","r",encoding="utf-8").read()

m=re.search(r'function\s+renderOpsVirtual\s*\(\)\s*\{[\s\S]*?\n\s*\}', s)
if not m:
    print("renderOpsVirtual yok -> PASS")
    sys.exit(0)

block=m.group(0)
bad=[]
for mm in re.finditer(r'(?<!\.)\b(packCount|packSize)\b', block):
    ln = block.count("\n", 0, mm.start()) + 1
    bad.append((mm.group(1), ln))

if bad:
    print("RİSK VAR: renderOpsVirtual içinde çıplak değişken bulundu:")
    for k,ln in bad[:30]:
        print(f" - {k} @ renderOpsVirtual:+{ln}")
    sys.exit(2)

print("OK: renderOpsVirtual temiz ✅")
sys.exit(0)
PY
rc=$?
set -e

if [ "$rc" -eq 2 ]; then
  echo "=> SONUÇ: Ops ekranında donma riski var (RefError)."
elif [ "$rc" -ne 0 ]; then
  echo "=> SONUÇ: Healthcheck python kısmı hata verdi (rc=$rc)."
else
  echo "=> SONUÇ: renderOpsVirtual temiz, rahatız."
fi

echo "[4] git durumu"
git status -sb || true

echo "== DONE =="
