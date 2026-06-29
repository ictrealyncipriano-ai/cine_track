import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewWidget extends StatelessWidget {
  final String url;
  final void Function(int progress)? onProgressChanged;

  const WebViewWidget({
    super.key,
    required this.url,
    this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowFileAccess: true,
        allowContentAccess: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        javaScriptCanOpenWindowsAutomatically: true,
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      ),
      onProgressChanged: (controller, progress) {
        onProgressChanged?.call(progress);
      },
    );
  }
}
