#!/data/data/com.termux/files/usr/bin/bash
set -e

FILE="index.html"
TMP="index_tmp.html"

echo "Risk etiketi motoru ekleniyor..."

awk '
BEGIN{added=0}
{
print $0

# renderProducts fonksiyonu içinde net hesaplandıktan sonra risk etiketi ekle
if($0 ~ /const net =/ && added==0){
print "    // === RISK MOTORU ==="
print "    let riskLabel=\"\";"
print "    if(net < 0){ riskLabel=\"🔴 KRİTİK\"; }"
print "    else if(net === 0){ riskLabel=\"🟡 PASİF\"; }"
print "    else{ riskLabel=\"🟢 NORMAL\"; }"
print ""
added=1
}
}
END{
if(added==0){
print \"// Risk motoru eklenemedi (net bulunamadı)\"
}
}
' "$FILE" > "$TMP"

mv "$TMP" "$FILE"

echo "Tamamlandı."
