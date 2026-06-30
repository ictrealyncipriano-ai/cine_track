import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../config.dart';
import '../helpers/open_url.dart';
import '../models/movie.dart';

class StreamPlayerScreen extends StatefulWidget {
  final Movie movie;

  const StreamPlayerScreen({super.key, required this.movie});

  @override
  State<StreamPlayerScreen> createState() => _StreamPlayerScreenState();
}

class _StreamPlayerScreenState extends State<StreamPlayerScreen> {
  InAppWebViewController? _controller;
  int _sourceIndex = 0;
  double _progress = 0;
  bool _showTrySource = false;

  String get _currentUrl => AppConfig.streamUrl(widget.movie.id, _sourceIndex);
  String get _currentName => AppConfig.streamingSources[_sourceIndex]['name']!;

  @override
  void initState() {
    super.initState();
    _openSourceOnWeb();
    Timer(const Duration(seconds: 4), () {
      if (mounted && _progress < 1) {
        setState(() => _showTrySource = true);
      }
    });
  }

  void _openSourceOnWeb() {
    if (!kIsWeb) return;
    if (_sourceIndex < 2) return;
    openUrlInNewTab(_currentUrl);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _switchSource() {
    _sourceIndex = (_sourceIndex + 1) % AppConfig.streamingSources.length;
    _showTrySource = false;
    _progress = 0;
    if (kIsWeb && _sourceIndex >= 2) {
      openUrlInNewTab(_currentUrl);
      return;
    }
    _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_currentUrl)),
    );
    Timer(const Duration(seconds: 4), () {
      if (mounted && _progress < 1) {
        setState(() => _showTrySource = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowFileAccess: true,
              allowContentAccess: true,
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              javaScriptCanOpenWindowsAutomatically: true,
              userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onProgressChanged: (controller, progress) {
              setState(() => _progress = progress / 100);
            },
            onCreateWindow: (controller, createWindowAction) async {
              return true;
            },
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
          if (_progress < 1)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.black,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
              ),
            ),
        ],
      ),
    );
  }
}
