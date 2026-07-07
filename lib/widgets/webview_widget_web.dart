import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

class WebViewWidget extends StatelessWidget {
  final String url;

  const WebViewWidget({super.key, required this.url});

  /// Tracks registered view types to prevent duplicate registrations
  /// that leak iframe elements in the browser's DOM.
  static final _registeredViewTypes = <String>{};

  @override
  Widget build(BuildContext context) {
    final viewType = 'wv-${url.hashCode}';
    try {
      if (_registeredViewTypes.add(viewType)) {
        ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
          final iframe = html.IFrameElement()
            ..src = url
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
      // Registration failures are non-fatal; the HtmlElementView will
      // simply render a blank placeholder.
    }
    return HtmlElementView(viewType: viewType);
  }
}
