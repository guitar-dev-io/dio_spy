import 'package:dio/dio.dart';
import 'package:net_spy/net_spy.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final NetSpy _netSpy;
  late final Dio _dio;
  late final ApiService _apiService;
  // final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initializeDio();
  }

  void _initializeDio() {
    // Initialize NetSpy with shake gesture enabled
    _netSpy = NetSpy(
      showOnShake: true,
      maxCalls: 1000,
      persistent: true, // keep captured calls after app restart
      retentionPeriod: const Duration(hours: 12), // auto-prune old calls
      title: 'NetSpy Example', // override the inspector title
      redactHeaders: false, // start with redaction off (toggle in the menu)
      // enabled defaults to kDebugMode, so NetSpy is off in release builds.
    );

    // Set the navigator key (required for NetSpy to work)
    // _netSpy.setNavigatorKey(_navigatorKey);

    // Initialize Dio with interceptors
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Attach NetSpy to Dio (one-liner). Equivalent to:
    // _dio.interceptors.add(_netSpy.interceptor);
    _netSpy.attachTo(_dio);

    // Optional: Add logging interceptor for console output
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );

    // Initialize API service
    _apiService = ApiService(_dio);
  }

  @override
  void dispose() {
    _netSpy.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetSpy Example',
      // navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      // Uncomment this if you want to use NetSpyWrapper instead of navigatorKey
      builder: (context, child) => NetSpyWrapper(
        netSpy: _netSpy,
        child: child ?? const SizedBox.shrink(),
      ),
      home: HomeScreen(apiService: _apiService),
      debugShowCheckedModeBanner: false,
    );
  }
}
