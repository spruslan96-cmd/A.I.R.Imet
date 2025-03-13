import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:local_ai_chat/Widgets/drawer.dart';
import 'package:local_ai_chat/Widgets/download_model_card.dart';
import 'package:local_ai_chat/Widgets/now_downloading_card.dart';
import 'package:local_ai_chat/Widgets/downloaded_model_card.dart';
import 'package:local_ai_chat/Widgets/search_bar.dart';
import 'package:local_ai_chat/utils/download_api.dart';
import 'package:path_provider/path_provider.dart'; // Add this import
import 'dart:io'; // Add this import

class ModelCheckPage extends StatefulWidget {
  const ModelCheckPage({super.key});

  @override
  State<ModelCheckPage> createState() => _ModelCheckPageState();
}

class _ModelCheckPageState extends State<ModelCheckPage> {
  bool _isLoading = false;
  String _errorMessage = "";
  List<dynamic> _availableModels = [];
  List<dynamic> _filteredModels = [];
  String _searchQuery = "";
  Map<String, bool> _modelExistsMap = {};
  Map<String, double> _downloadProgressMap = {};
  Map<String, int?> _modelSizes = {};
  bool _modelsLoaded = false;
  List<FileSystemEntity> _downloadedModels = []; // List of downloaded models

  final DownloadAPI _downloadAPI = DownloadAPI();

  @override
  void initState() {
    super.initState();
    _fetchAvailableModels();
    _fetchDownloadedModels(); // Fetch downloaded models
  }

  Future<void> _fetchAvailableModels() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });
    }

    try {
      final dio = Dio();
      final modelsUrl =
          "https://huggingface.co/api/models?filter=gguf,conversational&full=true";
      final modelsResponse = await dio.get(modelsUrl);

      if (modelsResponse.statusCode != 200) {
        throw Exception(
            "Failed to get available models: ${modelsResponse.statusCode}");
      }

      _availableModels = modelsResponse.data as List<dynamic>;

      _filteredModels = _availableModels.where((model) {
        final modelName = model['id'] as String;
        final quantizedKeywords = [
          "quantized",
          "q4",
          "q5",
          "q8",
          "int8",
          "int4",
          "ggml",
          "llama-q"
        ];
        final isQuantized = quantizedKeywords
            .any((keyword) => modelName.toLowerCase().contains(keyword));
        bool hasQuantizationTag = model['tags'] != null &&
            model['tags'] is List<dynamic> &&
            (model['tags'] as List<dynamic>).any(
                (tag) => tag.toString().toLowerCase().contains("quantized"));

        if (modelName.toLowerCase().contains('llama') ||
            modelName.toLowerCase().contains('ggml')) {
          return isQuantized || hasQuantizationTag;
        }
        return false;
      }).toList();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        for (final model in _filteredModels) {
          final modelName = model['id'];
          final exists = await _downloadAPI.checkModelExists(modelName);
          final modelSize = await _downloadAPI.fetchModelSize(modelName);

          if (mounted) {
            setState(() {
              _modelExistsMap[modelName] = exists;
              _modelSizes[modelName] = modelSize;
            });
          }
        }

        _sortModels();
        if (mounted) {
          setState(() {
            _modelsLoaded = true;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      _errorMessage = "Error fetching models: $e";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        return file.path.endsWith(".gguf"); // Filter for .gguf files
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

  void _filterModels(String query) {
    setState(() {
      _searchQuery = query;
      _filteredModels = _availableModels.where((model) {
        return model['id']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase());
      }).toList();
      _sortModels();
    });
  }

  void _sortModels() {
    setState(() {
      _filteredModels = _availableModels.where((model) {
        final modelName = model['id'];
        return !_downloadProgressMap.containsKey(modelName);
      }).toList();
    });
  }

  Future<void> _downloadModel(String modelName) async {
    setState(() {
      _downloadProgressMap[modelName] = 0.0;
    });

    try {
      await _downloadAPI.downloadModel(modelName, (progress) {
        setState(() {
          _downloadProgressMap[modelName] = progress;
        });
      });

      final exists = await _downloadAPI.checkModelExists(modelName);
      setState(() {
        _modelExistsMap[modelName] = exists;
        _downloadProgressMap.remove(modelName);
      });

      _sortModels();
    } catch (e) {
      setState(() {
        _errorMessage = "Error downloading model: $e";
        _downloadProgressMap.remove(modelName);
      });
    }
  }

  Future<void> _deleteModel(String modelName) async {
    try {
      // Remove the model file from local storage
      final directory = await getApplicationDocumentsDirectory();
      final modelFile = File('${directory.path}/$modelName');
      if (await modelFile.exists()) {
        await modelFile.delete();
      }

      // Remove the model from the _downloadedModels list
      setState(() {
        _downloadedModels
            .removeWhere((file) => file.uri.pathSegments.last == modelName);
        _modelExistsMap[modelName] = false; // Mark as not existing
        _sortModels(); // Re-sort models after deletion
      });
    } catch (e) {
      print("Error deleting model: $e");
    }
  }

  Future<void> _cancelDownload(String modelName) async {
    await _downloadAPI.cancelDownload(modelName);
    if (mounted) {
      setState(() {
        _downloadProgressMap.remove(modelName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> downloadingModels = _downloadProgressMap.keys.toList();
    List<dynamic> downloadedModels = _modelExistsMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    List<dynamic> browseModels = _filteredModels.where((model) {
      String modelName = model['id'];
      return !downloadingModels.contains(modelName) &&
          !downloadedModels.contains(modelName);
    }).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: Hamburger(),
        appBar: AppBar(
          title: const Text("Model Manager"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100.0),
            child: Column(
              children: [
                SearchBarWidget(onSearch: _filterModels),
                const TabBar(
                  tabs: [
                    Tab(text: "Browse Models"),
                    Tab(text: "Now Downloading"),
                    Tab(text: "Downloaded Models"),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text("Error: $_errorMessage"))
                : TabBarView(
                    children: [
                      _buildBrowseModels(browseModels), // Browse Models
                      _buildDownloadingModels(
                          downloadingModels), // Now Downloading
                      _buildDownloadedModels(
                          _downloadedModels), // Downloaded Models (updated)
                    ],
                  ),
      ),
    );
  }

  Widget _buildBrowseModels(List<dynamic> models) {
    return ListView(
      children: models.map((model) {
        return DownloadModelCard(
          model: model,
          modelSize: _modelSizes[model['id']],
          onDownload: _downloadModel,
        );
      }).toList(),
    );
  }

  Widget _buildDownloadingModels(List<dynamic> models) {
    return ListView(
      children: models.map((modelName) {
        return NowDownloadingCard(
          model: {'id': modelName},
          downloadProgress: _downloadProgressMap[modelName] ?? 0.0,
          modelSize: _modelSizes[modelName],
          onCancelDownload: _cancelDownload,
        );
      }).toList(),
    );
  }

  Widget _buildDownloadedModels(List<FileSystemEntity> models) {
    return ListView(
      children: models.map((file) {
        final modelName = file.uri.pathSegments.last; // Extract model name
        return DownloadedModelCard(
          model: {'id': modelName},
          modelSize: file.statSync().size,
          onDelete: _deleteModel,
        );
      }).toList(),
    );
  }
}
