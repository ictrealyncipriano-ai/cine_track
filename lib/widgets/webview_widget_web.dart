import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

class WebViewWidget extends StatelessWidget {
  final String url;
  final void Function(int progress)? onProgressChanged;

  const WebViewWidget({super.key, required this.url, this.onProgressChanged});

  @override
  Widget build(BuildContext context) {
    final viewType = 'wv-${identityHashCode(this)}';
    try {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
        return html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'fullscreen; autoplay; encrypted-media';
      });
    } catch (_) {}
    return HtmlElementView(viewType: viewType);
  }
}
