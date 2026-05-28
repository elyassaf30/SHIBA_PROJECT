import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';
import 'package:rabbi_shiba/utils/app_colors.dart';
import 'package:rabbi_shiba/services/map_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UserToSynagogueMap extends StatefulWidget {
  const UserToSynagogueMap({super.key});

  @override
  State<UserToSynagogueMap> createState() => _UserToSynagogueMapState();
}

class _UserToSynagogueMapState extends State<UserToSynagogueMap>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  LatLng? _currentLocation;
  Map<String, LatLng> _synagogueLocations = {};
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _loading = true;
  String? _selectedSynagogue;
  GoogleMapController? _mapController;
  bool _routeLoading = false;
  OsrmRouteResult? _routeInfo;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    final hasConnection = await _checkInternetConnection();
    if (!hasConnection) {
      setState(() => _loading = false);
      _showErrorDialog('אין אינטרנט', 'לא ניתן להתחבר לרשת.');
      return;
    }
    await _fetchSynagogueLocations();
    await _determinePosition();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  Future<void> _fetchSynagogueLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('synagogue_locations');
      final cachedTime = prefs.getInt('synagogue_locations_time');
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (cachedData != null && cachedTime != null) {
        if (currentTime - cachedTime < 3600000) {
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

      final response = await supabase
          .from('בתי כנסת')
          .select('"שם הבית כנסת", "אורך", "רוחב"');

      if (response.isEmpty) {
        setState(() {
          _loading = false;
          _synagogueLocations = {};
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

      await prefs.setString('synagogue_locations', jsonEncode(data));
      await prefs.setInt('synagogue_locations_time', currentTime);
    } catch (e) {
      debugPrint('Exception fetching synagogues: $e');
      setState(() {
        _loading = false;
        _synagogueLocations = {};
      });
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && !kIsWeb) return _showLocationServiceError();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied && !kIsWeb) {
          return _showLocationPermissionError();
        }
      }

      if (permission == LocationPermission.deniedForever && !kIsWeb) {
        return _showLocationPermissionError();
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      const fallback = LatLng(32.0464, 34.8411);

      setState(() {
        _currentLocation = position != null
            ? LatLng(position.latitude, position.longitude)
            : fallback;
        _loading = false;
      });

      _animationController.forward();
      await _setMarkersAndRoute();

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

  LatLngBounds _getBounds(LatLng userLocation, List<LatLng> locations) {
    double west = userLocation.longitude;
    double east = userLocation.longitude;
    double north = userLocation.latitude;
    double south = userLocation.latitude;

    for (final loc in locations) {
      if (loc.longitude < west) west = loc.longitude;
      if (loc.longitude > east) east = loc.longitude;
      if (loc.latitude < south) south = loc.latitude;
      if (loc.latitude > north) north = loc.latitude;
    }

    return LatLngBounds(
      northeast: LatLng(north, east),
      southwest: LatLng(south, west),
    );
  }

  Future<void> _setMarkersAndRoute({String? selectedSynagogue}) async {
    if (_currentLocation == null) return;

    if (selectedSynagogue != null) {
      setState(() => _selectedSynagogue = selectedSynagogue);
    }

    _markers = _synagogueLocations.entries.map((entry) {
      final isSelected = entry.key == _selectedSynagogue;
      return Marker(
        markerId: MarkerId(entry.key),
        position: entry.value,
        infoWindow: InfoWindow(title: entry.key),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        onTap: () => _setMarkersAndRoute(selectedSynagogue: entry.key),
      );
    }).toSet();

    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation!,
        infoWindow: const InfoWindow(title: 'המיקום שלי'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    _polylines.clear();
    setState(() => _routeInfo = null);

    if (_selectedSynagogue == null ||
        !_synagogueLocations.containsKey(_selectedSynagogue)) {
      setState(() {});
      return;
    }

    final synagogueLocation = _synagogueLocations[_selectedSynagogue]!;
    final prefs = await SharedPreferences.getInstance();
    final routeCacheKey = 'osrm_route_${_selectedSynagogue!}';
    final cachedRouteJson = prefs.getString(routeCacheKey);

    List<LatLng> polylineCoordinates = [];
    OsrmRouteResult? routeResult;

    if (cachedRouteJson != null) {
      try {
        final cached = jsonDecode(cachedRouteJson) as Map<String, dynamic>;
        final pointsList = cached['points'] as List<dynamic>;
        polylineCoordinates = pointsList
            .map((p) => LatLng(
                  (p[0] as num).toDouble(),
                  (p[1] as num).toDouble(),
                ))
            .toList();
        routeResult = OsrmRouteResult(
          polylinePoints: polylineCoordinates,
          distanceMeters: (cached['distance'] as num).toDouble(),
          durationSeconds: (cached['duration'] as num).toDouble(),
        );
      } catch (_) {
        polylineCoordinates = [];
        routeResult = null;
      }
    }

    if (polylineCoordinates.isEmpty) {
      setState(() => _routeLoading = true);
      try {
        final result = await MapService.fetchWalkingRoute(
          _currentLocation!,
          synagogueLocation,
        );

        if (result != null) {
          polylineCoordinates = result.polylinePoints;
          routeResult = result;

          final cachePayload = jsonEncode({
            'points': polylineCoordinates
                .map((p) => [p.latitude, p.longitude])
                .toList(),
            'distance': result.distanceMeters,
            'duration': result.durationSeconds,
          });
          await prefs.setString(routeCacheKey, cachePayload);
        } else {
          polylineCoordinates = [_currentLocation!, synagogueLocation];
        }
      } catch (_) {
        polylineCoordinates = [_currentLocation!, synagogueLocation];
      } finally {
        setState(() => _routeLoading = false);
      }
    }

    if (polylineCoordinates.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: PolylineId(_selectedSynagogue!),
          points: polylineCoordinates,
          color: AppColors.blue,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        ),
      );

      if (_mapController != null) {
        final bounds = _getBounds(_currentLocation!, [synagogueLocation]);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    }

    setState(() => _routeInfo = routeResult);
  }

  void _showLocationServiceError() => _showErrorDialog(
        'שירות המיקום מנוטרל',
        'אנא הפעל את שירות המיקום בהגדרות המכשיר',
      );

  void _showLocationPermissionError() => _showErrorDialog(
        'הרשאות מיקום נדרשות',
        'אנא אשר הרשאות מיקום כדי להשתמש בתכונה זו',
      );

  void _showLocationError() =>
      _showErrorDialog('שגיאה במיקום', 'לא ניתן לקבוע את המיקום הנוכחי');

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, textDirection: TextDirection.rtl),
        content: Text(message, textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirectionsInGoogleMaps() async {
    if (_currentLocation == null) return;

    final target = (_selectedSynagogue != null &&
            _synagogueLocations.containsKey(_selectedSynagogue))
        ? _synagogueLocations[_selectedSynagogue!]!
        : _currentLocation!;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
      '&destination=${target.latitude},${target.longitude}'
      '&travelmode=walking',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildSynagogueDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSynagogue,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.blue,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              items: _synagogueLocations.keys.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    name,
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) _setMarkersAndRoute(selectedSynagogue: value);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _routeInfo == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(_selectedSynagogue),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      color: AppColors.blue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildInfoTile(
                    label: 'מרחק',
                    value: _routeInfo!.formattedDistance,
                  ),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 36, color: AppColors.divider),
                  const SizedBox(width: 16),
                  _buildInfoTile(
                    label: 'זמן הליכה',
                    value: _routeInfo!.formattedDuration,
                  ),
                  const Spacer(),
                  _buildNavigateButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigateButton() {
    return GestureDetector(
      onTap: _openDirectionsInGoogleMaps,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.blue, AppColors.skyBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
            SizedBox(width: 5),
            Text(
              'נווט',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 44,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'תצוגת מפה פנימית אינה זמינה בדפדפן זה',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'לחץ על הכפתור להוראות הגעה מלאות ב-Google Maps',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_routeInfo != null) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWebInfoChip(
                      icon: Icons.straighten_rounded,
                      label: _routeInfo!.formattedDistance,
                    ),
                    const SizedBox(width: 12),
                    _buildWebInfoChip(
                      icon: Icons.access_time_rounded,
                      label: _routeInfo!.formattedDuration,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openDirectionsInGoogleMaps,
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('פתח ב-Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'בתי כנסת במרכז הרפואי',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF040404),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),

          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const SizedBox(height: 100),

                if (_synagogueLocations.isNotEmpty) _buildSynagogueDropdown(),

                Expanded(
                  child: kIsWeb
                      ? _buildWebMapFallback()
                      : Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _currentLocation ??
                                    const LatLng(31.768319, 35.213711),
                                zoom: 15,
                              ),
                              markers: _markers,
                              polylines: _polylines,
                              mapType: MapType.normal,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: false,
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                            ),

                            if (_routeLoading)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.navy
                                            .withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppColors.blue,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'מחשב מסלול...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _buildRouteInfoCard(),
                            ),
                          ],
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
