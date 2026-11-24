import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'theme.dart';
import 'ui.dart';

enum SourcePhoto { appareil, galerie }

/// Prend ou importe une photo et renvoie ses octets (null si annulé).
/// Remplaçable dans les tests, où l'appareil photo n'existe pas.
Future<Uint8List?> Function(SourcePhoto source, {bool selfie}) preneurPhoto = _imagePicker;

Future<Uint8List?> _imagePicker(SourcePhoto source, {bool selfie = false}) async {
  final fichier = await ImagePicker().pickImage(
    source: source == SourcePhoto.appareil ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1000,
    maxHeight: 1000,
    imageQuality: 80,
    preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
  );
  return fichier?.readAsBytes();
}

/// Résultat du choix : une nouvelle photo, ou la demande de la retirer.
class ChoixPhoto {
  const ChoixPhoto.photo(Uint8List this.octets) : retirer = false;
  const ChoixPhoto.retirer() : octets = null, retirer = true;
  final Uint8List? octets;
  final bool retirer;
}

/// Propose « Prendre une photo », « Importer une photo » et,
/// si une photo existe déjà, « Retirer la photo ». Sans [galerie] (documents
/// du conducteur), l'appareil photo s'ouvre directement : une image retouchée
/// ou trouvée ailleurs ne peut pas être envoyée.
Future<ChoixPhoto?> demanderPhoto(
  BuildContext context, {
  required String titre,
  bool selfie = false,
  bool peutRetirer = false,
  bool galerie = true,
}) async {
  final choix = !galerie && !peutRetirer
      ? 'appareil'
      : await showModalBottomSheet<String>(
    context: context,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titre, style: T.titre(22)),
            const SizedBox(height: 12),
            ListeCarte(
              children: [
                LigneListe(
                  onTap: () => Navigator.pop(c, 'appareil'),
                  children: const [
                    Icon(Icons.photo_camera_outlined, size: 22),
                    Bloc('Prendre une photo', "Avec l'appareil photo du téléphone"),
                  ],
                ),
                if (galerie)
                  LigneListe(
                    onTap: () => Navigator.pop(c, 'galerie'),
                    children: const [
                      Icon(Icons.photo_library_outlined, size: 22),
                      Bloc('Importer une photo', 'Depuis la galerie ou les fichiers'),
                    ],
                  ),
                if (peutRetirer)
                  LigneListe(
                    onTap: () => Navigator.pop(c, 'retirer'),
                    children: const [
                      Icon(Icons.delete_outline_rounded, size: 22, color: C.sos),
                      Bloc('Retirer la photo'),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (choix == null || !context.mounted) return null;
  if (choix == 'retirer') return const ChoixPhoto.retirer();
  try {
    final octets = await preneurPhoto(
      choix == 'appareil' ? SourcePhoto.appareil : SourcePhoto.galerie,
      selfie: selfie,
    );
    if (octets == null || octets.isEmpty) return null;
    return ChoixPhoto.photo(octets);
  } on PlatformException catch (e) {
    if (context.mounted) {
      message(
        context,
        e.code.contains('denied') || e.code.contains('access')
            ? "Autorisez l'accès à l'appareil photo et aux photos dans les réglages du téléphone."
            : "Impossible d'ouvrir l'appareil photo ou la galerie.",
      );
    }
    return null;
  }
}

/// Photo ronde (profil) : image si disponible, sinon les initiales.
class PhotoRonde extends StatelessWidget {
  const PhotoRonde({
    super.key,
    required this.photo,
    required this.initiales,
    this.taille = 46,
    this.fond = C.lateriteC,
    this.texte = C.lateriteF,
  });
  final Uint8List? photo;
  final String initiales;
  final double taille;
  final Color fond;
  final Color texte;

  @override
  Widget build(BuildContext context) {
    if (photo == null) return Ava(initiales, taille: taille, fond: fond, texte: texte);
    return ClipOval(
      child: Image.memory(
        photo!,
        width: taille,
        height: taille,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        semanticLabel: 'Photo de profil',
        errorBuilder: (_, _, _) => Ava(initiales, taille: taille, fond: fond, texte: texte),
      ),
    );
  }
}
