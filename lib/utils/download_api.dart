import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DownloadAPI {
  final Dio _dio = Dio();

  // Check if a model exists locally
  Future<bool> checkModelExists(String modelName) async {
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = '${directory.path}/${modelName.split("/").last}';
    return File(modelPath).existsSync();
  }

  // Fetch the model size from HuggingFace
  Future<int?> fetchModelSize(String modelName) async {
    try {
      final filesUrl = "https://huggingface.co/api/models/$modelName/tree/main";
      final filesResponse = await _dio.get(filesUrl);

      if (filesResponse.statusCode != 200) {
        throw Exception(
            "Failed to get model files: ${filesResponse.statusCode}");
      }

      final filesData = filesResponse.data as List<dynamic>;

      final ggufFiles = filesData.where(
          (file) => file['path'].toString().toLowerCase().endsWith(".gguf"));

      if (ggufFiles.isNotEmpty) {
        final ggufFile = ggufFiles.first;
        return ggufFile['size'];
      }
    } catch (e) {
      print("Error fetching model size: $e");
    }
    return null;
  }

  // Download a model from HuggingFace
  Future<void> downloadModel(
      String modelName, Function(double) onProgress) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final filesUrl = "https://huggingface.co/api/models/$modelName/tree/main";
      final filesResponse = await _dio.get(filesUrl);

      if (filesResponse.statusCode != 200) {
        throw Exception(
            "Failed to get model files: ${filesResponse.statusCode}");
      }

      final filesData = filesResponse.data as List<dynamic>;

      final ggufFiles = filesData.where(
          (file) => file['path'].toString().toLowerCase().endsWith(".gguf"));

      if (ggufFiles.isEmpty) {
        throw Exception("No .gguf file found for this model.");
      }

      ggufFiles.toList().sort((a, b) => b['size'] - a['size']);

      final ggufFile = ggufFiles.first;
      final fileName = ggufFile['path'].toString().split("/").last;
      final downloadUrl =
          "https://huggingface.co/$modelName/resolve/main/${ggufFile['path']}";

      final modelPath = '${directory.path}/$fileName';
      print('Model Path = $modelPath');

      await _dio.download(downloadUrl, modelPath,
          onReceiveProgress: (received, total) {
        if (total != -1) {
          double progress = received / total;
          onProgress(progress);
        }
      });
    } catch (e) {
      print("Error downloading model: $e");
    }
  }

  // Delete a model from local storage
  Future<void> deleteModel(String modelName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/${modelName.split("/").last}';
      final file = File(modelPath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error deleting model: $e");
    }
  }
}
