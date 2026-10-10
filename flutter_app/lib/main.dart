import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/providers.dart';
import 'services/auth/auth_service.dart';
import 'services/firestore/firestore_service.dart';
import 'services/local/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final localStorageService = await LocalStorageService.create();
  final authService = AuthService();
  final firestoreService = FirestoreService();

  runApp(
    MultiProvider(
      providers: [
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
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(firestoreService),
          update: (_, auth, orders) =>
              (orders ?? OrderProvider(firestoreService))
                ..updateAuth(auth.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (_) => AdminProvider(firestoreService),
          update: (_, auth, admin) =>
              (admin ?? AdminProvider(firestoreService))
                ..updateAdminState(auth.isAdmin),
        ),
      ],
      child: const EcommerceApp(),
    ),
  );
}
