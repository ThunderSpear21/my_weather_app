import 'package:flutter/material.dart';

class City {
  final String cityName;
  final double temperature;
  final String weatherInfo;
  final int? timezoneOffset;

  City({
    required this.cityName,
    required this.temperature,
    required this.weatherInfo,
    required this.timezoneOffset,
  });

  bool isDaytime() {
    if (timezoneOffset == null) {
      return false;
    }

    DateTime now = DateTime.now().toUtc().add(Duration(seconds: timezoneOffset!));
    int hour = now.hour;
    return hour > 6 && hour < 18;
  }

  Color getColorForTemperature() {
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
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'temperature': temperature,
      'weatherInfo': weatherInfo,
      'timezoneOffset': timezoneOffset,
    };
  }

  static City fromJson(Map<String, dynamic> json) {
    return City(
      cityName: json['cityName'],
      temperature: json['temperature'],
      weatherInfo: json['weatherInfo'],
      timezoneOffset: json['timezoneOffset'],
    );
  }
}
