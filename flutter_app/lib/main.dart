import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/providers.dart';
import 'services/api/admin_api_service.dart';
import 'services/api/api_client.dart';
import 'services/api/auth_api_service.dart';
import 'services/api/order_api_service.dart';
import 'services/auth/auth_service.dart';
import 'services/firestore/firestore_service.dart';
import 'services/local/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final localStorageService = await LocalStorageService.create();
  final authService = AuthService();
  final firestoreService = FirestoreService();

  final apiClient = ApiClient(authService: authService);
  final authApiService = AuthApiService(apiClient);
  final orderApiService = OrderApiService(apiClient);
  final adminApiService = AdminApiService(apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthApiService>.value(value: authApiService),
        Provider<OrderApiService>.value(value: orderApiService),
        Provider<AdminApiService>.value(value: adminApiService),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(localStorageService),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, firestoreService),
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(firestoreService),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, CatalogProvider, CartProvider>(
          create: (_) => CartProvider(firestoreService),
          update: (_, auth, catalog, cart) =>
              (cart ?? CartProvider(firestoreService))
                ..updateAuth(auth.uid, catalog),
        ),
        ChangeNotifierProvider(
          create: (_) => CheckoutProvider(orderApiService, localStorageService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(firestoreService, orderApiService),
          update: (_, auth, orders) =>
              (orders ?? OrderProvider(firestoreService, orderApiService))
                ..updateAuth(auth.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (_) => AdminProvider(firestoreService, adminApiService),
          update: (_, auth, admin) =>
              (admin ?? AdminProvider(firestoreService, adminApiService))
                ..updateAdminState(auth.isAdmin),
        ),
      ],
      child: const EcommerceApp(),
    ),
  );
}
