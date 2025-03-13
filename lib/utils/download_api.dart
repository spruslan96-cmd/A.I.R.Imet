import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadAPI {
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {}; // Track downloads

  Future<void> downloadModel(
      String modelName, Function(double) onProgress) async {
    final cancelToken = CancelToken();
    _cancelTokens[modelName] = cancelToken; // Store cancel token

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filesUrl = "https://huggingface.co/api/models/$modelName/tree/main";
      final filesResponse = await _dio.get(filesUrl);

      if (filesResponse.statusCode != 200) {
        throw Exception(
            "Failed to get model files: ${filesResponse.statusCode}");
      }

      final filesData = filesResponse.data as List<dynamic>;
      final ggufFiles = filesData
          .where(
              (file) => file['path'].toString().toLowerCase().endsWith(".gguf"))
          .toList();

      if (ggufFiles.isEmpty) {
        throw Exception("No .gguf file found for this model.");
      }

      ggufFiles.sort((a, b) => b['size'] - a['size']); // Pick the largest
      final ggufFile = ggufFiles.first;
      final fileName = ggufFile['path'].split("/").last;
      final downloadUrl =
          "https://huggingface.co/$modelName/resolve/main/${ggufFile['path']}";

      final savePath = "${dir.path}/$fileName";

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        cancelToken: cancelToken,
      );
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        print("Download cancelled for $modelName");
      } else {
        print("Error downloading $modelName: $e");
      }
    } finally {
      _cancelTokens.remove(modelName);
    }
  }

  Future<void> cancelDownload(String modelName) async {
    if (_cancelTokens.containsKey(modelName)) {
      _cancelTokens[modelName]!.cancel();
      _cancelTokens.remove(modelName);
      print("Cancelled download for $modelName");
    }
  }

  // New function to check if the model exists in the app's directory
  Future<bool> isModelInAppDirectory(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/$modelName.gguf";
    final file = File(filePath);
    return await file.exists();
  }

  Future<List<String>> getDownloadedModels() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    return files
        .where((file) => file.path.endsWith('.gguf'))
        .map((file) => file.path.split('/').last.replaceAll('.gguf', ''))
        .toList();
  }

  Future<void> deleteModel(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/$modelName";

    final file = File(filePath);
    print('file path = $filePath');
    if (await file.exists()) {
      print('Model does ecist');
      await file.delete();
      print("Deleted model: $modelName");
    }
    print('Model does not exist');
  }

  Future<bool> checkModelExists(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$modelName.gguf").exists();
  }

  Future<int?> fetchModelSize(String modelName) async {
    try {
      final filesUrl = "https://huggingface.co/api/models/$modelName/tree/main";
      final filesResponse = await _dio.get(filesUrl);

      if (filesResponse.statusCode != 200) {
        throw Exception(
            "Failed to get model size: ${filesResponse.statusCode}");
      }

      final filesData = filesResponse.data as List<dynamic>;
      final ggufFiles = filesData
          .where(
              (file) => file['path'].toString().toLowerCase().endsWith(".gguf"))
          .toList();

      if (ggufFiles.isNotEmpty) {
        return ggufFiles.first['size'];
      }
    } catch (e) {
      print("Error fetching model size: $e");
    }
    return null;
  }
}
