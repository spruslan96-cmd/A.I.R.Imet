// manage_models.dart

import 'package:flutter/material.dart';
import 'package:local_ai_chat/Widgets/drawer.dart';
import 'package:local_ai_chat/Widgets/model_card.dart';
import 'package:local_ai_chat/utils/download_api.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ManageModelsPage extends StatefulWidget {
  const ManageModelsPage({super.key});

  @override
  State<ManageModelsPage> createState() => _ManageModelsPageState();
}

class _ManageModelsPageState extends State<ManageModelsPage> {
  bool _isLoading = false;
  String _errorMessage = "";
  List<FileSystemEntity> _downloadedModels = []; // List of downloaded files

  @override
  void initState() {
    super.initState();
    _fetchDownloadedModels();
  }

  // Fetch all downloaded models from the local storage directory
  Future<void> _fetchDownloadedModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the local directory where models are stored
      final directory = await getApplicationDocumentsDirectory();
      final modelDirectory = Directory(directory.path);

      // List all files in the directory
      final files = modelDirectory.listSync();

      // Filter for the models that are downloaded (based on file extension or name pattern)
      final downloadedModels = files.where((file) {
        // Here we assume downloaded models are stored as files and we filter them accordingly
        return file.path.endsWith(
            ".gguf"); // Filter for .gguf files or any other model type
      }).toList();

      setState(() {
        _downloadedModels = downloadedModels;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching downloaded models: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete a model from local storage
  Future<void> _deleteModel(String modelPath) async {
    try {
      DownloadAPI().deleteModel(modelPath);
    } catch (e) {
      // Handle any errors during deletion
      print("Error deleting model: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting model: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Hamburger(),
      appBar: AppBar(
        title: const Text("Manage Models"),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage.isNotEmpty
                ? Text("Error: $_errorMessage")
                : _downloadedModels.isNotEmpty
                    ? ListView.builder(
                        itemCount: _downloadedModels.length,
                        itemBuilder: (context, index) {
                          final modelFile = _downloadedModels[index];
                          final modelName = modelFile.uri.pathSegments.last;

                          return ModelCard(
                            model: {
                              'id': modelName,
                              'description': 'Downloaded model',
                            },
                            onDownload: (modelName) {}, // No download action
                            modelExists:
                                true, // All models in this list are downloaded
                            downloadProgress:
                                1.0, // Already downloaded, so set it to 100%
                            modelSize: modelFile.statSync().size,
                            onDelete: _deleteModel,
                          );
                        },
                      )
                    : const Text("No downloaded models found."),
      ),
    );
  }
}
