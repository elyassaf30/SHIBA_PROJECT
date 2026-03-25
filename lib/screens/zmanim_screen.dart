import 'package:flutter/material.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class ZmanimScreen extends StatefulWidget {
  const ZmanimScreen({super.key});

  @override
  _ZmanimScreenState createState() => _ZmanimScreenState();
}

class _ZmanimScreenState extends State<ZmanimScreen> {
  ComplexZmanimCalendar? _zmanimCalendar;
  JewishCalendar? _jewishCalendar;
  HebrewDateFormatter? _hebrewFormatter;
  bool _isLoading = true;
  String? _errorMessage;
  String _locationName = '׳™׳©׳¨׳׳';

  @override
  void initState() {
    super.initState();
    _initializeZmanim();
  }

  Future<void> _initializeZmanim() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ׳ ׳¡׳” ׳׳§׳‘׳ ׳׳™׳§׳•׳ ׳׳“׳•׳™׳§, ׳׳—׳¨׳× ׳”׳©׳×׳׳© ׳‘׳׳™׳§׳•׳ ׳‘׳¨׳™׳¨׳× ׳׳—׳“׳ (׳™׳¨׳•׳©׳׳™׳)
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(Duration(seconds: 5));
          _locationName = '׳׳™׳§׳•׳ ׳ ׳•׳›׳—׳™';
        }
      } catch (e) {
        debugPrint('׳׳ ׳ ׳™׳×׳ ׳׳§׳‘׳ ׳׳™׳§׳•׳ ׳׳“׳•׳™׳§, ׳׳©׳×׳׳© ׳‘׳׳™׳§׳•׳ ׳‘׳¨׳™׳¨׳× ׳׳—׳“׳');
      }

      // ׳׳ ׳׳ ׳”׳¦׳׳—׳ ׳• ׳׳§׳‘׳ ׳׳™׳§׳•׳, ׳”׳©׳×׳׳© ׳‘׳™׳¨׳•׳©׳׳™׳ ׳›׳‘׳¨׳™׳¨׳× ׳׳—׳“׳
      final latitude = position?.latitude ?? 31.7683;
      final longitude = position?.longitude ?? 35.2137;

      GeoLocation geoLocation = GeoLocation.setLocation(
        _locationName,
        latitude,
        longitude,
        DateTime.now(),
      );

      setState(() {
        _zmanimCalendar = ComplexZmanimCalendar.intGeoLocation(geoLocation);
        _jewishCalendar = JewishCalendar();
        _jewishCalendar!.inIsrael = true;
        _hebrewFormatter = HebrewDateFormatter();
        _hebrewFormatter!.hebrewFormat = true;
        _hebrewFormatter!.useGershGershayim = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '׳©׳’׳™׳׳” ׳‘׳˜׳¢׳™׳ ׳× ׳–׳׳ ׳™׳: $e';
      });
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '׳׳ ׳–׳׳™׳';
    return DateFormat('HH:mm').format(time);
  }

  Widget _buildZmanCard({
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '׳–׳׳ ׳™ ׳”׳™׳•׳',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.deepPurple.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _initializeZmanim,
            tooltip: '׳¨׳¢׳ ׳ ׳–׳׳ ׳™׳',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9)],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        '׳˜׳•׳¢׳ ׳–׳׳ ׳™׳...',
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                    ],
                  ),
                )
                : _errorMessage != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red[300],
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _initializeZmanim,
                        child: Text('׳ ׳¡׳” ׳©׳•׳‘'),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _initializeZmanim,
                  child: ListView(
                    padding: EdgeInsets.only(top: 100, bottom: 16),
                    children: [
                      // ׳›׳•׳×׳¨׳× ׳×׳׳¨׳™׳ ׳¢׳‘׳¨׳™
                      if (_jewishCalendar != null && _hebrewFormatter != null)
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple,
                                Colors.deepPurple[700]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                _hebrewFormatter!.format(_jewishCalendar!),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _locationName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 8),

                      // ׳–׳׳ ׳™ ׳”׳™׳•׳
                      _buildZmanCard(
                        title: '׳¢׳׳•׳× ׳”׳©׳—׳¨',
                        time: _formatTime(_zmanimCalendar?.getAlos72()),
                        icon: Icons.nightlight_round,
                        color: Colors.indigo,
                        subtitle: '72 ׳“׳§׳•׳× ׳׳₪׳ ׳™ ׳”׳ ׳¥',
                      ),
                      _buildZmanCard(
                        title: '׳”׳ ׳¥ ׳”׳—׳׳”',
                        time: _formatTime(_zmanimCalendar?.getSunrise()),
                        icon: Icons.wb_sunny,
                        color: Colors.orange,
                      ),
                      _buildZmanCard(
                        title: '׳¡׳•׳£ ׳–׳׳ ׳§"׳© (׳’׳¨"׳)',
                        time: _formatTime(_zmanimCalendar?.getSofZmanShmaGRA()),
                        icon: Icons.menu_book,
                        color: Colors.blue[700]!,
                      ),
                      _buildZmanCard(
                        title: '׳¡׳•׳£ ׳–׳׳ ׳×׳₪׳™׳׳” (׳’׳¨"׳)',
                        time: _formatTime(
                          _zmanimCalendar?.getSofZmanTfilaGRA(),
                        ),
                        icon: Icons.access_time,
                        color: Colors.teal,
                      ),
                      _buildZmanCard(
                        title: '׳—׳¦׳•׳× ׳”׳™׳•׳',
                        time: _formatTime(_zmanimCalendar?.getChatzos()),
                        icon: Icons.wb_twilight,
                        color: Colors.amber[700]!,
                      ),
                      _buildZmanCard(
                        title: '׳׳ ׳—׳” ׳’׳“׳•׳׳”',
                        time: _formatTime(_zmanimCalendar?.getMinchaGedola()),
                        icon: Icons.wb_cloudy,
                        color: Colors.blue[600]!,
                      ),
                      _buildZmanCard(
                        title: '׳׳ ׳—׳” ׳§׳˜׳ ׳”',
                        time: _formatTime(_zmanimCalendar?.getMinchaKetana()),
                        icon: Icons.cloud,
                        color: Colors.lightBlue,
                      ),
                      _buildZmanCard(
                        title: '׳₪׳׳’ ׳”׳׳ ׳—׳”',
                        time: _formatTime(_zmanimCalendar?.getPlagHamincha()),
                        icon: Icons.cloud_queue,
                        color: Colors.cyan,
                      ),
                      _buildZmanCard(
                        title: '׳©׳§׳™׳¢׳”',
                        time: _formatTime(_zmanimCalendar?.getSunset()),
                        icon: Icons.wb_twilight,
                        color: Colors.deepOrange,
                      ),
                      _buildZmanCard(
                        title: '׳¦׳׳× ׳”׳›׳•׳›׳‘׳™׳',
                        time: _formatTime(_zmanimCalendar?.getTzais()),
                        icon: Icons.nights_stay,
                        color: Colors.indigo[900]!,
                        subtitle: '׳¡׳•׳£ ׳”׳©׳‘׳× ׳•׳”׳—׳’',
                      ),
                      _buildZmanCard(
                        title: '׳—׳¦׳•׳× ׳”׳׳™׳׳”',
                        time: _formatTime(_zmanimCalendar?.getSolarMidnight()),
                        icon: Icons.bedtime,
                        color: Colors.deepPurple[900]!,
                      ),

                      SizedBox(height: 16),

                      // ׳”׳¢׳¨׳”
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber[800]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '׳”׳–׳׳ ׳™׳ ׳׳—׳•׳©׳‘׳™׳ ׳׳₪׳™ ׳”׳׳™׳§׳•׳ ׳©׳׳',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

