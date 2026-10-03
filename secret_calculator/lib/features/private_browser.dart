import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:secret_calculator/ui/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String _browserHome = 'https://www.google.com';
const String _browserBoxName = 'browserData';
const String _desktopUserAgent =
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

const List<String> _downloadExtensions = [
  '.zip', '.rar', '.7z', '.tar', '.gz', '.apk', '.pdf', '.doc', '.docx', '.xls',
  '.xlsx', '.ppt', '.pptx', '.csv', '.txt', '.epub', '.exe', '.msi', '.iso',
  '.mp3', '.m4a', '.wav', '.aac', '.flac', '.mp4', '.mkv', '.mov', '.avi',
  '.webm', '.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg',
];

String browserUrlFromInput(String input) {
  final text = input.trim();
  if (text.isEmpty) return _browserHome;
  
  final hasScheme = RegExp(r'^https?://', caseSensitive: false).hasMatch(text);
  final hasLocalhost = text.toLowerCase().startsWith('localhost') ||
      text.toLowerCase().startsWith('127.0.0.1');
  final hasIp = RegExp(r'^\d+\.\d+\.\d+\.\d+').hasMatch(text);
  
  if (text.contains(' ') && !hasScheme) {
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(text)}';
  }
  
  if (!text.contains('.') && !hasScheme && !hasLocalhost && !hasIp) {
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(text)}';
  }
  
  final withScheme = hasScheme ? text : 'https://$text';
  try {
    return Uri.parse(withScheme).toString();
  } catch (_) {
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(text)}';
  }
}

String browserHost(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  return host.isEmpty ? url : host;
}

String? browserDownloadExtension(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  for (final extension in _downloadExtensions) {
    if (path.endsWith(extension)) return extension.substring(1);
  }
  return null;
}

String _downloadName(String url) {
  final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
  final last = segments.isNotEmpty ? segments.last : '';
  if (last.isEmpty || !last.contains('.')) {
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }
  return p.basename(last);
}

enum DownloadStatus { running, done, failed }

class BrowserDownload {
  BrowserDownload({
    required this.url,
    required this.name,
    required this.path,
  });

  final String url;
  final String name;
  final String path;
  double progress = 0;
  DownloadStatus status = DownloadStatus.running;

  String get sizeLabel {
    final file = File(path);
    if (!file.existsSync()) return '';
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}

class BrowserDownloadManager {
  BrowserDownloadManager._();

  static final BrowserDownloadManager instance = BrowserDownloadManager._();

  final Dio _dio = Dio();
  final List<BrowserDownload> _items = [];
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  List<BrowserDownload> get items => List<BrowserDownload>.unmodifiable(_items);

  int get activeCount =>
      _items.where((d) => d.status == DownloadStatus.running).length;

  Future<void> start(String url) async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = p.join(docs.path, 'vault_downloads');
    await Directory(folder).create(recursive: true);
    final task = BrowserDownload(
      url: url,
      name: _downloadName(url),
      path: p.join(folder, _downloadName(url)),
    );
    _items.insert(0, task);
    revision.value++;
    try {
      await _dio.download(url, task.path, onReceiveProgress: (received, total) {
        if (total > 0) {
          task.progress = received / total;
          revision.value++;
        }
      });
      task.progress = 1;
      task.status = DownloadStatus.done;
    } catch (_) {
      task.status = DownloadStatus.failed;
    }
    revision.value++;
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    final task = _items.removeAt(index);
    final file = File(task.path);
    if (file.existsSync()) file.deleteSync();
    revision.value++;
  }

  void clearFinished() {
    _items.removeWhere((d) => d.status != DownloadStatus.running);
    revision.value++;
  }
}

