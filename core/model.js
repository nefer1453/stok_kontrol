// Stok Kontrol Motoru — veri çekirdeği (v0.2)
// UI değişir, ama bu model kalır.

export const DB_KEY = "stok_kontrol_v2";

export function now(){ return Date.now(); }

export function newDB(){
  return {
    v: 2,
    items: [],   // ürün kartları (id, name, createdAt, etc.)
    ops: [],     // işlemler (skt, sipariş, dağılım, satış, sayım...)
    meta: {
      createdAt: now(),
      updatedAt: now(),
    }
  };
}

export function load(){
  try{
    const raw = localStorage.getItem(DB_KEY);
    if(!raw) return newDB();
    const db = JSON.parse(raw);
    if(!db || db.v !== 2) return newDB();
    return db;
  }catch(e){
    return newDB();
  }
}

export function save(db){
  db.meta = db.meta || {};
  db.meta.updatedAt = now();
  localStorage.setItem(DB_KEY, JSON.stringify(db));
}

export function uid(prefix="id"){
  return prefix + "_" + now().toString(16) + "_" + Math.random().toString(16).slice(2,8);
}

// Ürün ekle/bul
export function addItem(db, name){
  const n = (name||"").trim();
  if(!n) throw new Error("Ürün adı boş");
  const id = uid("p");
  const it = { id, name: n, createdAt: now(), tags: [], active: true };
  db.items.push(it);
  return it;
}

export function findItemByName(db, name){
  const n=(name||"").trim().toLowerCase();
  return db.items.find(x => (x.name||"").toLowerCase() === n) || null;
}
