import React, { useEffect, useState } from 'react';
import { getFirestore, collection, getDocs } from 'firebase/firestore';

export default function Listings() {
  const [items, setItems] = useState<any[]>([]);
  useEffect(() => {
    (async () => {
      const db = getFirestore();
      const q = collection(db, 'listings');
      const snap = await getDocs(q);
      setItems(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    })();
  }, []);
  return (
    <table>
      <thead><tr><th>Title</th><th>Price</th><th>Status</th></tr></thead>
      <tbody>
        {items.map(it => <tr key={it.id}><td>{it.title}</td><td>{it.price}</td><td>{it.status}</td></tr>)}
      </tbody>
    </table>
  );
}
