import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget to display when data is loading
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingStateWidget({
    super.key,
    this.message = 'טוען...',
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
          SizedBox(height: 16),
          if (message != null)
            Text(
              message!,
              style: GoogleFonts.alef(fontSize: 16, color: Colors.grey[700]),
            ),
        ],
      ),
    );
  }
}

/// Widget to display when an error occurs
class ErrorStateWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorStateWidget({
    super.key,
    this.errorMessage = 'אירעה שגיאה בטעינת הנתונים',
    this.onRetry,
    this.retryButtonText = 'נסה שוב',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage ?? 'אירעה שגיאה בטעינת הנתונים',
              textAlign: TextAlign.center,
              style: GoogleFonts.alef(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
          SizedBox(height: 24),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text(retryButtonText ?? 'נסה שוב'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget to display when device is offline
class OfflineBanner extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const OfflineBanner({
    super.key,
    this.message = 'אתה במצב אופליין',
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.orange[700],
        border: Border(
          bottom: BorderSide(color: Colors.orange[900]!, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            message ?? 'אתה במצב אופליין',
            style: GoogleFonts.alef(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Builder widget that handles multiple states: loading, error, offline, and content
class StateBuilder extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final bool isOffline;
  final String? errorMessage;
  final String? loadingMessage;
  final VoidCallback? onRetry;
  final Widget? content;
  final Widget Function(BuildContext)? contentBuilder;

  const StateBuilder({
    super.key,
    this.isLoading = false,
    this.hasError = false,
    this.isOffline = false,
    this.errorMessage,
    this.loadingMessage,
    this.onRetry,
    this.content,
    this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LoadingStateWidget(message: loadingMessage);
    }

    if (hasError) {
      return ErrorStateWidget(errorMessage: errorMessage, onRetry: onRetry);
    }

    return Column(
      children: [
        if (isOffline) OfflineBanner(),
        Expanded(
          child: content ?? contentBuilder?.call(context) ?? SizedBox.expand(),
        ),
      ],
    );
  }
}

/// Expandable info card - commonly used pattern in app
class InfoCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String content;
  final Color? backgroundColor;
  final IconData? icon;
  final bool initiallyExpanded;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.backgroundColor,
    this.icon,
    this.initiallyExpanded = false,
  });

  @override
  State<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<InfoCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.alef(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            if (widget.icon != null)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(widget.icon, color: Colors.grey[600]),
              ),
          ],
        ),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                widget.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

