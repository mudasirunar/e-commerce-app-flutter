import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, deleteField, doc, getDoc, getDocs, query, serverTimestamp, setLogLevel,
  setDoc, Timestamp, updateDoc, where,
} from 'firebase/firestore';

let env;
setLogLevel('silent');
const date = Timestamp.fromMillis(1700000000000);
const profile = (uid) => ({
  uid, name: 'Customer', email: `${uid}@example.com`, phone: '',
  defaultAddress: '', role: 'customer', createdAt: date, updatedAt: date,
});
const dbFor = (uid, claims = {}) =>
  env.authenticatedContext(uid, { email: `${uid}@example.com`, ...claims }).firestore();
const cartItem = (quantity = 1) => ({
  productId: 'active', quantity, updatedAt: serverTimestamp(),
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-ecommerce-rules',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, 'users/alice'), profile('alice')),
      setDoc(doc(db, 'users/bob'), profile('bob')),
      setDoc(doc(db, 'users/mallory'), { ...profile('mallory'), role: 'admin' }),
      setDoc(doc(db, 'products/active'), { isActive: true, stockQuantity: 2 }),
      setDoc(doc(db, 'products/inactive'), { isActive: false, stockQuantity: 2 }),
      setDoc(doc(db, 'products/empty'), { isActive: true, stockQuantity: 0 }),
      setDoc(doc(db, 'categories/active'), { isActive: true }),
      setDoc(doc(db, 'categories/inactive'), { isActive: false }),
      setDoc(doc(db, 'orders/alice-order'), { userId: 'alice', status: 'Pending' }),
      setDoc(doc(db, 'orders/bob-order'), { userId: 'bob', status: 'Pending' }),
      setDoc(doc(db, 'users/alice/checkoutAttempts/attempt'), { orderId: 'alice-order' }),
      setDoc(doc(db, 'emailChallenges/challenge'), { uid: 'alice' }),
      setDoc(doc(db, 'emailRateLimits/limit'), { count: 1 }),
      setDoc(doc(db, 'emailOutbox/email'), { uid: 'alice' }),
    ]);
  });
});

after(async () => { await env?.cleanup(); });

test('public catalog reads require active filtering; claims permit inactive admin reads', async () => {
  const publicDb = env.unauthenticatedContext().firestore();
  for (const path of ['products', 'categories']) {
    await assertSucceeds(getDoc(doc(publicDb, `${path}/active`)));
    await assertFails(getDoc(doc(publicDb, `${path}/inactive`)));
    await assertSucceeds(getDocs(query(collection(publicDb, path), where('isActive', '==', true))));
    await assertFails(getDocs(collection(publicDb, path)));
    await assertSucceeds(getDocs(collection(dbFor('admin', { admin: true }), path)));
    await assertFails(getDoc(doc(dbFor('mallory'), `${path}/inactive`)));
  }
});

test('profiles are owner-only; even admin cannot read/edit another profile', async () => {
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'users/alice')));
  for (const db of [env.unauthenticatedContext().firestore(), dbFor('bob'), dbFor('admin', { admin: true })]) {
    await assertFails(getDoc(doc(db, 'users/alice')));
    await assertFails(updateDoc(doc(db, 'users/alice'), { name: 'Changed', updatedAt: serverTimestamp() }));
  }
  await assertFails(getDocs(collection(dbFor('alice'), 'users')));
  await assertFails(deleteDoc(doc(dbFor('alice'), 'users/alice')));
});

