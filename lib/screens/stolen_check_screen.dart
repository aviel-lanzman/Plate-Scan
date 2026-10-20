import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/vehicle_result.dart';
import '../services/plate_parser.dart';
import '../widgets/status_style.dart';

/// Opens the official Israel Police stolen-vehicle page with the plate filled
/// in. The page is protected by reCAPTCHA, so the user presses "בדוק רכב"
/// themselves; the app only reads the result the page displays.
class StolenCheckScreen extends StatefulWidget {
  const StolenCheckScreen({super.key, required this.plate});

  /// Digits only.
  final String plate;

  static final pageUrl = Uri.parse('https://www.gov.il/apps/police/stolencar/');

  @override
  State<StolenCheckScreen> createState() => _StolenCheckScreenState();
}

enum _Phase { loading, filled, manualEntry, done }

class _StolenCheckScreenState extends State<StolenCheckScreen> {
  late final WebViewController _controller;
  _Phase _phase = _Phase.loading;
  int _progress = 0;
  StolenCheckOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('PlateScan', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageFinished: (_) =>
              _controller.runJavaScript(_injectedScript(widget.plate)),
        ),
      )
      ..loadRequest(StolenCheckScreen.pageUrl);
  }

  void _onMessage(JavaScriptMessage message) {
    if (!mounted) return;
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(message.message) as Map<String, dynamic>;
    } on Object {
      return;
    }
    switch (data['type']) {
      case 'ready':
        if (_phase == _Phase.loading) setState(() => _phase = _Phase.filled);
      case 'noinput':
        if (_phase == _Phase.loading) {
          setState(() => _phase = _Phase.manualEntry);
        }
      case 'result':
        // Ignore searches the user made for a different number.
        if (data['plate'] != widget.plate) return;
        final outcome = StolenCheckOutcome.values.asNameMap()[data['value']];
        if (outcome == null) return;
        if (outcome == StolenCheckOutcome.stolen) HapticFeedback.heavyImpact();
        setState(() {
          _outcome = outcome;
          _phase = _Phase.done;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = formatPlate(widget.plate);
    return PopScope<StolenCheckOutcome>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _outcome);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('בדיקת גניבה: משטרת ישראל')),
        body: Column(
          children: [
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100),
            _Banner(
              phase: _phase,
              plate: formatted,
              outcome: _outcome,
              onDone: () => Navigator.pop(context, _outcome),
            ),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.phase,
    required this.plate,
    required this.outcome,
    required this.onDone,
  });

  final _Phase phase;
  final String plate;
  final StolenCheckOutcome? outcome;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outcome = this.outcome;
    if (phase == _Phase.done && outcome != null) {
      return Material(
        color: outcome.color,
        child: ListTile(
          leading: Icon(outcome.icon, color: Colors.white, size: 32),
          title: Text(
            outcome.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: outcome == StolenCheckOutcome.stolen
              ? const Text(
                  'אל תתעמת עם הנהג. דווח למוקד 100.',
                  style: TextStyle(color: Colors.white),
                )
              : null,
          trailing: FilledButton.tonal(
            onPressed: onDone,
            child: const Text('סיום'),
          ),
        ),
      );
    }
    final text = switch (phase) {
      _Phase.loading => 'טוען את אתר משטרת ישראל...',
      _Phase.filled => 'המספר $plate מולא. לחץ על "בדוק רכב" באתר.',
      _Phase.manualEntry ||
      _Phase.done => 'הזן באתר את המספר $plate ולחץ על "בדוק רכב".',
    };
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.touch_app, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fills the plate into the page's Angular form and reports the result text
/// the page shows after the user searches. [plate] is digits only, so it is
/// safe to interpolate.
String _injectedScript(String plate) =>
    '''
(function () {
  if (window.__plateScan) return;
  window.__plateScan = true;
  var PLATE = '$plate';
  function post(o) { PlateScan.postMessage(JSON.stringify(o)); }

  var tries = 0;
  var timer = setInterval(function () {
    var input = document.querySelector('input[formcontrolname="plateNumber"]');
    if (!input) {
      if (++tries > 100) { clearInterval(timer); post({type: 'noinput'}); }
      return;
    }
    clearInterval(timer);
    var setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
    setter.call(input, PLATE);
    input.dispatchEvent(new Event('input', {bubbles: true}));
    input.scrollIntoView({block: 'center'});
    post({type: 'ready'});
    watch(input);
  }, 300);

  function watch(input) {
    var searched = null, last = null;
    function onSearch() { searched = input.value; last = null; }
    document.addEventListener('click', function (e) {
      var button = e.target.closest && e.target.closest('button');
      if (button && button.textContent.indexOf('בדוק רכב') >= 0) onSearch();
    }, true);
    document.addEventListener('submit', onSearch, true);

    function check() {
      if (searched === null) return;
      var text = document.body.innerText;
      var value = null;
      if (text.indexOf('הרכב לא מופיע במאגר כרכב גנוב') >= 0) value = 'clean';
      else if (text.indexOf('הרכב גנוב') >= 0) value = 'stolen';
      else if (text.indexOf('אירעה שגיאה בלתי צפויה') >= 0) value = 'error';
      if (value && value !== last) {
        last = value;
        post({type: 'result', value: value, plate: searched});
      }
    }
    new MutationObserver(check).observe(document.body,
        {childList: true, subtree: true, characterData: true});
  }
})();
''';
