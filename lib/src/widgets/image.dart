import 'dart:io';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex/src/models/widget_meta.dart';
import 'package:flutter_tex/src/utils/style_utils.dart';
import 'dart:convert'; // Import dart:convert for base64

class TeXViewImage extends TeXViewWidget {
  /// Uri for Image.
  final String imageUri;

  final String _type;

  const TeXViewImage.asset(this.imageUri) : _type = 'tex-view-asset-image';

  const TeXViewImage.network(this.imageUri) : _type = 'tex-view-network-image';

  TeXViewImage.file(File imageFile)
      : imageUri = _fileToBase64(imageFile),
        _type = 'tex-view-file-image';

  static String _fileToBase64(File imageFile) {
    List<int> imageBytes = imageFile.readAsBytesSync();
    return 'data:image/png;base64,${base64Encode(imageBytes)}';
  }

  @override
  TeXViewWidgetMeta meta() {
    return TeXViewWidgetMeta(tag: 'img', classList: _type, node: Node.leaf);
  }

  @override
  Map toJson() => {
        'meta': meta().toJson(),
        'data': imageUri,
        'style': "max-width: 100%; max-height: 100%; $teXViewDefaultStyle",
      };
}
