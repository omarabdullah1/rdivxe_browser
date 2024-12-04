import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class BrowserHome extends StatefulWidget {
  const BrowserHome({super.key});

  @override
  State<BrowserHome> createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome> {
  final TextEditingController urlController = TextEditingController();
  InAppWebViewController? webViewController;
  String currentUrl = "https://rdivxe.com/";
  double progress = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: "Enter URL or text to search",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    handleTextInput(value.trim());
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  handleTextInput(urlController.text.trim());
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
            ),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(currentUrl),
                ),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onProgressChanged: (controller, progressValue) {
                  setState(() {
                    progress = progressValue / 100;
                  });
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var url = navigationAction.request.url;

                  if (url == null) return NavigationActionPolicy.ALLOW;

                  if (kDebugMode) {
                    print("Intercepted URL: ${url.toString()}");
                  }

                  // Handle special schemes like mailto, tel, whatsapp
                  if (['mailto', 'tel', 'whatsapp'].contains(url.scheme)) {
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (kDebugMode) {
                        print("Could not launch URL: ${url.toString()}");
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text("Cannot open this link: ${url.toString()}"),
                        ),
                      );
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  // Handle intent:// URLs
                  if (url.scheme == "intent") {
                    final fallbackUrl = extractFallbackUrl(url.toString());
                    if (fallbackUrl != null) {
                      if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
                        await launchUrl(
                          Uri.parse(fallbackUrl),
                          mode: LaunchMode.externalApplication,
                        );
                        return NavigationActionPolicy.CANCEL;
                      } else {
                        if (kDebugMode) {
                          print("Could not launch fallback URL: $fallbackUrl");
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Cannot handle this intent."),
                          ),
                        );
                      }
                    } else {
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                        return NavigationActionPolicy.CANCEL;
                      } else {
                        if (kDebugMode) {
                          print(
                              "Could not launch intent URL: ${url.toString()}");
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Cannot handle this intent."),
                          ),
                        );
                      }
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStop: (controller, url) {
                  setState(() {
                    currentUrl = url?.toString() ?? '';
                    urlController.text = currentUrl;
                  });
                },
                onPermissionRequest: (controller, request) async {
                  var permissions = request.resources
                      .map((resource) {
                        if (resource == PermissionResourceType.CAMERA) {
                          return Permission.camera;
                        } else if (resource ==
                            PermissionResourceType.MICROPHONE) {
                          return Permission.microphone;
                        }
                        return null;
                      })
                      .whereType<Permission>()
                      .toList();

                  for (var permission in permissions) {
                    if (await permission.request().isGranted) {
                      if (kDebugMode) {
                        print("${permission.toString()} granted");
                      }
                    }
                  }
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (await webViewController?.canGoBack() ?? false) {
                    webViewController?.goBack();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () async {
                  if (await webViewController?.canGoForward() ?? false) {
                    webViewController?.goForward();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  webViewController?.reload();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (await webViewController?.canGoBack() ?? false) {
      // If the web view can go back, navigate back within the web view.
      webViewController?.goBack();
      return false; // Prevent the default back action
    }
    return true; // Allow the default back action (exit the app)
  }

  void handleTextInput(String text) {
    if (_isValidUrl(text)) {
      // If it's a valid URL with http or https
      webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(text)),
      );
    } else if (_isDomainName(text)) {
      // If it's just a domain name (e.g., example.com), prepend "https://"
      final fullUrl = "https://$text";
      webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(fullUrl)),
      );
    } else {
      // If it's not a valid URL or domain, search for it on rdivxe
      final searchUrl =
          "https://rdivxe.com/search/?sxsrf=ALeKk0163NcjUKF5pyXKfofqOu14qYhLWw%3A1612561808473&ei=kL0dYOWoHM31kwXY5KqwDA&query=${Uri.encodeComponent(text)}";
      webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(searchUrl)),
      );
    }
  }

  bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool _isDomainName(String text) {
    // Check if the text looks like a domain name (e.g., example.com)
    final domainPattern = RegExp(r'^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$');
    return domainPattern.hasMatch(text);
  }

  String? extractFallbackUrl(String intentUrl) {
    try {
      final regex = RegExp(r'(?<=S.browser_fallback_url=)([^&]*)');
      final match = regex.firstMatch(intentUrl);
      if (match != null) {
        return Uri.decodeFull(match.group(0)!);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error extracting fallback URL: $e");
      }
    }
    return null;
  }
}
