import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/ai/paddle_onnx_native_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PaddleOnnxBenchmarkApp());
}

class PaddleOnnxBenchmarkApp extends StatelessWidget {
  const PaddleOnnxBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PaddleOnnxBenchmarkScreen(),
    );
  }
}

class PaddleOnnxBenchmarkScreen extends StatefulWidget {
  const PaddleOnnxBenchmarkScreen({super.key});

  @override
  State<PaddleOnnxBenchmarkScreen> createState() =>
      _PaddleOnnxBenchmarkScreenState();
}

class _PaddleOnnxBenchmarkScreenState extends State<PaddleOnnxBenchmarkScreen> {
  static const int _threadCount = 4;
  static const double _lowConfidence = 0.80;

  final PaddleOnnxNativeService _service = const PaddleOnnxNativeService();
  final ImagePicker _picker = ImagePicker();

  // ---- Model validation (existing) ----
  bool _isRunning = true;
  String _status = 'Preparing ONNX Runtime...';
  String _output = '';

  // ---- Full-page offline OCR test ----
  bool _isScanning = false;
  String _scanStatus = '';
  String? _scanError;
  String? _imagePath;
  OfflineOcrResult? _scanResult;
  int? _initWallMs;
  int? _scanWallMs;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runValidation();
    });
  }

  Future<void> _runValidation() async {
    if (_isRunning && _output.isNotEmpty) {
      return;
    }

    setState(() {
      _isRunning = true;
      _status = 'Checking ONNX Runtime...';
      _output = '';
    });

    try {
      final Map<String, dynamic> runtime = await _service.runtimeInfo();

      if (!mounted) {
        return;
      }

      setState(() {
        _status =
            'ONNX Runtime ${runtime['version']}\n'
            'Copying and validating models...';
      });

      final Map<String, dynamic> validation = await _service.validateModels(
        threadCount: _threadCount,
      );

      const JsonEncoder encoder = JsonEncoder.withIndent('  ');

      if (!mounted) {
        return;
      }

      setState(() {
        _isRunning = false;
        _status = 'All ONNX models loaded successfully.';
        _output = encoder.convert(<String, dynamic>{
          'runtime': runtime,
          'validation': validation,
        });
      });
    } catch (error, stackTrace) {
      debugPrint('Paddle ONNX validation failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isRunning = false;
        _status = 'Validation failed';
        _output = error.toString();
      });
    }
  }

  // Temporary full-page offline OCR test.
  // Remove once the offline pipeline is connected to scan_result_screen.dart.
  Future<void> _scanFullPage(ImageSource source) async {
    if (_isScanning || _isRunning) {
      return;
    }

    final XFile? picked = await _picker.pickImage(source: source);

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _isScanning = true;
      _scanStatus = 'Loading offline OCR models...';
      _scanError = null;
      _scanResult = null;
      _imagePath = picked.path;
      _initWallMs = null;
      _scanWallMs = null;
    });

    try {
      final Stopwatch initWatch = Stopwatch()..start();
      await _service.initializeOcr(threadCount: _threadCount);
      initWatch.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        _initWallMs = initWatch.elapsedMilliseconds;
        _scanStatus = 'Running full-page OCR...';
      });

      final Stopwatch scanWatch = Stopwatch()..start();
      final OfflineOcrResult result = await _service.recognizeImageResult(
        imagePath: picked.path,
        threadCount: _threadCount,
      );
      scanWatch.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        _isScanning = false;
        _scanWallMs = scanWatch.elapsedMilliseconds;
        _scanResult = result;
        _scanStatus = result.isEmpty
            ? 'Scan finished — no text detected.'
            : 'Scan finished — ${result.blocks.length} lines detected.';
      });
    } catch (error, stackTrace) {
      debugPrint('Offline full-page OCR failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isScanning = false;
        _scanStatus = 'Scan failed';
        _scanError = error is PaddleOnnxNativeException && error.code != null
            ? '[${error.code}] ${error.message}'
            : error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool busy = _isRunning || _isScanning;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Paddle ONNX Test')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: <Widget>[
              // ---- Full-page OCR test ----
              Text('Full-page offline OCR', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed:
                        busy ? null : () => _scanFullPage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Scan with camera'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        busy ? null : () => _scanFullPage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Pick from gallery'),
                  ),
                ],
              ),
              if (_isScanning) ...<Widget>[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              if (_scanStatus.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text(_scanStatus, style: textTheme.titleMedium),
              ],
              if (_scanError != null) ...<Widget>[
                const SizedBox(height: 8),
                SelectableText(
                  _scanError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_imagePath != null) ...<Widget>[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_imagePath!),
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
              if (_scanResult != null) ...<Widget>[
                const SizedBox(height: 16),
                _buildScanMetrics(textTheme, _scanResult!),
                const SizedBox(height: 16),
                ..._scanResult!.blocks.map(
                  (OfflineOcrBlock block) => _buildBlockTile(context, block),
                ),
              ],

              const Divider(height: 48),

              // ---- Model validation (existing) ----
              Text('Model validation', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              if (_isRunning) ...<Widget>[
                const LinearProgressIndicator(),
                const SizedBox(height: 20),
              ],
              Text(_status, style: textTheme.titleMedium),
              if (_output.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                SelectableText(_output),
              ],
              if (!_isRunning) ...<Widget>[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: busy ? null : _runValidation,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Run Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanMetrics(TextTheme textTheme, OfflineOcrResult result) {
    final String metrics = <String>[
      'Lines: ${result.lineCount} (blocks: ${result.blocks.length})',
      'Detection: ${result.detectionTimeMs} ms',
      'Recognition: ${result.recognitionTimeMs} ms',
      'Native total: ${result.totalTimeMs} ms',
      'Cold load (native): ${result.coldLoadTimeMs} ms',
      if (_initWallMs != null) 'initializeOcr round trip: $_initWallMs ms',
      if (_scanWallMs != null) 'Scan round trip (Flutter): $_scanWallMs ms',
      'Threads: ${result.threadCount}',
    ].join('\n');

    return SelectableText(metrics, style: textTheme.bodyMedium);
  }

  Widget _buildBlockTile(BuildContext context, OfflineOcrBlock block) {
    final bool isLow = block.confidence < _lowConfidence;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: isLow ? colors.errorContainer : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '#${block.index}  •  '
              '${(block.confidence * 100).toStringAsFixed(1)}%  •  '
              'top ${block.top.toStringAsFixed(0)}, '
              'left ${block.left.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            SelectableText(
              block.text.isEmpty ? '(empty)' : block.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}