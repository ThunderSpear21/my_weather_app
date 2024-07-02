import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../keys/open_weather_api.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favoriteCities = []; // Replace with your actual API key

  @override
  void initState() {
    super.initState();
    _loadFavoriteCities(); // Load favorite cities on app start
  }

  Future<void> _loadFavoriteCities() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCities = prefs.getStringList('favoriteCities') ?? [];

    setState(() {
      favoriteCities = storedCities
          .map((cityJson) => jsonDecode(cityJson) as Map<String, dynamic>)
          .toList();
    });

    // Fetch weather for loaded favorite cities
    for (var city in favoriteCities) {
      await _fetchWeather(city['cityName'], initialLoad: true);
    }
  }

  Future<void> _saveFavoriteCities() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> citiesJson =
        favoriteCities.map((city) => jsonEncode(city)).toList();
    await prefs.setStringList('favoriteCities', citiesJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Cities'),
      ),
      body: SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: favoriteCities.length,
          itemBuilder: (context, index) {
            return _buildCityCard(favoriteCities[index], index);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCityDialog();
        },
        tooltip: 'Add City',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _fetchWeather(String cityName, {bool initialLoad = false}) async {
    // Check if the city already exists in the favoriteCities list
    if (!initialLoad && favoriteCities.any((city) => city['cityName'].toLowerCase() == cityName.toLowerCase())) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('City Already Added'),
            content: const Text('This city is already in your favorites.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$weatherApiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final weatherData = jsonDecode(response.body);
      final weatherInfo = 'Temperature: ${weatherData['main']['temp']}°C\n'
          'Weather: ${weatherData['weather'][0]['description']}';
      final countryName = weatherData['sys']['country']; // Extract the country name

      // Extract city coordinates
      final double lat = weatherData['coord']['lat'];
      final double lon = weatherData['coord']['lon'];

      // Fetch timezone offset using OpenWeatherMap's timezone endpoint
      final timezoneOffset = await _getTimezoneOffset(lat, lon);

      if (!initialLoad) {
        setState(() {
          favoriteCities.add({
            'cityName': '$cityName, $countryName', // Append the country name to the city name
            'weatherInfo': weatherInfo,
            'timezone': timezoneOffset,
          });
          _removeDuplicateCities(); // Remove duplicates after adding a new city
        });

        await _saveFavoriteCities(); // Save updated list of favorite cities
      }
    } else {
      if (!initialLoad) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('City Not Found'),
              content: const Text('Please enter a valid city name.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<int?> _getTimezoneOffset(double lat, double lon) async {
    final timezoneUrl =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$weatherApiKey';

    final response = await http.get(Uri.parse(timezoneUrl));

    if (response.statusCode == 200) {
      final timezoneData = jsonDecode(response.body)['timezone'];
      return timezoneData;
    } else {
      // Handle error case where timezone data cannot be fetched
      return null;
    }
  }

  void _showAddCityDialog() {
    TextEditingController _addCitySearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Add City',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _addCitySearchController,
            decoration: InputDecoration(
              hintText: 'Enter city name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('ADD'),
              onPressed: () {
                if (_addCitySearchController.text.isNotEmpty) {
                  _fetchWeather(_addCitySearchController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _removeCity(int index) {
    setState(() {
      favoriteCities.removeAt(index);
    });
    _saveFavoriteCities(); // Save updated list of favorite cities
  }

  Widget _buildCityCard(Map<String, dynamic> cityData, int index) {
    // Determine day or night based on current time of the city
    bool isDay = _isDaytime(cityData['timezone']);

    // Extract temperature from weatherInfo
    RegExp regex = RegExp(r'Temperature: ([-+]?\d*\.?\d*)');
    String? temperatureString =
        regex.firstMatch(cityData['weatherInfo'])?.group(1);
    double temperature =
        temperatureString != null ? double.parse(temperatureString) : 0.0;

    // Determine background color for temperature visualization
    Color tempColor = _getColorForTemperature(cityData['weatherInfo']);

    // Use a stable key combining cityName and index
    Key dismissibleKey = Key('${cityData['cityName']}_$index');

    return Dismissible(
      key: dismissibleKey,
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeCity(index);
      },
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: AlignmentDirectional.centerEnd,
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Card(
        elevation: 4.0,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Container(
          height: 100.0, // Adjust the height as needed
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            gradient: LinearGradient(
              colors: [
                isDay ? Colors.blue.shade200 : Colors.indigo.shade400,
                tempColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              // Left side: Day or Night indicator
              Container(
                width: 50.0,
                height: double.infinity,
                decoration: BoxDecoration(
                  color:
                      isDay ? Colors.yellow.shade700 : Colors.blueGrey.shade800,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0),
                  ),
                ),
                child: Center(
                  child: Icon(
                    isDay ? Icons.wb_sunny : Icons.nightlight_round,
                    color: Colors.white,
                  ),
                ),
              ),
              // Right side: City name and additional information
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cityData['cityName'],
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$temperature°C',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        cityData['weatherInfo'],
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDaytime(int? timezoneOffset) {
    if (timezoneOffset == null) {
      // Handle case where timezoneOffset is null
      return false; // Default to false or handle as needed
    }

    // Get the current time in UTC and adjust it by the city's timezone offset
    DateTime now =
        DateTime.now().toUtc().add(Duration(seconds: timezoneOffset));
    int hour = now.hour;

    // Adjust these thresholds based on your preference
    return hour > 6 && hour < 18;
  }

  Color _getColorForTemperature(String weatherInfo) {
    // Extract temperature from weatherInfo
    RegExp regex = RegExp(r'Temperature: ([-+]?\d*\.?\d*)');
    String? temperatureString = regex.firstMatch(weatherInfo)?.group(1);

    if (temperatureString != null) {
      double temperature = double.parse(temperatureString);

      // Adjust these thresholds based on your preference
      if (temperature < 0) {
        return Colors.blue.shade900;
      } else if (temperature < 10) {
        return Colors.blue.shade700;
      } else if (temperature < 20) {
        return Colors.blue.shade500;
      } else if (temperature < 30) {
        return Colors.orange;
      } else if (temperature < 40) {
        return Colors.orange.shade700;
      } else {
        return Colors.red;
      }
    } else {
      // Handle case where temperature string is null (error case)
      return Colors.grey; // Placeholder color or handle error gracefully
    }
  }

  // Function to remove duplicate cities
  void _removeDuplicateCities() {
    final uniqueCities = <String>{};
    final uniqueFavoriteCities = <Map<String, dynamic>>[];

    for (var city in favoriteCities) {
      if (uniqueCities.add(city['cityName'].toLowerCase())) {
        uniqueFavoriteCities.add(city);
      }
    }

    setState(() {
      favoriteCities = uniqueFavoriteCities;
    });
    _saveFavoriteCities();
  }
}
