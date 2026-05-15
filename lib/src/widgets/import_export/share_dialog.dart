import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../util/share_url.dart';

class ShareDialog extends StatelessWidget {
  /// URL-safe base64 encoded game state. The dialog wraps it into a share URL.
  final String urlSafeCode;

  const ShareDialog({super.key, required this.urlSafeCode});

  // QR (binary mode, ECC L) maxes out at ~2,953 chars at version 40.
  // Stay slightly under to keep scanning reliable.
  static const int _qrCharLimit = 2900;

  @override
  Widget build(BuildContext context) {
    final url = ShareUrl.build(urlSafeCode);
    final qrFits = url.length <= _qrCharLimit;

    return PointerInterceptor(
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Share Game State",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      url,
                      style: const TextStyle(fontSize: 14, overflow: TextOverflow.fade),
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: "Copy link",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Link copied to clipboard")),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text("Share link"),
                onPressed: () =>
                    SharePlus.instance.share(ShareParams(text: url)),
              ),

              const SizedBox(height: 16),

              if (qrFits)
                Center(
                  child: QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 250,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: const [
                      Icon(Icons.qr_code_2, size: 48, color: Colors.black38),
                      SizedBox(height: 8),
                      Text(
                        "Game too large for a QR code.\n"
                        "Share the link instead.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Secondary: raw code, for users who prefer pasting it directly
              // into the import field instead of opening a link.
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    "Show raw code",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            urlSafeCode,
                            style: const TextStyle(
                              fontSize: 12,
                              overflow: TextOverflow.fade,
                            ),
                            maxLines: 3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: "Copy code",
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: urlSafeCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Code copied to clipboard")),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
