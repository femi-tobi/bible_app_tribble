import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

class ModelLoaderService {
  static const String _modelUrl = 'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip';
  static const String _modelName = 'vosk-model-small-en-us-0.15';

  Future<String?> loadModel() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${appDir.path}/$_modelName');

      if (await modelDir.exists()) {
        print('Model found at: ${modelDir.path}');
        return modelDir.path;
      }

      print('Model not found. Downloading from $_modelUrl...');
      final zipFile = File('${appDir.path}/model.zip');
      
      // Download
      final response = await http.get(Uri.parse(_modelUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download model: ${response.statusCode}');
      }
      await zipFile.writeAsBytes(response.bodyBytes);
      print('Download complete. Extracting...');

      // Extract
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('${appDir.path}/$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory('${appDir.path}/$filename').createSync(recursive: true);
        }
      }

      // Cleanup
      await zipFile.delete();
      print('Model extracted to: ${modelDir.path}');
      
      return modelDir.path;
    } catch (e) {
      print('Error loading model: $e');
      return null;
    }
  }
}
