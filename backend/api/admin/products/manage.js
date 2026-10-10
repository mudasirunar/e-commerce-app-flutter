import { getFirebaseAdmin } from '../../../src/firebase.js';
import { authenticateUser, requireAdmin } from '../../../src/auth-middleware.js';
import { generateSecureToken } from '../../../src/crypto-utils.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    // 1. Authenticate and require admin privileges
    const user = await authenticateUser(req);
    requireAdmin(user);

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const { action, productId, productData } = body;

    const validActions = ['create', 'update', 'update-stock', 'toggle-active'];
    if (!action || !validActions.includes(action)) {
      return res.status(400).json({
        error: `Valid action (${validActions.join(', ')}) is required.`
      });
    }

    const admin = getFirebaseAdmin();
    const db = admin.firestore();

    // ----------------------------------------------------
    // ACTION: CREATE PRODUCT
    // ----------------------------------------------------
    if (action === 'create') {
      const data = productData || body;
      const { name, categoryId, description, priceMinor, stockQuantity, imageUrl, isFeatured = false } = data;

      if (!name || typeof name !== 'string' || !name.trim()) {
        return res.status(400).json({ error: 'Product name is required.' });
      }

      if (!categoryId || typeof categoryId !== 'string') {
        return res.status(400).json({ error: 'Valid categoryId is required.' });
      }

      const parsedPrice = parseInt(priceMinor, 10);
      if (isNaN(parsedPrice) || parsedPrice <= 0) {
        return res.status(400).json({ error: 'priceMinor must be a positive integer.' });
      }

      const parsedStock = parseInt(stockQuantity, 10);
      if (isNaN(parsedStock) || parsedStock < 0) {
        return res.status(400).json({ error: 'stockQuantity must be an integer >= 0.' });
      }

      const newId = productId || `prod_${Date.now()}_${generateSecureToken().slice(0, 4)}`;
      const docRef = db.collection('products').doc(newId);

      const existing = await docRef.get();
      if (existing.exists) {
        return res.status(400).json({ error: `Product with ID "${newId}" already exists.` });
      }

      const newProduct = {
        productId: newId,
        categoryId: categoryId.trim(),
        name: name.trim(),
        normalizedName: name.trim().toLowerCase(),
        description: (description || '').trim(),
        priceMinor: parsedPrice,
        stockQuantity: parsedStock,
        imageUrl: (imageUrl || '').trim(),
        isActive: true,
        isFeatured: !!isFeatured,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      await docRef.set(newProduct);

      return res.status(201).json({
        success: true,
        message: 'Product created successfully.',
        productId: newId,
        product: newProduct
      });
    }

    // For all other actions, productId is mandatory
    if (!productId || typeof productId !== 'string') {
      return res.status(400).json({ error: 'productId is required for this operation.' });
    }

    const docRef = db.collection('products').doc(productId.trim());

    // ----------------------------------------------------
    // ACTION: UPDATE STOCK
    // ----------------------------------------------------
    if (action === 'update-stock') {
      const newStock = parseInt(body.stockQuantity ?? body.stock, 10);
      if (isNaN(newStock) || newStock < 0) {
        return res.status(400).json({ error: 'stockQuantity must be an integer >= 0.' });
      }

      await db.runTransaction(async (transaction) => {
        const snap = await transaction.get(docRef);
        if (!snap.exists) {
          const err = new Error(`Product "${productId}" not found.`);
          err.statusCode = 404;
          throw err;
        }

        transaction.update(docRef, {
          stockQuantity: newStock,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      return res.status(200).json({
        success: true,
        message: `Stock updated to ${newStock} for product "${productId}".`,
        productId,
        stockQuantity: newStock
      });
    }

    // ----------------------------------------------------
    // ACTION: TOGGLE ACTIVE / DEACTIVATE
    // ----------------------------------------------------
    if (action === 'toggle-active') {
      let finalActiveState;
      await db.runTransaction(async (transaction) => {
        const snap = await transaction.get(docRef);
        if (!snap.exists) {
          const err = new Error(`Product "${productId}" not found.`);
          err.statusCode = 404;
          throw err;
        }

        const currentActive = !!snap.data().isActive;
        finalActiveState = body.isActive !== undefined ? !!body.isActive : !currentActive;

        transaction.update(docRef, {
          isActive: finalActiveState,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      return res.status(200).json({
        success: true,
        message: `Product "${productId}" isActive set to ${finalActiveState}.`,
        productId,
        isActive: finalActiveState
      });
    }

    // ----------------------------------------------------
    // ACTION: UPDATE PRODUCT DETAILS
    // ----------------------------------------------------
    if (action === 'update') {
      const data = productData || body;
      const updates = {};

      if (data.name !== undefined) {
        updates.name = data.name.trim();
        updates.normalizedName = data.name.trim().toLowerCase();
      }
      if (data.description !== undefined) updates.description = data.description.trim();
      if (data.categoryId !== undefined) updates.categoryId = data.categoryId.trim();
      if (data.imageUrl !== undefined) updates.imageUrl = data.imageUrl.trim();
      if (data.isFeatured !== undefined) updates.isFeatured = !!data.isFeatured;
      if (data.priceMinor !== undefined) {
        const price = parseInt(data.priceMinor, 10);
        if (isNaN(price) || price <= 0) {
          return res.status(400).json({ error: 'priceMinor must be a positive integer.' });
        }
        updates.priceMinor = price;
      }
      if (data.stockQuantity !== undefined) {
        const stock = parseInt(data.stockQuantity, 10);
        if (isNaN(stock) || stock < 0) {
          return res.status(400).json({ error: 'stockQuantity must be an integer >= 0.' });
        }
        updates.stockQuantity = stock;
      }

      if (Object.keys(updates).length === 0) {
        return res.status(400).json({ error: 'No valid fields provided for update.' });
      }

      updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

      await db.runTransaction(async (transaction) => {
        const snap = await transaction.get(docRef);
        if (!snap.exists) {
          const err = new Error(`Product "${productId}" not found.`);
          err.statusCode = 404;
          throw err;
        }
        transaction.update(docRef, updates);
      });

      return res.status(200).json({
        success: true,
        message: `Product "${productId}" updated successfully.`,
        productId,
        updates
      });
    }

  } catch (error) {
    console.error('Admin product management error:', error);
    return res.status(error.statusCode || 500).json({
      error: error.message || 'Product management operation failed.'
    });
  }
}
