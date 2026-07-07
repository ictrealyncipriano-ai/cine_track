import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../helpers/open_url.dart';
import '../models/movie.dart';
import '../providers/history_provider.dart';

class StreamPlayerScreen extends StatefulWidget {
  final Movie movie;

  const StreamPlayerScreen({super.key, required this.movie});

  @override
  State<StreamPlayerScreen> createState() => _StreamPlayerScreenState();
}

class _StreamPlayerScreenState extends State<StreamPlayerScreen> {
  int _sourceIndex = 0;
  bool _showTrySource = false;

  /// Tracks registered view types to prevent duplicate registrations
  /// that leak iframe elements in the browser's DOM.
  static final _registeredViewTypes = <String>{};

  String get _currentUrl => AppConfig.streamUrl(widget.movie.id, _sourceIndex);
  String get _currentName => AppConfig.streamingSources[_sourceIndex]['name']!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HistoryProvider>().addToHistory(widget.movie);
      }
    });
    _openExternalSource();
    Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showTrySource = true);
    });
  }

  void _openExternalSource() {
    if (_sourceIndex >= 2) {
      openUrlInNewTab(_currentUrl);
    }
  }

  void _switchSource() {
    _sourceIndex = (_sourceIndex + 1) % AppConfig.streamingSources.length;
    _showTrySource = false;
    if (_sourceIndex >= 2) {
      openUrlInNewTab(_currentUrl);
    }
    if (mounted) setState(() {});
  }

  Widget _buildPlayer() {
    final viewType = 'sp-${widget.movie.id}-$_sourceIndex';
    try {
      if (_registeredViewTypes.add(viewType)) {
        ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
          final iframe = html.IFrameElement()
            ..src = _currentUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allow = 'fullscreen; autoplay; encrypted-media'
            ..referrerPolicy = 'no-referrer';
          try { iframe.sandbox?.value = ''; } catch (_) {}
          return iframe;
        });
      }
    } catch (_) {
      debugPrint('StreamPlayerWeb: view factory registration failed for $viewType');
    }
    return HtmlElementView(viewType: viewType);
  }

  @override
  Widget build(BuildContext context) {
    final showExternalHint = _sourceIndex >= 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!showExternalHint)
            _buildPlayer()
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 48, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    'This source opens in a new tab',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 8, left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.title,
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _currentName,
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showTrySource)
            Positioned(
              top: 8, right: 8,
              child: SafeArea(
                child: TextButton.icon(
                  onPressed: _switchSource,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(
                    'Try different source',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
