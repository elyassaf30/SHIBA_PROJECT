import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // חובה בשביל jsonDecode/jsonEncode
import 'package:connectivity_plus/connectivity_plus.dart'; // עבור בדיקת חיבור אינטרנט

class UserToSynagogueMap extends StatefulWidget {
  @override
  _UserToSynagogueMapState createState() => _UserToSynagogueMapState();
}

class _UserToSynagogueMapState extends State<UserToSynagogueMap>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  LatLng? _currentLocation;
  Map<String, LatLng> _synagogueLocations = {};
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;
  String? _selectedSynagogue;
  BitmapDescriptor? _customMarkerIcon;
  GoogleMapController? _mapController;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    bool hasConnection = await _checkInternetConnection();
    if (!hasConnection) {
      setState(() {
        _loading = false;
      });
      _showErrorDialog("אין אינטרנט", "לא ניתן להתחבר לרשת.");
      return;
    }
    await _fetchSynagogueLocations();
    await _determinePosition();
  }

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _fetchSynagogueLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('synagogue_locations');
      final cachedTime = prefs.getInt('synagogue_locations_time');

      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (cachedData != null && cachedTime != null) {
        final difference = currentTime - cachedTime;
        if (difference < 3600000) {
          // פחות משעה (3600 שניות * 1000 מילי שניות)
          // יש קאש תקין - טוען מהקאש
          final List<dynamic> data = jsonDecode(cachedData);

          setState(() {
            _synagogueLocations = {
              for (var item in data)
                item['שם הבית כנסת'] as String: LatLng(
                  (item['אורך'] as double).toDouble(),
                  (item['רוחב'] as double).toDouble(),
                ),
            };
            if (_synagogueLocations.isNotEmpty) {
              _selectedSynagogue = _synagogueLocations.keys.first;
            }
          });
          return;
        }
      }

      // אין קאש תקין או שעברה שעה - טוען מחדש מהשרת
      final response = await supabase
          .from('בתי כנסת')
          .select('"שם הבית כנסת", "אורך", "רוחב"');

      if (response.isEmpty) {
        setState(() {
          _loading = false;
          _synagogueLocations = {}; // אם אין נתונים, הצג רק את המיקום של המשתמש
        });
        return;
      }

      final data = response as List<dynamic>;

      setState(() {
        _synagogueLocations = {
          for (var item in data)
            item['שם הבית כנסת'] as String: LatLng(
              (item['אורך'] as double).toDouble(),
              (item['רוחב'] as double).toDouble(),
            ),
        };
        if (_synagogueLocations.isNotEmpty) {
          _selectedSynagogue = _synagogueLocations.keys.first;
        }
      });

      // שמירה לקאש
      await prefs.setString('synagogue_locations', jsonEncode(data));
      await prefs.setInt('synagogue_locations_time', currentTime);
    } catch (e) {
      print('Exception fetching synagogues: $e');
      setState(() {
        _loading = false;
        _synagogueLocations =
            {}; // אם לא הצלחנו לטעון את הנתונים מהשרת, נציג רק את המיקום של המשתמש
      });
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _showLocationServiceError();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          return _showLocationPermissionError();
      }

      if (permission == LocationPermission.deniedForever)
        return _showLocationPermissionError();

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _setMarkersAndRoute();
        _loading = false;
      });
      _animationController.forward();

      // Zoom to show both user location and synagogues
      if (_mapController != null &&
          _currentLocation != null &&
          _synagogueLocations.isNotEmpty) {
        final bounds = _getBounds(
          _currentLocation!,
          _synagogueLocations.values.toList(),
        );
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      _showLocationError();
    }
  }

  LatLngBounds _getBounds(
    LatLng userLocation,
    List<LatLng> synagogueLocations,
  ) {
    double? west, south, east, north;

    // Include user location in bounds
    west = userLocation.longitude;
    east = userLocation.longitude;
    north = userLocation.latitude;
    south = userLocation.latitude;

    // Include all synagogue locations
    for (var location in synagogueLocations) {
      if (west == null || location.longitude < west) west = location.longitude;
      if (east == null || location.longitude > east) east = location.longitude;
      if (south == null || location.latitude < south) south = location.latitude;
      if (north == null || location.latitude > north) north = location.latitude;
    }

    return LatLngBounds(
      northeast: LatLng(north!, east!),
      southwest: LatLng(south!, west!),
    );
  }

  Future<void> _setMarkersAndRoute({String? selectedSynagogue}) async {
    if (_currentLocation == null || _synagogueLocations.isEmpty) return;

    setState(() {
      if (selectedSynagogue != null) {
        _selectedSynagogue = selectedSynagogue;
      }
    });

    // Create markers for all synagogues
    _markers =
        _synagogueLocations.entries.map((entry) {
          return Marker(
            markerId: MarkerId(entry.key),
            position: entry.value,
            infoWindow: InfoWindow(title: entry.key),
            icon:
                _customMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  entry.key == _selectedSynagogue
                      ? BitmapDescriptor.hueGreen
                      : BitmapDescriptor.hueRed,
                ),
            onTap: () {
              _setMarkersAndRoute(selectedSynagogue: entry.key);
            },
          );
        }).toSet();

    // Add user location marker
    _markers.add(
      Marker(
        markerId: MarkerId('current_location'),
        position: _currentLocation!,
        infoWindow: InfoWindow(title: 'המיקום שלי'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Clear previous polylines
    _polylines.clear();

    // Create route to selected synagogue
    if (_selectedSynagogue != null &&
        _synagogueLocations.containsKey(_selectedSynagogue)) {
      final synagogueLocation = _synagogueLocations[_selectedSynagogue]!;

      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyCnSxJ2tY3gEzotimAUACpW1qFE7h4_6EM', // השתמש במפתח API שלך
        PointLatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        PointLatLng(synagogueLocation.latitude, synagogueLocation.longitude),
        travelMode: TravelMode.walking,
      );

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates =
            result.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();

        _polylines.add(
          Polyline(
            polylineId: PolylineId(_selectedSynagogue!),
            points: polylineCoordinates,
            color: Colors.deepPurple,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
          ),
        );

        // Zoom to show route
        if (_mapController != null) {
          final bounds = _getBounds(_currentLocation!, [synagogueLocation]);
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        }
      }
    }

    setState(() {});
  }

  void _showLocationServiceError() {
    _showErrorDialog(
      'שירות המיקום מנוטרל',
      'אנא הפעל את שירות המיקום בהגדרות המכשיר',
    );
  }

  void _showLocationPermissionError() {
    _showErrorDialog(
      'הרשאות מיקום נדרשות',
      'אנא אשר הרשאות מיקום כדי להשתמש בתכונה זו',
    );
  }

  void _showLocationError() {
    _showErrorDialog('שגיאה במיקום', 'לא ניתן לקבוע את המיקום הנוכחי');
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('אישור'),
              ),
            ],
          ),
    );
  }

  Widget _buildBackground() {
    // רקע חלופי אם יש בעיה עם התמונה
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9)],
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
          'בתי כנסת במרכז הרפואי',
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
              colors: [Colors.deepPurple.withOpacity(0.8), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          // עיגול טעינה שמופיע עד שהמפה נטענת
          if (_loading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                SizedBox(height: 100),
                // Dropdown to select synagogue
                if (_synagogueLocations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: DropdownButton<String>(
                          value: _selectedSynagogue,
                          isExpanded: true,
                          underline: SizedBox(),
                          items:
                              _synagogueLocations.keys.map((String synagogue) {
                                return DropdownMenuItem<String>(
                                  value: synagogue,
                                  child: Text(synagogue),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSynagogue = value;
                              _setMarkersAndRoute(selectedSynagogue: value);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                // Google Map Widget
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation ?? LatLng(31.768319, 35.213711),
                      zoom: 15,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
