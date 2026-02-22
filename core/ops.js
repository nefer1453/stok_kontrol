// İşlem kayıtları (v0.2)
// Tipler: skt | siparis | dagitim | satis | sayim | fiyat_iste | not

import { uid, now } from "./model.js";

export const OP_TYPES = ["skt","siparis","dagitim","satis","sayim","fiyat_iste","not"];

// ortak işlem şeması
export function addOp(db, op){
  const type = op?.type;
  if(!OP_TYPES.includes(type)) throw new Error("Geçersiz op.type: " + type);

  const row = {
    id: uid("op"),
    type,
    itemId: op.itemId || null,
    ts: op.ts || now(),
    qty: Number.isFinite(op.qty) ? op.qty : null,
    price: Number.isFinite(op.price) ? op.price : null,
    channel: op.channel || null, // dagitim: normal|iskonto|insert gibi
    note: op.note || "",
    extra: op.extra || {}
  };

  db.ops.push(row);
  return row;
}