class _BrowserStore {
  static void recordVisit(Box<String> box, String url, String title) {
    box.put('h:$url', jsonEncode({
      'u': url,
      't': title,
      'd': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  static void removeVisit(Box<String> box, String url) => box.delete('h:$url');

  static void toggleBookmark(Box<String> box, String url, String title) {
    final key = 'b:$url';
    if (box.containsKey(key)) {
      box.delete(key);
      return;
    }
    box.put(key, jsonEncode({
      'u': url,
      't': title,
      'd': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  static void removeBookmark(Box<String> box, String url) => box.delete('b:$url');

  static bool isBookmarked(Box<String> box, String url) =>
      box.containsKey('b:$url');

  static List<Map<String, dynamic>> history(Box<String> box) =>
      _read(box, 'h:');

  static List<Map<String, dynamic>> bookmarks(Box<String> box) =>
      _read(box, 'b:');

  static void clearHistory(Box<String> box) {
    final keys = box.keys.whereType<String>().where((k) => k.startsWith('h:'));
    box.deleteAll(keys.toList());
  }

  static List<Map<String, dynamic>> _read(Box<String> box, String prefix) {
    final entries = box.keys
        .whereType<String>()
        .where((key) => key.startsWith(prefix))
        .map((key) => jsonDecode(box.get(key)!) as Map<String, dynamic>)
        .toList();
    entries.sort((a, b) => (b['d'] as int).compareTo(a['d'] as int));
    return entries;
  }
}

class PrivateBrowser extends StatefulWidget {
  const PrivateBrowser({super.key});

  @override
  State<PrivateBrowser> createState() => _PrivateBrowserState();
}

class _PrivateBrowserState extends State<PrivateBrowser> {
  late final WebViewController _controller;
  late final Future<Box<String>> _boxFuture;
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocus = FocusNode();

  int _progress = 0;
  String _currentUrl = _browserHome;
  String _pageTitle = '';
  String? _error;
  bool _canGoBack = false;
  bool _desktopMode = false;

  @override
  void initState() {
    super.initState();
    _boxFuture = Hive.openBox<String>(_browserBoxName);
    _urlController.text = _currentUrl;
    _controller = WebViewController.fromPlatformCreationParams(
      const PlatformWebViewControllerCreationParams(),
    );
    _load();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.black);
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
        onPageStarted: (url) {
          if (mounted) {
            setState(() {
              _currentUrl = url;
              _error = null;
            });
          }
          _syncCanGoBack();
        },
        onUrlChange: (change) {
          if (mounted && change.url != null) {
            setState(() => _currentUrl = change.url!);
          }
        },
        onPageFinished: _onPageFinished,
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) {
            setState(() => _error = error.description);
          }
        },
        onNavigationRequest: (request) {
          if (browserDownloadExtension(request.url) != null) {
            BrowserDownloadManager.instance.start(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
    await _controller.loadRequest(Uri.parse(_browserHome));
  }

  Future<void> _onPageFinished(String url) async {
    final title = await _controller.getTitle();
    final resolved = (title == null || title.trim().isEmpty)
        ? browserHost(url)
        : title.trim();
    _boxFuture.then((box) {
      _BrowserStore.recordVisit(box, url, resolved);
    });
    if (mounted) {
      setState(() {
        _progress = 0;
        _pageTitle = resolved;
      });
    }
    _syncCanGoBack();
  }

  void _syncCanGoBack() {
    _controller.canGoBack().then((value) {
      if (mounted && value != _canGoBack) setState(() => _canGoBack = value);
    });
  }

  void _submitUrl(String input) {
    String text = input.trim();
    if (text.isEmpty) return;
    
    // Check if it has scheme
    final hasScheme = RegExp(r'^https?://', caseSensitive: false).hasMatch(text);
    final hasLocalhost = text.toLowerCase().startsWith('localhost') ||
        text.toLowerCase().startsWith('127.0.0.1');
    final hasIp = RegExp(r'^\d+\.\d+\.\d+\.\d+').hasMatch(text);
    
    // If it's a search query (contains space and no scheme), use Google search
    if (text.contains(' ') && !hasScheme) {
      final encoded = Uri.encodeQueryComponent(text);
      _urlFocus.unfocus();
      _openUrl('https://www.google.com/search?q=$encoded');
      return;
    }
    
    // If no dot and no scheme and not localhost/ip, treat as search
    if (!text.contains('.') && !hasScheme && !hasLocalhost && !hasIp) {
      final encoded = Uri.encodeQueryComponent(text);
      _urlFocus.unfocus();
      _openUrl('https://www.google.com/search?q=$encoded');
      return;
    }
    
    final withScheme = hasScheme ? text : 'https://$text';
    try {
      _urlFocus.unfocus();
      _openUrl(Uri.parse(withScheme).toString());
    } catch (_) {
      final encoded = Uri.encodeQueryComponent(text);
      _openUrl('https://www.google.com/search?q=$encoded');
    }
  }

  void _openUrl(String url) {
    setState(() {
      _currentUrl = url;
      _error = null;
    });
    _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) await _controller.goBack();
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) await _controller.goForward();
  }

  Future<void> _setDesktopMode(bool desktop) async {
    _desktopMode = desktop;
    await _controller.setUserAgent(desktop ? _desktopUserAgent : null);
    await _controller.reload();
  }

  void _openDownloads() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BrowserDownloadsPage()),
    );
  }

  void _onMenuSelected(int value, Box<String> box) {
    switch (value) {
      case 0:
        _BrowserStore.toggleBookmark(box, _currentUrl, _pageTitle);
        final saved = _BrowserStore.isBookmarked(box, _currentUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(saved ? "Bookmark added" : "Bookmark removed"),
          ),
        );
      case 1:
        Clipboard.setData(ClipboardData(text: _currentUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Link copied"),
          ),
        );
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrowserHistoryPage(onOpen: _openUrl),
          ),
        );
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrowserBookmarksPage(onOpen: _openUrl),
          ),
        );
      case 4:
        _openUrl(_browserHome);
      case 5:
        _setDesktopMode(!_desktopMode);
      case 6:
        _BrowserStore.clearHistory(box);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("History cleared"),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box<String>>(
      future: _boxFuture,
      builder: (context, snapshot) {
        final box = snapshot.data;
        return PopScope(
          canPop: !_canGoBack,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _goBack();
          },
          child: Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: _UrlField(
                controller: _urlController,
                focusNode: _urlFocus,
                url: _currentUrl,
                onSubmitted: _submitUrl,
              ),
              actions: [
                IconButton(
                  tooltip: "Back",
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
                IconButton(
                  tooltip: "Forward",
                  onPressed: _goForward,
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
                IconButton(
                  tooltip: "Reload",
                  onPressed: _controller.reload,
                  icon: const Icon(Icons.refresh),
                ),
                if (box != null)
                  ValueListenableBuilder<Box<String>>(
                    valueListenable: box.listenable(),
                    builder: (context, listenable, child) => PopupMenuButton<int>(
                      tooltip: "More",
                      icon: const Icon(Icons.more_vert),
                      color: mainColorDark,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (value) => _onMenuSelected(value, box),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 0,
                          child: _menuRow(
                            Icons.bookmark,
                            _BrowserStore.isBookmarked(box, _currentUrl)
                                ? "Remove bookmark"
                                : "Add bookmark",
                          ),
                        ),
                        const PopupMenuItem(
                          value: 1,
                          child: _MenuRow(
                            icon: Icons.copy,
                            label: "Copy link",
                          ),
                        ),
                        const PopupMenuItem(
                          value: 2,
                          child: _MenuRow(
                            icon: Icons.history,
                            label: "History",
                          ),
                        ),
                        const PopupMenuItem(
                          value: 3,
                          child: _MenuRow(
                            icon: Icons.bookmarks_outlined,
                            label: "Bookmarks",
                          ),
                        ),
                        const PopupMenuItem(
                          value: 4,
                          child: _MenuRow(icon: Icons.home, label: "Home"),
                        ),
                        PopupMenuItem(
                          value: 5,
                          child: _MenuRow(
                            icon: Icons.desktop_windows_outlined,
                            label:
                                _desktopMode ? "Mobile site" : "Desktop site",
                          ),
                        ),
                        const PopupMenuItem(
                          value: 6,
                          child: _MenuRow(
                            icon: Icons.delete_sweep_outlined,
                            label: "Clear history",
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            body: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_progress > 0 && _progress < 100)
                  Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(
                      value: _progress / 100,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                if (_error != null)
                  _ErrorView(
                    message: _error!,
                    onRetry: _controller.reload,
                    onHome: () => _openUrl(_browserHome),
                  ),
              ],
            ),
            floatingActionButton: _DownloadFab(onTap: _openDownloads),
          ),
        );
      },
    );
  }

  Widget _menuRow(IconData icon, String label) => _MenuRow(icon: icon, label: label);
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _UrlField extends StatefulWidget {
  const _UrlField({
    required this.controller,
    required this.focusNode,
    required this.url,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String url;
  final ValueChanged<String> onSubmitted;

  @override
  State<_UrlField> createState() => _UrlFieldState();
}

class _UrlFieldState extends State<_UrlField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _UrlField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.focusNode.hasFocus && widget.url != widget.controller.text) {
      widget.controller.text = browserHost(widget.url);
    }
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      widget.controller.text = widget.url;
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    } else {
      widget.controller.text = browserHost(widget.url);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: const TextStyle(fontSize: 14),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        autocorrect: false,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: mainColorDark,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          prefixIcon: Icon(
            focused ? Icons.search : Icons.lock_outline,
            size: 18,
            color: secondaryColor,
          ),
          hintText: focused ? "Search or enter address" : "Search",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onHome,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mainColor,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: secondaryColor),
          const SizedBox(height: 16),
          Text(
            "Unable to load page",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(onPressed: onHome, child: const Text("Home")),
              const SizedBox(width: 12),
              FilledButton(onPressed: onRetry, child: const Text("Retry")),
            ],
          ),
        ],
      ),
    );
  }
}

