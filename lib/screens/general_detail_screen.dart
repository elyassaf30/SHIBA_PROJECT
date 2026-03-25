import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class GeneralDetailScreen extends StatefulWidget {
  final String? type;

  const GeneralDetailScreen({super.key, this.type});

  @override
  _GeneralDetailScreenState createState() => _GeneralDetailScreenState();
}

class _GeneralDetailScreenState extends State<GeneralDetailScreen> {
  String? info;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isOffline = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchInfoByType();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> fetchInfoByType() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isOffline = false;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'generalInfo_${widget.type}';
    final cacheTimeKey = 'generalInfoTime_${widget.type}';

    final cachedData = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt(cacheTimeKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    // ׳‘׳“׳™׳§׳× ׳—׳™׳‘׳•׳¨ ׳׳׳™׳ ׳˜׳¨׳ ׳˜
    final hasInternet = await _checkInternetConnection();

    // ׳׳ ׳™׳© ׳׳™׳“׳¢ ׳׳•׳§׳“׳ ׳‘׳§׳׳©, ׳”׳¦׳’ ׳׳•׳×׳• ׳×׳—׳™׳׳”
    if (cachedData != null) {
      setState(() {
        info = cachedData;
        _isLoading = false;
        if (!hasInternet) {
          _isOffline = true;
        }
      });

      // ׳׳ ׳”׳׳™׳“׳¢ ׳¢׳“׳™׳™׳ ׳¨׳׳•׳•׳ ׳˜׳™ (׳₪׳—׳•׳× ׳׳©׳¢׳”) ׳•׳™׳© ׳׳™׳ ׳˜׳¨׳ ׳˜, ׳׳ ׳¦׳¨׳™׳ ׳׳˜׳¢׳•׳ ׳׳—׳“׳©
      if (cachedTime != null && now - cachedTime < 3600000 && hasInternet) {
        return;
      }
    }

    // ׳׳ ׳׳™׳ ׳׳™׳ ׳˜׳¨׳ ׳˜ ׳•׳׳™׳ ׳§׳׳©
    if (!hasInternet) {
      setState(() {
        _isOffline = true;
        _isLoading = false;
        if (cachedData == null) {
          _hasError = true;
          _errorMessage = '׳׳™׳ ׳—׳™׳‘׳•׳¨ ׳׳׳™׳ ׳˜׳¨׳ ׳˜ ׳•׳׳ ׳ ׳׳¦׳ ׳׳™׳“׳¢ ׳©׳׳•׳¨';
        }
      });
      return;
    }

    // ׳ ׳™׳¡׳™׳•׳ ׳׳˜׳¢׳•׳ ׳׳”׳©׳¨׳×
    try {
      final response = await Supabase.instance.client
          .from('׳›׳׳׳™')
          .select('׳׳™׳“׳¢')
          .eq('׳¡׳•׳’', widget.type ?? '')
          .maybeSingle()
          .timeout(Duration(seconds: 10)); // timeout ׳©׳ 10 ׳©׳ ׳™׳•׳×

      setState(() {
        info = response != null ? (response['׳׳™׳“׳¢'] as String?) : null;
        _isLoading = false;
        _isOffline = false;
      });

      if (info != null) {
        await prefs.setString(cacheKey, info!);
        await prefs.setInt(cacheTimeKey, now);
      }
    } catch (e) {
      debugPrint('׳©׳’׳™׳׳” ׳‘-fetchInfoByType: $e');

      setState(() {
        _isLoading = false;

        if (e.toString().contains('timeout') ||
            e.toString().contains('network') ||
            e.toString().contains('connection')) {
          _isOffline = true;
          if (cachedData == null) {
            _hasError = true;
            _errorMessage = '׳—׳™׳‘׳•׳¨ ׳׳©׳¨׳× ׳ ׳›׳©׳ - ׳‘׳“׳•׳§ ׳׳× ׳”׳—׳™׳‘׳•׳¨ ׳׳׳™׳ ׳˜׳¨׳ ׳˜';
          }
        } else {
          _hasError = true;
          _errorMessage = '׳׳™׳¨׳¢׳” ׳©׳’׳™׳׳” ׳‘׳˜׳¢׳™׳ ׳× ׳”׳׳™׳“׳¢. ׳ ׳¡׳” ׳©׳•׳‘ ׳׳׳•׳—׳¨ ׳™׳•׳×׳¨.';
        }
      });
    }
  }

