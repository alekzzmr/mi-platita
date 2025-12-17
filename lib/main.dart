import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/transaction.dart';
import 'models/category.dart';
import 'providers/expense_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/category_provider.dart';
import 'providers/recurring_provider.dart';
import 'models/recurring_transaction.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(RecurringTransactionAdapter());
  Hive.registerAdapter(FrequencyAdapter());
  
  await Hive.openBox<Transaction>('transactions');
  // Categories box opened in provider init
  // We'll let provider open its own box or open it here
  await Hive.openBox('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..init()), 
        ChangeNotifierProvider(create: (context) => ExpenseProvider(
             Hive.box<Transaction>('transactions'),
           )..init()),
        ChangeNotifierProvider(create: (context) => RecurringProvider(
          Provider.of<ExpenseProvider>(context, listen: false)
        )..init()),
      ],
      child: const AppContent(),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    // We listen to SettingsProvider to rebuild app on language change if needed, 
    // although for simple string lookups inside widgets, just consuming it there is enough.
    // However, to change MaterialApp properties (like supportedLocales if we used formal l10n) we'd need it here.
    // For our simple AppStrings approach, we just need to ensure widgets rebuild.
    // We can wrap MaterialApp in a Consumer to trigger rebuild on language change.
    
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'MiPlatita',
          debugShowCheckedModeBanner: false,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00897B), // Teal - color del dinero
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
            // Light Theme Customizations
            scaffoldBackgroundColor: Colors.grey.shade100,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey.shade100,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: GoogleFonts.poppins(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00897B), // Teal - color del dinero
              brightness: Brightness.dark, 
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF121212),
              elevation: 0,
              centerTitle: false,
              titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