class _DownloadFab extends StatefulWidget {
  const _DownloadFab({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_DownloadFab> createState() => _DownloadFabState();
}

class _DownloadFabState extends State<_DownloadFab>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  int _lastActive = 0;

  @override
  void initState() {
    super.initState();
    _lastActive = BrowserDownloadManager.instance.activeCount;
    BrowserDownloadManager.instance.revision.addListener(_onDownloadsChanged);
    _spin.forward(from: 0);
  }

  @override
  void dispose() {
    BrowserDownloadManager.instance.revision.removeListener(_onDownloadsChanged);
    _enter.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _onDownloadsChanged() {
    final active = BrowserDownloadManager.instance.activeCount;
    if (active != _lastActive) {
      _lastActive = active;
      _spin.forward(from: 0);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final active = BrowserDownloadManager.instance.activeCount;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _enter, curve: Curves.easeOutBack),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            heroTag: 'privateBrowserDownloadFab',
            tooltip: "Downloads",
            onPressed: widget.onTap,
            child: RotationTransition(
              turns: _spin,
              child: const Icon(Icons.download_rounded),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: active == 0
                  ? const SizedBox.shrink(key: ValueKey('none'))
                  : Container(
                      key: ValueKey(active),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$active",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

class BrowserHistoryPage extends StatelessWidget {
  const BrowserHistoryPage({super.key, required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        actions: [
          IconButton(
            tooltip: "Clear history",
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _BrowserStore.clearHistory(
              Hive.box<String>(_browserBoxName),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Box<String>>(
        future: Hive.openBox<String>(_browserBoxName),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ValueListenableBuilder<Box<String>>(
            valueListenable: snapshot.data!.listenable(),
            builder: (context, box, child) {
              final entries = _BrowserStore.history(box);
              if (entries.isEmpty) {
                return const Center(child: Text("No history yet!"));
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final url = entry['u'] as String;
                  return ListTile(
                    leading: const Icon(Icons.history, color: secondaryColor),
                    title: Text(
                      entry['t'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _BrowserStore.removeVisit(box, url),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onOpen(url);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class BrowserBookmarksPage extends StatelessWidget {
  const BrowserBookmarksPage({super.key, required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bookmarks")),
      body: FutureBuilder<Box<String>>(
        future: Hive.openBox<String>(_browserBoxName),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ValueListenableBuilder<Box<String>>(
            valueListenable: snapshot.data!.listenable(),
            builder: (context, box, child) {
              final entries = _BrowserStore.bookmarks(box);
              if (entries.isEmpty) {
                return const Center(child: Text("No bookmarks yet!"));
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final url = entry['u'] as String;
                  return ListTile(
                    leading: const Icon(Icons.bookmark, color: secondaryColor),
                    title: Text(
                      entry['t'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _BrowserStore.removeBookmark(box, url),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onOpen(url);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class BrowserDownloadsPage extends StatelessWidget {
  const BrowserDownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Downloads"),
        actions: [
          IconButton(
            tooltip: "Clear finished",
            icon: const Icon(Icons.delete_sweep),
            onPressed: BrowserDownloadManager.instance.clearFinished,
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: BrowserDownloadManager.instance.revision,
        builder: (context, revision, child) {
          final items = BrowserDownloadManager.instance.items;
          if (items.isEmpty) {
            return const Center(child: Text("No downloads yet!"));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = items[index];
              return ListTile(
                leading: Icon(
                  task.status == DownloadStatus.failed
                      ? Icons.error_outline
                      : Icons.insert_drive_file_outlined,
                  color: task.status == DownloadStatus.failed
                      ? Colors.redAccent
                      : secondaryColor,
                ),
                title: Text(
                  task.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: task.status == DownloadStatus.running
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: LinearProgressIndicator(
                          value: task.progress,
                        ),
                      )
                    : Text(
                        task.status == DownloadStatus.failed
                            ? "Download failed"
                            : task.sizeLabel,
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () =>
                      BrowserDownloadManager.instance.removeAt(index),
                ),
                onTap: () async {
                  final result = await OpenFilex.open(task.path);
                  if (result.type != ResultType.done && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text("No app found to open this file"),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}