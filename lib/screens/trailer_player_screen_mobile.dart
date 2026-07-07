import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/trailer_video.dart';

class TrailerPlayerScreen extends StatefulWidget {
  final TrailerVideo video;
  final String movieTitle;

  const TrailerPlayerScreen({
    super.key,
    required this.video,
    required this.movieTitle,
  });

  @override
  State<TrailerPlayerScreen> createState() => _TrailerPlayerScreenState();
}

class _TrailerPlayerScreenState extends State<TrailerPlayerScreen> {
  InAppWebViewController? _controller;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.video.youtubeUrl)),
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
          ),
          Positioned(
            top: 8, left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
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
                              widget.movieTitle,
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              widget.video.name,
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
          if (_progress < 1)
            Positioned(
              top: 0, left: 0, right: 0,
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
