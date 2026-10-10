import { getFirebaseAdmin } from '../../src/firebase.js';
import { authenticateUser, requireAdmin } from '../../src/auth-middleware.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    // Enforce admin authorization: require valid Firebase ID token with admin claims,
    // or internal server bootstrap key if configured
    const headers = req.headers || {};
    const adminKey = headers['x-admin-key'] || headers['X-Admin-Key'];
    const expectedKey = process.env.ADMIN_BOOTSTRAP_KEY;

    if (expectedKey && adminKey && adminKey === expectedKey) {
      // Authorized via server bootstrap key
    } else {
      const user = await authenticateUser(req);
      requireAdmin(user);
    }

    const admin = getFirebaseAdmin();
    const db = admin.firestore();

    const categories = [
      { categoryId: 'electronics', name: 'Electronics', sortOrder: 1, isActive: true },
      { categoryId: 'clothing', name: 'Clothing', sortOrder: 2, isActive: true },
      { categoryId: 'home-kitchen', name: 'Home & Kitchen', sortOrder: 3, isActive: true },
      { categoryId: 'personal-care', name: 'Personal Care', sortOrder: 4, isActive: true }
    ];

    const products = [
      // ==========================================
      // Electronics (8 products)
      // ==========================================
      {
        productId: 'prod_elec_01',
        categoryId: 'electronics',
        name: 'Wireless Noise-Cancelling Headphones',
        normalizedName: 'wireless noise-cancelling headphones',
        description: 'Premium over-ear wireless headphones with active noise cancellation, 30-hour battery life, and crystal-clear acoustic sound.',
        priceMinor: 1499900, // PKR 14,999
        stockQuantity: 25,
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
        isActive: true,
        isFeatured: true
      },
      {
        productId: 'prod_elec_02',
        categoryId: 'electronics',
        name: 'Smart Fitness Watch Series 5',
        normalizedName: 'smart fitness watch series 5',
        description: 'Track your workouts, heart rate, sleep metrics, and notifications with an always-on AMOLED display and 7-day battery.',
        priceMinor: 849900, // PKR 8,499
        stockQuantity: 40,
        imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
        isActive: true,
        isFeatured: true
      },
      {
        productId: 'prod_elec_03',
        categoryId: 'electronics',
        name: 'Compact Bluetooth Speaker',
        normalizedName: 'compact bluetooth speaker',
        description: 'Waterproof portable speaker with rich 360-degree bass and IPX7 rating for outdoor and indoor entertainment.',
        priceMinor: 429900, // PKR 4,299
        stockQuantity: 50,
        imageUrl: 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_elec_04',
        categoryId: 'electronics',
        name: 'Fast Wireless Charging Pad 15W',
        normalizedName: 'fast wireless charging pad 15w',
        description: 'Ultra-slim wireless charging dock compatible with all Qi-enabled iOS and Android smartphones.',
        priceMinor: 219900, // PKR 2,199
        stockQuantity: 0, // Out of stock fixture for testing
        imageUrl: 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_elec_05',
        categoryId: 'electronics',
        name: 'Ergonomic Precision Wireless Mouse',
        normalizedName: 'ergonomic precision wireless mouse',
        description: 'Sculpted wireless mouse with thumb rest, silent tactile switches, and multi-device Bluetooth switching.',
        priceMinor: 349900, // PKR 3,499
        stockQuantity: 35,
        imageUrl: 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_elec_06',
        categoryId: 'electronics',
        name: 'RGB Mechanical Gaming Keyboard',
        normalizedName: 'rgb mechanical gaming keyboard',
        description: 'Compact tenkeyless mechanical keyboard with hot-swappable switches, per-key RGB backlighting, and aluminum frame.',
        priceMinor: 999900, // PKR 9,999
        stockQuantity: 20,
        imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800&q=80',
        isActive: true,
        isFeatured: true
      },
      {
        productId: 'prod_elec_07',
        categoryId: 'electronics',
        name: '4K Ultra HD Waterproof Action Camera',
        normalizedName: '4k ultra hd waterproof action camera',
        description: 'Capture crisp 4K 60fps stabilized footage with wide-angle lens, dual touchscreens, and underwater casing.',
        priceMinor: 1850000, // PKR 18,500
        stockQuantity: 15,
        imageUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_elec_08',
        categoryId: 'electronics',
        name: 'Fast Charging Power Bank 20000mAh',
        normalizedName: 'fast charging power bank 20000mah',
        description: 'High-capacity portable battery with 22.5W Power Delivery, dual USB-C ports, and LED digital capacity display.',
        priceMinor: 549900, // PKR 5,499
        stockQuantity: 45,
        imageUrl: 'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=800&q=80',
        isActive: true,
        isFeatured: false
      },

      // ==========================================
      // Clothing (8 products)
      // ==========================================
      {
        productId: 'prod_cloth_01',
        categoryId: 'clothing',
        name: 'Classic Oxford Cotton Shirt',
        normalizedName: 'classic oxford cotton shirt',
        description: 'Tailored from 100% breathable organic cotton. Crisp collar design suitable for both formal and casual settings.',
        priceMinor: 389900, // PKR 3,899
        stockQuantity: 35,
        imageUrl: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800&q=80',
        isActive: true,
        isFeatured: true
      },
      {
        productId: 'prod_cloth_02',
        categoryId: 'clothing',
        name: 'Relaxed Fit Denim Jacket',
        normalizedName: 'relaxed fit denim jacket',
        description: 'Vintage wash heavyweight cotton denim with branded metal buttons and spacious chest pockets.',
        priceMinor: 649900, // PKR 6,499
        stockQuantity: 20,
        imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_cloth_03',
        categoryId: 'clothing',
        name: 'Minimalist Crewneck Sweatshirt',
        normalizedName: 'minimalist crewneck sweatshirt',
        description: 'Plush fleece interior providing everyday comfort and warmth. Pre-shrunk ribbed cuffs and hem.',
        priceMinor: 299900, // PKR 2,999
        stockQuantity: 45,
        imageUrl: 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_cloth_04',
        categoryId: 'clothing',
        name: 'Premium Wool Blend Scarf',
        normalizedName: 'premium wool blend scarf',
        description: 'Soft cashmere and merino wool blend for winter elegance. Finished with delicate fringed ends.',
        priceMinor: 179900, // PKR 1,799
        stockQuantity: 30,
        imageUrl: 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_cloth_05',
        categoryId: 'clothing',
        name: 'Athletic Lightweight Running Shoes',
        normalizedName: 'athletic lightweight running shoes',
        description: 'Engineered mesh upper with responsive foam cushioning and high-traction rubber outsole.',
        priceMinor: 799900, // PKR 7,999
        stockQuantity: 25,
        imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
        isActive: true,
        isFeatured: true
      },
      {
        productId: 'prod_cloth_06',
        categoryId: 'clothing',
        name: 'Slim Fit Stretch Chino Trousers',
        normalizedName: 'slim fit stretch chino trousers',
        description: 'Versatile cotton-twill chinos with a hint of stretch for all-day comfort and mobility.',
        priceMinor: 349900, // PKR 3,499
        stockQuantity: 40,
        imageUrl: 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_cloth_07',
        categoryId: 'clothing',
        name: 'Breathable Linen Summer Shirt',
        normalizedName: 'breathable linen summer shirt',
        description: 'Naturally cool, lightweight linen with a relaxed camp collar, perfect for warmer climates.',
        priceMinor: 419900, // PKR 4,199
        stockQuantity: 30,
        imageUrl: 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_cloth_08',
        categoryId: 'clothing',
        name: 'Handcrafted Full-Grain Leather Belt',
        normalizedName: 'handcrafted full-grain leather belt',
        description: 'Durable genuine full-grain leather finished with an antique brass buckle and reinforced stitching.',
        priceMinor: 199900, // PKR 1,999
        stockQuantity: 50,
        imageUrl: 'https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=800&q=80',
        isActive: true,
        isFeatured: false
      },

      // ==========================================
      // Home & Kitchen (7 products)
      // ==========================================
      {
        productId: 'prod_home_01',
        categoryId: 'home-kitchen',
        name: 'Precision Pour-Over Coffee Kettle',
        normalizedName: 'precision pour-over coffee kettle',
        description: 'Gooseneck spout design for steady water flow. Built-in analog thermometer and heat-resistant ergonomic handle.',
        priceMinor: 489900, // PKR 4,899
        stockQuantity: 25,
        imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800&q=80',
        isActive: true,
        isFeatured: true
      },
      {
        productId: 'prod_home_02',
        categoryId: 'home-kitchen',
        name: 'Handcrafted Ceramic Dinner Set',
        normalizedName: 'handcrafted ceramic dinner set',
        description: 'Stoneware matte glazed plates and bowls. Microwave and dishwasher safe, crafted for modern tables.',
        priceMinor: 799900, // PKR 7,999
        stockQuantity: 15,
        imageUrl: 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_home_03',
        categoryId: 'home-kitchen',
        name: 'Aroma Diffuser with Ambient LED',
        normalizedName: 'aroma diffuser with ambient led',
        description: 'Ultrasonic cool mist essential oil humidifier with quiet operation and customizable ambient lighting.',
        priceMinor: 319900, // PKR 3,199
        stockQuantity: 30,
        imageUrl: 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_home_04',
        categoryId: 'home-kitchen',
        name: 'Natural Bamboo Cutting Board Set',
        normalizedName: 'natural bamboo cutting board set',
        description: 'Three-piece organic bamboo boards with juice grooves and non-slip silicone feet for kitchen prep.',
        priceMinor: 249900, // PKR 2,499
        stockQuantity: 50,
        imageUrl: 'https://images.unsplash.com/photo-1590794056226-79ef3a8147e1?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_home_05',
        categoryId: 'home-kitchen',
        name: 'Stainless Steel Insulated Tumbler 750ml',
        normalizedName: 'stainless steel insulated tumbler 750ml',
        description: 'Double-wall vacuum insulation keeping beverages icy cold for 24 hours or piping hot for 12 hours.',
        priceMinor: 189900, // PKR 1,899
        stockQuantity: 40,
        imageUrl: 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_home_06',
        categoryId: 'home-kitchen',
        name: 'Non-Stick Cast Iron Chef Skillet 10-inch',
        normalizedName: 'non-stick cast iron chef skillet 10-inch',
        description: 'Pre-seasoned heavy-duty cast iron pan offering superior heat retention and uniform searing on all stovetops.',
        priceMinor: 529900, // PKR 5,299
        stockQuantity: 20,
        imageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_home_07',
        categoryId: 'home-kitchen',
        name: 'Minimalist Nordic Desk Table Lamp',
        normalizedName: 'minimalist nordic desk table lamp',
        description: 'Modern matte finished lamp with adjustable neck and soft warm glow LED eye-care illumination.',
        priceMinor: 679900, // PKR 6,799
        stockQuantity: 18,
        imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=800&q=80',
        isActive: true,
        isFeatured: true
      },

      // ==========================================
      // Personal Care (7 products)
      // ==========================================
      {
        productId: 'prod_care_01',
        categoryId: 'personal-care',
        name: 'Botanical Hydrating Face Serum 50ml',
        normalizedName: 'botanical hydrating face serum 50ml',
        description: 'Enriched with hyaluronic acid, vitamin C, and organic botanical extracts to deeply hydrate and restore radiance.',
        priceMinor: 349900, // PKR 3,499
        stockQuantity: 60,
        imageUrl: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=800&q=80',
        isActive: true,
        isFeatured: true
      },
      {
        productId: 'prod_care_02',
        categoryId: 'personal-care',
        name: 'Sonic Electric Toothbrush',
        normalizedName: 'sonic electric toothbrush',
        description: 'High-frequency vibrations, 4 distinct cleaning modes, smart 2-minute timer, and induction travel charging case.',
        priceMinor: 599900, // PKR 5,999
        stockQuantity: 35,
        imageUrl: 'https://images.unsplash.com/photo-1553545985-1e0d8781d5db?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_care_03',
        categoryId: 'personal-care',
        name: 'Cold-Pressed Argan Hair Oil 100ml',
        normalizedName: 'cold-pressed argan hair oil 100ml',
        description: 'Pure Moroccan argan oil to nourish dry tips, tame frizz, and add silky natural shine without greasy residue.',
        priceMinor: 229900, // PKR 2,299
        stockQuantity: 40,
        imageUrl: 'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_care_04',
        categoryId: 'personal-care',
        name: 'Artisan Sandalwood Beard Care Kit',
        normalizedName: 'artisan sandalwood beard care kit',
        description: 'Includes sandalwood beard oil, conditioning balm, boar bristle brush, and hand-carved wooden comb.',
        priceMinor: 289900, // PKR 2,899
        stockQuantity: 20,
        imageUrl: 'https://images.unsplash.com/photo-1621607512214-68297480165e?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_care_05',
        categoryId: 'personal-care',
        name: 'Mineral Sunscreen SPF 50 Broad Spectrum',
        normalizedName: 'mineral sunscreen spf 50 broad spectrum',
        description: 'Non-greasy reef-safe zinc oxide sunscreen providing all-day broad spectrum UV protection with zero white cast.',
        priceMinor: 249900, // PKR 2,499
        stockQuantity: 50,
        imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80',
        isActive: true,
        isFeatured: true
      },
      {
        productId: 'prod_care_06',
        categoryId: 'personal-care',
        name: 'Exfoliating Arabica Coffee Body Scrub',
        normalizedName: 'exfoliating arabica coffee body scrub',
        description: 'Organic roast coffee grounds with sweet almond oil and sea salt for ultra-smooth skin rejuvenation.',
        priceMinor: 199900, // PKR 1,999
        stockQuantity: 45,
        imageUrl: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=800&q=80',
        isActive: true,
        isFeatured: false
      },
      {
        productId: 'prod_care_07',
        categoryId: 'personal-care',
        name: 'Aromatherapy Lavender Sleep Pillow Mist',
        normalizedName: 'aromatherapy lavender sleep pillow mist',
        description: 'Infused with French lavender and Roman chamomile essential oils to promote restorative, peaceful sleep.',
        priceMinor: 169900, // PKR 1,699
        stockQuantity: 35,
        imageUrl: 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=800&q=80',
        isActive: true,
        isFeatured: false
      }
    ];

    const batch = db.batch();

    // 1. Write categories
    for (const cat of categories) {
      const ref = db.collection('categories').doc(cat.categoryId);
      batch.set(ref, {
        ...cat,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    }

    // 2. Write products
    for (const prod of products) {
      const ref = db.collection('products').doc(prod.productId);
      batch.set(ref, {
        ...prod,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    }

    await batch.commit();

    return res.status(200).json({
      success: true,
      message: `Database successfully seeded with ${categories.length} categories and ${products.length} products.`,
      categoriesCount: categories.length,
      productsCount: products.length
    });

  } catch (error) {
    console.error('Seed execution error:', error);
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      error: error.message || 'Failed to seed database.',
      details: error.details || error.message
    });
  }
}
