import 'package:flutter/material.dart';
import 'screens/weather_map_screen.dart';
import 'screens/favorites_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WeatherMapScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/favorites': (context) => FavoritesScreen(), // Define route
      },
    );
  }
}
