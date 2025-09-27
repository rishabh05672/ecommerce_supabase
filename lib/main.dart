import 'package:ecommerce_supabse/provider/auth_provider.dart';
import 'package:ecommerce_supabse/provider/category_provider.dart';
import 'package:ecommerce_supabse/provider/dashboard_provider.dart';
import 'package:ecommerce_supabse/provider/order_provider.dart';
import 'package:ecommerce_supabse/provider/product_provider.dart';
import 'package:ecommerce_supabse/screen/add_category_screen.dart';
import 'package:ecommerce_supabse/screen/add_product_screen.dart';
import 'package:ecommerce_supabse/screen/categories_screen.dart';
import 'package:ecommerce_supabse/screen/dashboard_screen.dart';
import 'package:ecommerce_supabse/screen/login_screen.dart';
import 'package:ecommerce_supabse/screen/order_screen.dart';
import 'package:ecommerce_supabse/screen/product_screen.dart';
import 'package:ecommerce_supabse/screen/signup_screen.dart';
import 'package:ecommerce_supabse/screen/splash_screen.dart';
import 'package:ecommerce_supabse/utils/constants/supabase_key.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Ecommerce Admin',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: SplashScreen(),
            routes: {
              '/login': (context) => LoginScreen(),
              '/signup': (context) => SignupScreen(),
              '/dashboard': (context) => DashboardScreen(),
              '/products': (context) => ProductsScreen(),
              '/add-product': (context) => AddProductScreen(),
              '/categories': (context) => CategoriesScreen(),
              '/add-category': (context) => AddCategoryScreen(),
              '/orders': (context) => OrdersScreen(),
            },
          );
        },
      ),
    );
  }
}
