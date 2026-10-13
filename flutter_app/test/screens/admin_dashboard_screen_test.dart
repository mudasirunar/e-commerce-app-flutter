import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/order.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/admin_provider.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/screens/admin/admin_dashboard_screen.dart';

class MockAdminProvider extends ChangeNotifier implements AdminProvider {
  @override
  List<OrderModel> allOrders = [];

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCatalogProvider extends ChangeNotifier implements CatalogProvider {
  @override
  List<Product> allProducts = [];

  @override
  bool isLoading = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget buildTestableWidget({
  required MockAdminProvider admin,
  required MockCatalogProvider catalog,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AdminProvider>.value(value: admin),
      ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
    ],
    child: const MaterialApp(
      home: AdminDashboardScreen(),
    ),
  );
}

void main() {
  late MockAdminProvider mockAdmin;
  late MockCatalogProvider mockCatalog;

  setUp(() {
    mockAdmin = MockAdminProvider();
    mockCatalog = MockCatalogProvider();
  });

  testWidgets('AdminDashboardScreen renders executive revenue, bento cards, and modules', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final order1 = OrderModel(
      orderId: 'ord_1',
      userId: 'u1',
      deliveryName: 'Ahmed Ali',
      deliveryPhone: '03001234567',
      deliveryAddress: 'Karachi, Clifton',
      status: OrderStatus.pending,
      subtotalMinor: 500000,
      deliveryFeeMinor: 0,
      totalMinor: 500000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: const [],
    );

    final order2 = OrderModel(
      orderId: 'ord_2',
      userId: 'u2',
      deliveryName: 'Sara Khan',
      deliveryPhone: '03007654321',
      deliveryAddress: 'Lahore, DHA',
      status: OrderStatus.delivered,
      subtotalMinor: 300000,
      deliveryFeeMinor: 0,
      totalMinor: 300000,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now(),
      items: const [],
    );

    mockAdmin.allOrders = [order1, order2];

    const prod1 = Product(
      productId: 'p1',
      name: 'Leather Bag',
      description: 'Artisanal bag',
      priceMinor: 500000,
      stockQuantity: 2, // Low stock (< 5)
      categoryId: 'Bags',
      imageUrl: '',
      isActive: true,
    );

    const prod2 = Product(
      productId: 'p2',
      name: 'Silk Scarf',
      description: 'Handmade scarf',
      priceMinor: 300000,
      stockQuantity: 0, // Out of stock
      categoryId: 'Accessories',
      imageUrl: '',
      isActive: true,
    );

    mockCatalog.allProducts = [prod1, prod2];

    await tester.pumpWidget(buildTestableWidget(
      admin: mockAdmin,
      catalog: mockCatalog,
    ));
    await tester.pumpAndSettle();

    // 1. Executive GMV Revenue Card
    expect(find.text('Admin Operations'), findsOneWidget);
    expect(find.text('STORE VOLUME'), findsOneWidget);
    expect(find.text('Cash on Delivery'), findsOneWidget);

    // 2. Bento Grid Cards
    expect(find.text('Store Performance'), findsOneWidget);
    expect(find.text('Total Orders'), findsOneWidget);
    expect(find.text('Pending Action'), findsOneWidget);
    expect(find.text('Stock Alerts'), findsOneWidget);

    // Values in bento cards
    expect(find.text('2'), findsWidgets); // Total orders count

    // 3. Pipeline Distribution Card
    expect(find.text('Fulfillment Pipeline'), findsOneWidget);
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Delivered (1)'), findsOneWidget);

    // 4. Management Modules
    expect(find.text('Management Modules'), findsOneWidget);
    expect(find.text('Catalog & Inventory Management'), findsOneWidget);
    expect(find.text('Order Fulfillment & Lifecycle'), findsOneWidget);

    // 5. Recent Store Activity
    expect(find.text('Recent Store Activity'), findsOneWidget);
    expect(find.text('#ORD_1'), findsOneWidget);
    expect(find.text('#ORD_2'), findsOneWidget);
  });
}
