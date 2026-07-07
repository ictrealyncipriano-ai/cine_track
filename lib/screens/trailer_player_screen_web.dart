import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  @override
  Widget build(BuildContext context) {
    final viewType = 'tp-${identityHashCode(widget.video)}';
    try {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
        final iframe = html.IFrameElement()
          ..src = 'https://www.youtube.com/embed/${widget.video.key}?autoplay=1&rel=0'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'fullscreen; autoplay; encrypted-media'
          ..referrerPolicy = 'no-referrer';
        try { iframe.sandbox?.value = ''; } catch (_) {}
        return iframe;
      });
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          HtmlElementView(viewType: viewType),
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
        ],
      ),
    );
  }
}
