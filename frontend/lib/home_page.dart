import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_service.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _recentCities = [];
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _cityController = TextEditingController(
    text: 'Delhi',
  );

  Map<String, dynamic>? weatherData;
  bool isloading = false;
  String? errorMessage;
  bool _isCelsius = true;

  // static const Color _background = Color(0xFFF5F6FC);
  static const Color _purple = Color(0xFF6256D9);
  static const Color _darkPurple = Color(0xFF393078);

  @override
  void initState() {
    super.initState();
    _searchWeather();
    _loadRecentCities();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentCities() async {
    final prefs = await SharedPreferences.getInstance();
    final cities = prefs.getStringList('recentCities') ?? [];

    if (!mounted) return;

    setState(() {
      _recentCities = cities;
    });
  }

  Future<void> _saveRecentCity(String city) async {
    final name = city.trim();

    if (name.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final updatedCities = [
      name,
      ..._recentCities.where(
        (item) => item.toLowerCase() != name.toLowerCase(),
      ),
    ].take(8).toList();

    await prefs.setStringList('recentCities', updatedCities);

    if (!mounted) return;

    setState(() {
      _recentCities = updatedCities;
    });
  }

  Future<void> _searchWeather() async {
    if (!mounted) return;

    setState(() {
      isloading = true;
      errorMessage = null;
    });
    await _saveRecentCity(_cityController.text.trim());

    try {
      Map<String, dynamic>? result;
      Object? lastError;

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          result = await _weatherService
              .getWeather(_cityController.text.trim())
              .timeout(const Duration(seconds: 20));

          break;
        } catch (e) {
          lastError = e;

          if (attempt == 0) {
            await Future.delayed(const Duration(milliseconds: 800));
          }
        }
      }

      if (result == null) {
        throw Exception(lastError ?? 'Weather unavailable');
      }

      if (!mounted) return;

      setState(() {
        weatherData = result;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint('Weather loading error: $e');

      if (!mounted) return;

      setState(() {
        errorMessage =
            'Weather load unavailable. Please try again. or check the internet';
        weatherData = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          isloading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocationWeather() async {
    if (isloading || !mounted) return;

    setState(() {
      isloading = true;
      errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please enable location services on your device.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission required. Please allow it in app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      final result = await _weatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        weatherData = result;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint('Current location error: $e');

      if (!mounted) return;

      setState(() {
        weatherData = null;
        errorMessage = 'Could not get your location weather. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isloading = false;
        });
      }
    }
  }

  String _formatTemp(dynamic value) {
    final celsius = double.tryParse(value.toString());

    if (celsius == null) return '--°';

    final temperature = _isCelsius ? celsius : (celsius * 9 / 5) + 32;

    return '${temperature.round()}°${_isCelsius ? 'C' : 'F'}';
  }

  String _iconUrl(dynamic icon) {
    final path = icon?.toString() ?? '';
    if (path.isEmpty) return '';
    return path.startsWith('//') ? 'https:$path' : path;
  }

  Widget _weatherIcon(dynamic icon, {double size = 48}) {
    final url = _iconUrl(icon);

    if (url.isEmpty) {
      return Icon(Icons.cloud_rounded, size: size, color: _purple);
    }

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.cloud_rounded, size: size, color: _purple),
    );
  }

  String _hourLabel(dynamic time) {
    if (time == null) return '--';
    try {
      final date = DateTime.parse(time.toString());
      final hour = date.hour;
      final suffix = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour $suffix';
    } catch (_) {
      return time.toString();
    }
  }

  String _weekday(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      final date = DateTime.parse(dateValue.toString());
      const names = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return names[date.weekday - 1];
    } catch (_) {
      return dateValue.toString();
    }
  }

  String _shortDate(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      final date = DateTime.parse(dateValue.toString());
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return dateValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = weatherData?['location'] as Map<String, dynamic>?;
    final current = weatherData?['current'] as Map<String, dynamic>?;
    final condition = current?['condition'] as Map<String, dynamic>?;
    final forecast = weatherData?['forecast'] as List<dynamic>? ?? [];
    final weatherText = (condition?['text'] ?? '').toString().toLowerCase();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final weatherGradient =
        weatherText.contains('rain') ||
            weatherText.contains('drizzle') ||
            weatherText.contains('thunder')
        ? const [Color(0xFF35658D), Color(0xFF263B63)]
        : weatherText.contains('sun') || weatherText.contains('clear')
        ? const [Color(0xFFFFB75E), Color(0xFFED6A5A)]
        : weatherText.contains('snow') || weatherText.contains('ice')
        ? const [Color(0xFF83C5E8), Color(0xFF5776A8)]
        : const [Color(0xFF7B8DA8), Color(0xFF515D79)];

    final firstDay = forecast.isNotEmpty
        ? forecast.first as Map<String, dynamic>
        : null;

    final allHours = firstDay?['hour'] as List<dynamic>? ?? [];

    // Show the next eight hours, starting near the current local time.
    var startIndex = 0;
    final localTime = location?['localtime']?.toString();

    if (localTime != null) {
      try {
        final now = DateTime.parse(localTime);
        startIndex = allHours.indexWhere((hour) {
          final time = DateTime.tryParse(hour['time'].toString());
          return time != null && !time.isBefore(now);
        });
        if (startIndex < 0) startIndex = 0;
      } catch (_) {
        startIndex = 0;
      }
    }

    final hourly = allHours.skip(startIndex).take(8).toList();
    final cardColor = Theme.of(context).colorScheme.surface;
    // final textColor = Theme.of(context).colorScheme.onSurface;
    final secondaryTextColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_cloudy_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 27,
            ),
            const SizedBox(width: 9),
            Text(
              'SkyCast',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh weather',
            onPressed: isloading ? null : _searchWeather,
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          IconButton(
            tooltip: 'Use my current location',
            onPressed: isloading ? null : _getCurrentLocationWeather,
            icon: Icon(
              Icons.my_location_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isCelsius = !_isCelsius;
              });
            },
            child: Text(
              _isCelsius ? '°C' : '°F',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              appThemeMode.value = appThemeMode.value == ThemeMode.light
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
            icon: Icon(
              appThemeMode.value == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // City search
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _darkPurple.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _cityController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchWeather(),
                  decoration: InputDecoration(
                    hintText: 'Search city, e.g. Delhi',
                    hintStyle: TextStyle(color: secondaryTextColor),
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      onPressed: isloading ? null : _searchWeather,
                      icon: Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 17,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              if (_recentCities.isNotEmpty) ...[
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('recentCities');

                        if (!mounted) return;

                        setState(() {
                          _recentCities = [];
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recentCities.map((city) {
                    return ActionChip(
                      avatar: const Icon(Icons.history_rounded, size: 18),
                      label: Text(city),
                      onPressed: () {
                        _cityController.text = city;
                        _searchWeather();
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 22),

              if (isloading && weatherData == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: _purple),
                  ),
                )
              else if (errorMessage != null && weatherData == null)
                _errorCard()
              else if (current != null) ...[
                // Current weather hero card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(23),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              weatherGradient.first.withValues(alpha: 0.8),
                              const Color(0xFF171725),
                            ]
                          : weatherGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _purple.withValues(alpha: 0.25),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              location?['name']?.toString() ?? 'Unknown city',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isloading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [location?['region'], location?['country']]
                            .where(
                              (value) =>
                                  value != null && value.toString().isNotEmpty,
                            )
                            .join(', '),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatTemp(current['temp_c']),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 68,
                                    height: 1.0,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  condition?['text']?.toString() ??
                                      'Weather unavailable',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (firstDay != null)
                                  Text(
                                    'H: ${_formatTemp(firstDay['day']['maxtemp_c'])}L: ${_formatTemp(firstDay['day']['mintemp_c'])}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _weatherIcon(condition?['icon'], size: 112),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _heroStat(
                                Icons.water_drop_rounded,
                                'Humidity',
                                '${current['humidity']}%',
                              ),
                            ),
                            Expanded(
                              child: _heroStat(
                                Icons.air_rounded,
                                'Wind',
                                '${current['wind_kph']} km/h',
                              ),
                            ),
                            Expanded(
                              child: _heroStat(
                                Icons.thermostat_rounded,
                                'Feels like',
                                _formatTemp(current['feelslike_c']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Hourly forecast
                _sectionTitle('Hourly Forecast', subtitle: 'Coming hours'),
                const SizedBox(height: 13),
                if (hourly.isEmpty)
                  _smallMessage('Hourly forecast is not available.')
                else
                  SizedBox(
                    height: 153,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: hourly.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 11),
                      itemBuilder: (context, index) {
                        final hour = hourly[index] as Map<String, dynamic>;
                        final hourCondition =
                            hour['condition'] as Map<String, dynamic>?;

                        return Container(
                          width: 91,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(
                              color: _purple.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _hourLabel(hour['time']),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              _weatherIcon(hourCondition?['icon'], size: 42),
                              Text(
                                _formatTemp(hour['temp_c']),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _darkPurple,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.water_drop,
                                    size: 12,
                                    color: _purple,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${hour['chance_of_rain'] ?? 0}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 28),

                // Extra weather details
                _sectionTitle('Weather Details', subtitle: 'Right now'),
                const SizedBox(height: 13),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.65,
                  children: [
                    _detailCard(
                      Icons.compress_rounded,
                      'Pressure',
                      '${current['pressure_mb']} hPa',
                    ),
                    _detailCard(
                      Icons.visibility_outlined,
                      'Visibility',
                      '${current['vis_km']} km',
                    ),
                    _detailCard(
                      Icons.wb_sunny_outlined,
                      'UV Index',
                      '${current['uv']}',
                    ),
                    _detailCard(
                      Icons.cloud_outlined,
                      'Cloud Cover',
                      '${current['cloud']}%',
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Three-day forecast
                _sectionTitle('3-Day Forecast', subtitle: 'Plan ahead'),
                const SizedBox(height: 13),
                if (forecast.isEmpty)
                  _smallMessage('Daily forecast is not available.')
                else
                  ...forecast.map((item) {
                    final dayData = item as Map<String, dynamic>;
                    final day = dayData['day'] as Map<String, dynamic>;
                    final dayCondition =
                        day['condition'] as Map<String, dynamic>?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 11),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _purple.withValues(alpha: 0.07),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _weekday(dayData['date']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _darkPurple,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _shortDate(dayData['date']),
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _weatherIcon(dayCondition?['icon'], size: 46),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dayCondition?['text']?.toString() ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTemp(day['maxtemp_c']),
                            style: const TextStyle(
                              fontSize: 16,
                              color: _darkPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            '${day['mintemp_c']}°',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Refresh failed: $errorMessage',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ] else
                _errorCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _heroStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 23),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _detailCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _purple, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _darkPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: _purple, size: 54),
          const SizedBox(height: 12),
          const Text(
            'Weather unavailable',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: _darkPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Please check the city name and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 17),
          FilledButton.icon(
            onPressed: isloading ? null : _searchWeather,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: FilledButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message, style: const TextStyle(color: Colors.black54)),
    );
  }
}
