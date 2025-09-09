import 'package:eafoods/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database
  await DatabaseService.init();

  runApp(const EAFoodsApp());
}

class EAFoodsApp extends StatelessWidget {
  const EAFoodsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'EA Foods - Pre-Order System',
        theme: ThemeData(
          colorSchemeSeed: kprimarycolor,
          scaffoldBackgroundColor: kbgcolor,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: kbgcolor,
            foregroundColor: kprimarycolor,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shadowColor: Color(0x409e9e9e),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