  Widget _buildOfflineBanner() {
    if (!_isOffline) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange[700], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              info != null
                  ? '׳׳¦׳™׳’ ׳׳™׳“׳¢ ׳©׳׳•׳¨ - ׳׳™׳ ׳—׳™׳‘׳•׳¨ ׳׳׳™׳ ׳˜׳¨׳ ׳˜'
                  : '׳׳™׳ ׳—׳™׳‘׳•׳¨ ׳׳׳™׳ ׳˜׳¨׳ ׳˜',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    IconData errorIcon;
    String errorTitle;
    String errorSubtitle;

    if (_isOffline) {
      errorIcon = Icons.wifi_off;
      errorTitle = '׳׳™׳ ׳—׳™׳‘׳•׳¨ ׳׳׳™׳ ׳˜׳¨׳ ׳˜';
      errorSubtitle = '׳‘׳“׳•׳§ ׳׳× ׳”׳—׳™׳‘׳•׳¨ ׳©׳׳ ׳•׳ ׳¡׳” ׳©׳•׳‘';
    } else {
      errorIcon = Icons.error_outline;
      errorTitle = '׳©׳’׳™׳׳” ׳‘׳˜׳¢׳™׳ ׳× ׳”׳׳™׳“׳¢';
      errorSubtitle = _errorMessage ?? '׳׳™׳¨׳¢׳” ׳©׳’׳™׳׳” ׳׳ ׳¦׳₪׳•׳™׳”';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(errorIcon, size: 64, color: Colors.grey[600]),
        SizedBox(height: 16),
        Text(
          errorTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          errorSubtitle,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: fetchInfoByType,
          icon: Icon(Icons.refresh),
          label: Text('׳ ׳¡׳” ׳©׳•׳‘'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.type ?? '׳₪׳¨׳˜׳™׳ ׳›׳׳׳™׳™׳',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 6, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ׳¨׳§׳¢ ׳×׳׳•׳ ׳” ׳׳׳ ׳¢׳ ׳˜׳™׳₪׳•׳ ׳‘׳©׳’׳™׳׳•׳×
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/siba4.png'),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    debugPrint('Background image error: $exception');
                  },
                ),
              ),
              // ׳¨׳§׳¢ ׳—׳׳•׳₪׳™ ׳׳ ׳”׳×׳׳•׳ ׳” ׳׳ ׳ ׳˜׳¢׳ ׳×
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                  ),
                ),
              ),
            ),
          ),

          // ׳×׳•׳›׳ ׳׳׳ ׳”׳׳×׳—׳™׳ ׳׳׳׳¢׳׳”
          SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white.withValues(alpha: 0.9)],
                  stops: [0.3, 0.5], // ׳”׳×׳—׳׳× ׳׳¢׳‘׳¨ ׳¦׳‘׳¢ ׳׳”׳©׳׳™׳© ׳”׳¢׳׳™׳•׳
                ),
              ),
              padding: EdgeInsets.only(
                top: 100, // ׳׳¨׳•׳•׳— ׳׳›׳•׳×׳¨׳×
                left: 24,
                right: 24,
                bottom: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ׳‘׳׳ ׳¨ ׳׳¦׳‘ ׳׳•׳₪׳׳™׳™׳
                  _buildOfflineBanner(),

                  // ׳›׳¨׳˜׳™׳¡ ׳×׳•׳›׳
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(24),
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
              SizedBox(height: 16),
              Text(
                '׳˜׳•׳¢׳ ׳׳™׳“׳¢...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError && info == null) {
      return SizedBox(height: 300, child: _buildErrorState());
    }

    if (info == null || info!.isEmpty) {
      return Column(
        children: [
          Icon(Icons.info_outline, size: 50, color: Colors.grey[600]),
          SizedBox(height: 16),
          Text(
            '׳׳ ׳ ׳׳¦׳ ׳׳™׳“׳¢ ׳–׳׳™׳',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: fetchInfoByType,
            icon: Icon(Icons.refresh),
            label: Text('׳¨׳¢׳ ׳'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          info!,
          style: TextStyle(fontSize: 18, height: 1.6, color: Colors.black87),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
        ),

        // ׳›׳₪׳×׳•׳¨ ׳¨׳¢׳ ׳•׳ ׳‘׳×׳—׳×׳™׳×
        if (_isOffline || _hasError)
          Padding(
            padding: EdgeInsets.only(top: 24),
            child: ElevatedButton.icon(
              onPressed: fetchInfoByType,
              icon: Icon(Icons.refresh),
              label: Text('׳¨׳¢׳ ׳ ׳׳™׳“׳¢'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isOffline ? Colors.orange[700] : Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

