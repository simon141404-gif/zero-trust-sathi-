import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../data/models/file_model.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final ApiClient _apiClient = ApiClient();
  List<FileModel> _files = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.getFiles();
      final files = (response.data['files'] as List)
          .map((f) => FileModel.fromJson(f))
          .toList();
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(String fileId) async {
    try {
      await _apiClient.deleteFile(fileId);
      setState(() {
        _files.removeWhere((f) => f.id == fileId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddFileDialog() {
    final nameController = TextEditingController();
    final sizeController = TextEditingController();
    String selectedType = 'application/octet-stream';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add File'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'File Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'File Size (bytes)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'MIME Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'text/plain', child: Text('Text')),
                  DropdownMenuItem(value: 'image/jpeg', child: Text('Image')),
                  DropdownMenuItem(value: 'application/pdf', child: Text('PDF')),
                  DropdownMenuItem(
                    value: 'application/octet-stream',
                    child: Text('Binary'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) selectedType = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  sizeController.text.isNotEmpty) {
                Navigator.of(ctx).pop();
                await _addFile(
                  nameController.text,
                  int.tryParse(sizeController.text) ?? 0,
                  selectedType,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFile(String name, int size, String mimeType) async {
    try {
      // Generate a mock encrypted key for demonstration
      final encryptedKey = 'mock_key_${DateTime.now().millisecondsSinceEpoch}';
      
      await _apiClient.uploadFile(name, size, mimeType, encryptedKey);
      await _loadFiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFiles,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_queue,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No files yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first file to get started',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFiles,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  _getFileIcon(file.mimeType),
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              title: Text(file.name),
                              subtitle: Text(
                                '${file.formattedSize} • ${file.mimeType}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(file),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFileDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(FileModel file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteFile(file.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_file;
    if (mimeType.startsWith('audio/')) return Icons.audio_file;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('text')) return Icons.description;
    return Icons.insert_drive_file;
  }
}
