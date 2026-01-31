import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'config/api_config.dart';

void main() {
  runApp(const SignatureAnalyzerApp());
}

class SignatureAnalyzerApp extends StatelessWidget {
  const SignatureAnalyzerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signature Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SignatureAnalyzerHome(),
    );
  }
}

class SignatureAnalyzerHome extends StatefulWidget {
  const SignatureAnalyzerHome({Key? key}) : super(key: key);

  @override
  State<SignatureAnalyzerHome> createState() => _SignatureAnalyzerHomeState();
}

class _SignatureAnalyzerHomeState extends State<SignatureAnalyzerHome> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  bool _isApiHealthy = false;
  bool _checkingHealth = false;

 
  String get baseUrl => ApiConfig.baseUrl;
  String get predictUrl => '$baseUrl/predict';
  String get healthUrl => '$baseUrl/health';

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
  }

  Future<void> _checkApiHealth() async {
    setState(() => _checkingHealth = true);

    try {
      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(Duration(seconds: ApiConfig.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isApiHealthy = data['status'] == 'healthy';
          _checkingHealth = false;
        });

        if (ApiConfig.enableLogging) {
          print('API Health Check: ${data['status']}');
        }
      } else {
        setState(() {
          _isApiHealthy = false;
          _checkingHealth = false;
        });
      }
    } catch (e) {
      setState(() {
        _isApiHealthy = false;
        _checkingHealth = false;
      });
      if (ApiConfig.enableLogging) {
        print('Health check failed: $e');
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _imageFile = photo;
          _imageBytes = bytes;
          _result = null;
        });
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _imageFile = photo;
          _imageBytes = bytes;
          _result = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeSignature() async {
    if (_imageFile == null || _imageBytes == null) {
      _showError('Please select or capture an image first');
      return;
    }

    if (!_isApiHealthy) {
      _showError('API is not available. Please check your connection.');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      // Convert bytes to base64
      final base64Image = base64Encode(_imageBytes!);

      // Send to API
      final response = await http
          .post(
            Uri.parse(predictUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'image': base64Image}),
          )
          .timeout(
            Duration(seconds: ApiConfig.timeout),
            onTimeout: () {
              throw Exception('Request timeout. Please try again.');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = data;
          _isLoading = false;
        });

        if (ApiConfig.enableLogging) {
          print('Prediction successful: ${data['flexibility']}');
        }
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        _showError(error['detail'] ?? 'Bad request. Please check the image.');
        setState(() => _isLoading = false);
      } else if (response.statusCode == 500) {
        final error = jsonDecode(response.body);
        _showError(error['detail'] ?? 'Server error. Please try again.');
        setState(() => _isLoading = false);
      } else {
        _showError('Unexpected error (${response.statusCode})');
        setState(() => _isLoading = false);
      }
    } on SocketException {
      _showError('No internet connection. Please check your network.');
      setState(() => _isLoading = false);
    } on FormatException {
      _showError('Invalid response from server.');
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Error: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature Analyzer'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // API Status Indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _checkingHealth
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : GestureDetector(
                      onTap: _checkApiHealth,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: _isApiHealthy ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isApiHealthy ? 'Online' : 'Offline',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // API Status Banner
              if (!_isApiHealthy && !_checkingHealth)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'API is offline. Please check your connection or try again later.',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      TextButton(
                        onPressed: _checkApiHealth,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),

              // Image Display
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No signature selected',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Camera and Gallery Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: kIsWeb ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Detect Button
              ElevatedButton(
                onPressed: (_isLoading || !_isApiHealthy)
                    ? null
                    : _analyzeSignature,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Detect Signature',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Results Display
              if (_result != null) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isForceful = _result!['is_forceful'] as bool;
    final confidence = _result!['confidence'] as double;
    final flexibility = _result!['flexibility'] as String;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isForceful ? Icons.warning_amber : Icons.check_circle,
                  color: isForceful ? Colors.orange : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isForceful ? 'Forceful Signature' : 'Natural Signature',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Flexibility: $flexibility',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Confidence
            Text(
              'Confidence: ${confidence.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: confidence / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isForceful ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 16),

            // Probabilities
            const Divider(),
            const Text(
              'Probabilities:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildProbabilityRow(
              'Natural',
              _result!['probabilities']['natural'] as double,
              Colors.green,
            ),
            _buildProbabilityRow(
              'Forceful',
              _result!['probabilities']['forceful'] as double,
              Colors.orange,
            ),

            // Features
            const SizedBox(height: 16),
            const Divider(),
            ExpansionTile(
              title: const Text(
                'Technical Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              children: [
                _buildFeatureRow(
                  'Alignment Entropy',
                  _result!['features']['alignment_entropy'] as double,
                ),
                _buildFeatureRow(
                  'Slant Variance',
                  _result!['features']['slant_variance'] as double,
                ),
                _buildFeatureRow(
                  'Spacing Std Dev',
                  _result!['features']['spacing_std'] as double,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilityRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${value.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          Text(
            value.toStringAsFixed(4),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
