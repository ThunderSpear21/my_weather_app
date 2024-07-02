import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../keys/open_weather_api.dart';

class WeatherService { // Replace with your OpenWeatherMap API Key

  static Future<String> fetchWeather(LatLng latlng) async {
    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=${latlng.latitude}&lon=${latlng.longitude}&appid=$weatherApiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final weatherData = jsonDecode(response.body);
      return 'Temperature: ${weatherData['main']['temp']}°C\nWeather: ${weatherData['weather'][0]['description']}';
    } else {
      return 'Failed to load weather data';
    }
  }
}
