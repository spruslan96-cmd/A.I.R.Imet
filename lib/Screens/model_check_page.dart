import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:local_ai_chat/Screens/ai_chat_page.dart';
import 'package:local_ai_chat/Widgets/drawer.dart';
import 'package:local_ai_chat/Widgets/model_card.dart';
import 'package:local_ai_chat/utils/download_api.dart';

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

  final DownloadAPI _downloadAPI =
      DownloadAPI(); // Initialize the DownloadAPI instance

  @override
  void initState() {
    super.initState();
    _fetchAvailableModels();
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

      // Initial filtering (gguf, conversational, and other relevant tags)
      final modelsUrl =
          "https://huggingface.co/api/models?filter=gguf,conversational&full=true"; // Add other relevant filters

      final modelsResponse = await dio.get(modelsUrl);

      if (modelsResponse.statusCode != 200) {
        throw Exception(
            "Failed to get available models: ${modelsResponse.statusCode}");
      }

      _availableModels = modelsResponse.data as List<dynamic>;

      // Additional filtering (after fetching):
      _filteredModels = _availableModels.where((model) {
        final modelName = model['id'] as String;

        // Quantization keywords (add more as needed)
        final quantizedKeywords = [
          "quantized",
          "q4",
          "q5",
          "q8",
          "int8",
          "int4",
          "ggml", // Older quantization format
          "llama-q", // Often indicates quantized Llama models
        ];

        // Check if the model name contains any of the quantization keywords
        final isQuantized = quantizedKeywords
            .any((keyword) => modelName.toLowerCase().contains(keyword));

        // Check for specific tags related to quantization (if available)
        bool hasQuantizationTag = false;
        if (model['tags'] != null && model['tags'] is List<dynamic>) {
          hasQuantizationTag = (model['tags'] as List<dynamic>)
              .any((tag) => tag.toString().toLowerCase().contains("quantized"));
        }

        // Check model name for keywords (llama, ggml, etc.)
        if (modelName.toLowerCase().contains('llama') ||
            modelName.toLowerCase().contains('ggml')) {
          return isQuantized ||
              hasQuantizationTag; // Only include quantized models
        }

        return false; // Exclude models that don't match criteria
      }).toList();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        for (final model in _filteredModels) {
          // Iterate over _filteredModels
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

  void _filterModels(String query) {
    setState(() {
      _searchQuery = query;
      _filteredModels = _availableModels
          .where((model) => model['id']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
      _sortModels();
    });
  }

  void _sortModels() {
    _filteredModels.sort((a, b) {
      final aExists = _modelExistsMap[a['id']] ?? false;
      final bExists = _modelExistsMap[b['id']] ?? false;

      if (aExists && !bExists) {
        return -1;
      } else if (!aExists && bExists) {
        return 1;
      } else {
        return 0;
      }
    });
  }

  Future<void> _downloadModel(String modelName) async {
    _downloadProgressMap[modelName] = 0.0;

    try {
      await _downloadAPI.downloadModel(modelName, (progress) {
        setState(() {
          _downloadProgressMap[modelName] = progress;
        });
      });

      final exists = await _downloadAPI.checkModelExists(modelName);
      setState(() {
        _modelExistsMap[modelName] = exists;
      });

      _sortModels();
    } catch (e) {
      _errorMessage = "Error downloading model: $e";
      _downloadProgressMap[modelName] = 0.0;
    }
  }

  Future<void> _deleteModel(String modelName) async {
    try {
      await _downloadAPI.deleteModel(modelName);
      setState(() {
        _modelExistsMap[modelName] = false;
        _sortModels();
      });
    } catch (e) {
      print("Error deleting model: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Hamburger(),
      appBar: AppBar(
        title: const Text("Model Check"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterModels,
              decoration: InputDecoration(
                hintText: "Search models...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(),
                suffix: IconButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _filteredModels = [];
                        _searchQuery = '';
                      });
                    }
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage.isNotEmpty
                ? Text("Error: $_errorMessage")
                : _filteredModels.isNotEmpty
                    ? ListView.builder(
                        itemCount: _filteredModels.length,
                        itemBuilder: (context, index) {
                          final model = _filteredModels[index];
                          final modelName = model['id'];
                          final modelExists =
                              _modelExistsMap[modelName] ?? false;
                          final progress =
                              _downloadProgressMap[modelName] ?? 0.0;
                          final modelSize = _modelSizes[modelName];

                          return ModelCard(
                            model: model,
                            onDownload: _downloadModel,
                            modelExists: modelExists,
                            downloadProgress: progress,
                            modelSize: modelSize,
                            onDelete: _deleteModel,
                          );
                        },
                      )
                    : const Text(
                        "No models found. Please check your internet connection."),
      ),
    );
  }
}
