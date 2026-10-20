import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The documents in docs/, bundled with the app and also published on the
/// web for the store listing, so both always show the same text.
enum LegalDoc {
  terms('תנאי שימוש', 'docs/terms.html'),
  privacy('מדיניות פרטיות', 'docs/privacy-policy.html'),
  accessibility('הצהרת נגישות', 'docs/accessibility.html');

  const LegalDoc(this.title, this.asset);

  final String title;
  final String asset;
}

/// Shows a bundled [LegalDoc]. Links leave the app, except links between the
/// bundled documents.
class LegalDocScreen extends StatefulWidget {
  const LegalDocScreen(this.doc, {super.key});

  final LegalDoc doc;

  @override
  State<LegalDocScreen> createState() => _LegalDocScreenState();
}

class _LegalDocScreenState extends State<LegalDocScreen> {
  late final _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.disabled)
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);
          if (uri.scheme == 'file') return NavigationDecision.navigate;
          launchUrl(uri, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
      ),
    )
    ..loadFlutterAsset(widget.doc.asset);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.doc.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
