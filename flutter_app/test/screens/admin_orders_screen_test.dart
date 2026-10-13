import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/order.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/admin_provider.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/screens/admin/admin_orders_screen.dart';

class MockAdminProvider extends ChangeNotifier implements AdminProvider {
  @override
  List<OrderModel> allOrders = [];

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  String? updatedOrderId;
  String? updatedStatus;

  @override
  Future<bool> updateOrderStatus(String orderId, String newStatus, {String? note}) async {
    updatedOrderId = orderId;
    updatedStatus = newStatus;
    return true;
  }

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

Widget buildTestableOrdersWidget({
  required MockAdminProvider admin,
  required MockCatalogProvider catalog,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AdminProvider>.value(value: admin),
      ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
    ],
    child: const MaterialApp(
      home: AdminOrdersScreen(),
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

  testWidgets('AdminOrdersScreen renders search, tick-free tabs with counts, and order cards', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final order1 = OrderModel(
      orderId: 'ord_123',
      userId: 'u1',
      deliveryName: 'Ahmed Ali',
      deliveryPhone: '03001234567',
      deliveryAddress: 'Karachi, Clifton',
      status: OrderStatus.pending,
      subtotalMinor: 450000,
      deliveryFeeMinor: 0,
      totalMinor: 450000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: const [
        OrderItemSnapshot(
          productId: 'p1',
          nameSnapshot: 'Leather Bag',
          unitPriceMinorSnapshot: 450000,
          quantity: 2,
        ),
      ],
    );

    mockAdmin.allOrders = [order1];

    await tester.pumpWidget(buildTestableOrdersWidget(
      admin: mockAdmin,
      catalog: mockCatalog,
    ));
    await tester.pumpAndSettle();

    // 1. App Bar and Search
    expect(find.text('Orders Management'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // 2. ChoiceChips without checkmarks showing counts
    expect(find.text('All (1)'), findsOneWidget);
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Processing (0)'), findsOneWidget);

    final choiceChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All (1)'));
    expect(choiceChip.showCheckmark, false);

    // 3. Order Card details
    expect(find.text('#ORD_123'), findsOneWidget);
    expect(find.text('Ahmed Ali • 03001234567'), findsOneWidget);
    expect(find.text('Karachi, Clifton'), findsOneWidget);
    expect(find.text('2 items • COD'), findsOneWidget);
    expect(find.text('x2'), findsOneWidget); // Thumbnail quantity badge

    // 4. Status Advancement Buttons
    expect(find.text('Move status to:'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);

    // 5. Search filtering
    await tester.enterText(find.byType(TextField), 'NonExistent');
    await tester.pumpAndSettle();
    expect(find.text('No Orders Found'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ahmed');
    await tester.pumpAndSettle();
    expect(find.text('#ORD_123'), findsOneWidget);
  });
}