test('signup profile requires exact fields, token email, baseline role and server timestamps', async () => {
  const db = dbFor('new');
  const data = { ...profile('new'), createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
  for (const extra of [
    { role: 'admin' }, { email: 'other@example.com' }, { uid: 'other' },
    { createdAt: date }, { updatedAt: date }, { admin: true }, { name: '' },
    { phone: 'invalid' }, { defaultAddress: 42 },
  ]) {
    await assertFails(setDoc(doc(db, 'users/new'), { ...data, ...extra }));
  }
  const missing = { ...data };
  delete missing.role;
  await assertFails(setDoc(doc(db, 'users/new'), missing));
  await assertFails(setDoc(doc(db, 'users/other'), data));
  await assertSucceeds(setDoc(doc(db, 'users/new'), data));
});

test('profile updates allow delivery/basic fields and reject privilege/audit changes', async () => {
  const ref = doc(dbFor('alice'), 'users/alice');
  await assertSucceeds(updateDoc(ref, {
    name: 'Alice', phone: '+923001234567', defaultAddress: 'Delivery address',
    updatedAt: serverTimestamp(),
  }));
  for (const change of [
    { role: 'admin' }, { uid: 'bob' }, { email: 'other@example.com' },
    { createdAt: serverTimestamp() }, { admin: true }, { name: '' },
    { phone: 'invalid' }, { defaultAddress: 123 },
  ]) {
    await assertFails(updateDoc(ref, { ...change, updatedAt: serverTimestamp() }));
  }
  await assertFails(updateDoc(ref, { name: 'No timestamp', updatedAt: date }));
  await assertFails(updateDoc(ref, { phone: deleteField(), updatedAt: serverTimestamp() }));
});

test('cart enforces own positive integer quantity, active stock and exact shape', async () => {
  const alice = dbFor('alice');
  const ref = doc(alice, 'users/alice/cart/active');
  for (const quantity of [0, -1, 1.5, '1', 3]) {
    await assertFails(setDoc(ref, cartItem(quantity)));
  }
  await assertFails(setDoc(ref, { ...cartItem(), productId: 'other' }));
  await assertFails(setDoc(ref, { ...cartItem(), priceMinor: 1 }));
  await assertFails(setDoc(ref, { ...cartItem(), updatedAt: date }));
  for (const productId of ['inactive', 'empty', 'missing']) {
    await assertFails(setDoc(doc(alice, `users/alice/cart/${productId}`), { ...cartItem(), productId }));
  }
  await assertSucceeds(setDoc(ref, cartItem()));
  await assertSucceeds(updateDoc(ref, { quantity: 2, updatedAt: serverTimestamp() }));
  await assertSucceeds(getDocs(collection(alice, 'users/alice/cart')));
  for (const db of [dbFor('bob'), env.unauthenticatedContext().firestore()]) {
    await assertFails(getDoc(doc(db, 'users/alice/cart/active')));
    await assertFails(setDoc(doc(db, 'users/alice/cart/active'), cartItem()));
    await assertFails(deleteDoc(doc(db, 'users/alice/cart/active')));
  }
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'products/active'), { isActive: false });
  });
  await assertSucceeds(deleteDoc(ref));
});

test('only order owner/admin can read; queries must be scoped to owner', async () => {
  const alice = dbFor('alice');
  await assertSucceeds(getDoc(doc(alice, 'orders/alice-order')));
  await assertFails(getDoc(doc(alice, 'orders/bob-order')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'orders/alice-order')));
  await assertSucceeds(getDocs(query(collection(alice, 'orders'), where('userId', '==', 'alice'))));
  await assertFails(getDocs(collection(alice, 'orders')));
  await assertSucceeds(getDocs(collection(dbFor('admin', { admin: true }), 'orders')));
  await assertFails(getDocs(collection(dbFor('mallory'), 'orders')));
});

test('all direct order/catalog writes are denied, including authenticated admins', async () => {
  for (const db of [dbFor('alice'), dbFor('admin', { admin: true }), env.unauthenticatedContext().firestore()]) {
    for (const collectionName of ['orders', 'products', 'categories']) {
      await assertFails(setDoc(doc(db, `${collectionName}/new`), { userId: 'alice', isActive: true }));
      const id = collectionName === 'orders' ? 'alice-order' : 'active';
      await assertFails(updateDoc(doc(db, `${collectionName}/${id}`), { status: 'Cancelled', totalMinor: 1 }));
      await assertFails(deleteDoc(doc(db, `${collectionName}/${id}`)));
    }
  }
});

test('checkout attempts permit own get only and deny writes/cross-user/list access', async () => {
  const alice = dbFor('alice');
  await assertSucceeds(getDoc(doc(alice, 'users/alice/checkoutAttempts/attempt')));
  await assertFails(getDoc(doc(dbFor('bob'), 'users/alice/checkoutAttempts/attempt')));
  await assertFails(getDocs(collection(alice, 'users/alice/checkoutAttempts')));
  await assertFails(setDoc(doc(alice, 'users/alice/checkoutAttempts/new'), { orderId: 'fake' }));
  await assertFails(deleteDoc(doc(alice, 'users/alice/checkoutAttempts/attempt')));
});

test('private email and unknown collections are denied to all clients', async () => {
  for (const db of [dbFor('alice'), dbFor('admin', { admin: true }), env.unauthenticatedContext().firestore()]) {
    for (const path of ['emailChallenges/challenge', 'emailRateLimits/limit', 'emailOutbox/email', 'unknown/document']) {
      await assertFails(getDoc(doc(db, path)));
      await assertFails(setDoc(doc(db, path), { uid: 'alice' }));
    }
  }
});
