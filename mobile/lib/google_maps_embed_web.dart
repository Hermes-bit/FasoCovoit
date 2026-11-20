import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildGoogleMapsEmbed(Uri uri) => ClipRRect(
  borderRadius: BorderRadius.circular(14),
  child: SizedBox(
    width: double.infinity,
    height: 280,
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
