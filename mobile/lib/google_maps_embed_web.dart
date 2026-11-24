import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// `height` nul : la carte remplit la place disponible.
Widget buildGoogleMapsEmbed(Uri uri, double? height) => ClipRRect(
  borderRadius: BorderRadius.circular(height == null ? 0 : 14),
  child: SizedBox(
    width: double.infinity,
    height: height,
    child: HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (element) {
        final iframe = element as web.HTMLIFrameElement
          ..src = uri.toString()
          ..title = 'Itinéraire FasoCovoit dans Google Maps'
          ..allow = 'fullscreen'
          ..loading = 'lazy'
          ..referrerPolicy = 'strict-origin-when-cross-origin';
        iframe.setAttribute('style', 'border:0;width:100%;height:100%;');
      },
    ),
  ),
);
