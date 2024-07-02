import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../widgets/weather_info_card.dart';
import '../widgets/map_widget.dart';

class WeatherMapScreen extends StatefulWidget {
  @override
  _WeatherMapScreenState createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends State<WeatherMapScreen> {
  LatLng selectedLocation = LatLng(28.6139, 77.2090); // Default to Delhi
  String weatherInfo = 'Tap on a location to see the weather';
  String regionName = ''; // To store the region name
  bool isLoading = false; // For loading indicator
  final MapController _mapController = MapController(); // Map controller

  void _onTap(LatLng latlng) async {
    setState(() {
      selectedLocation = latlng;
      weatherInfo = 'Loading weather data...';
      regionName = ''; // Reset region name while loading
      isLoading = true; // Start loading indicator
    });

    final fetchedRegionName = await LocationService.getRegionName(latlng);
    setState(() {
      regionName = fetchedRegionName;
    });

    final fetchedWeatherInfo = await WeatherService.fetchWeather(latlng);
    setState(() {
      weatherInfo = fetchedWeatherInfo;
      isLoading = false; // Stop loading indicator
    });
  }

  Future<void> _locateMe() async {
    setState(() {
      isLoading = true; // Start loading indicator
    });

    final currentLocation = await LocationService.locateMe();
    if (currentLocation != null) {
      _mapController.move(currentLocation, 10.0);
      _onTap(currentLocation);
    } else {
      setState(() {
        weatherInfo = 'Failed to locate.';
        isLoading = false; // Stop loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor, // Use accent color from the theme
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Weather Map',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: WeatherInfoCard(
                  regionName: regionName,
                  weatherInfo: weatherInfo,
                  isLoading: isLoading,
                ),
              ),
              Expanded(
                child: MapWidget(
                  mapController: _mapController,
                  selectedLocation: selectedLocation,
                  onTap: _onTap,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 80.0,
            right: 16.0,
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 14, 165, 199),
              onPressed: () {
                Navigator.pushNamed(context, '/favorites'); // Navigate to FavoritesScreen
              },
              tooltip: 'My Cities',
              child: const Icon(Icons.add_box),
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              backgroundColor: Colors.orangeAccent,
              onPressed: _locateMe,
              tooltip: 'Locate Me',
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
