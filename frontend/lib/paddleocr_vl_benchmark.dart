import 'package:flutter/material.dart';

import 'services/ai/paddleocr_vl_native_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PaddleOcrVlBenchmarkApp());
}

class PaddleOcrVlBenchmarkApp extends StatelessWidget {
  const PaddleOcrVlBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PaddleOcrVlBenchmarkScreen(),
    );
  }
}

class PaddleOcrVlBenchmarkScreen extends StatefulWidget {
  const PaddleOcrVlBenchmarkScreen({super.key});

  @override
  State<PaddleOcrVlBenchmarkScreen> createState() =>
      _PaddleOcrVlBenchmarkScreenState();
}

class _PaddleOcrVlBenchmarkScreenState
    extends State<PaddleOcrVlBenchmarkScreen> {
  final PaddleOcrVlNativeService _service = const PaddleOcrVlNativeService();

  String _status = 'Preparing PaddleOCR-VL...';
  String _content = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runBenchmark();
    });
  }

  Future<void> _runBenchmark() async {
    try {
      final PaddleOcrVlRuntimeInfo runtime = await _service.initialize();
      final int separator = runtime.modelDirectory.lastIndexOf('/');
      final String filesDirectory = separator < 0
          ? runtime.modelDirectory
          : runtime.modelDirectory.substring(0, separator);
      final String imagePath = '$filesDirectory/input/equation.png';

      _updateStatus('Loading PaddleOCR-VL models...');

      final PaddleOcrVlModelLoadResult loadResult = await _service.loadModels(
        threadCount: 4,
      );

      if (!loadResult.success || !loadResult.loaded) {
        throw PaddleOcrVlNativeException(
          loadResult.error ?? 'The model files could not be loaded.',
        );
      }

      _updateStatus(
        'Models loaded in ${loadResult.loadTimeMs} ms.\n'
        'Recognizing the test image—please keep the app open...',
      );

      final PaddleOcrVlScanResult scanResult = await _service.scanImage(
        imagePath: imagePath,
        prompt: 'Formula Recognition:',
        maximumTokens: 128,
        threadCount: 4,
      );

      if (!scanResult.success) {
        throw PaddleOcrVlNativeException(
          scanResult.error ?? 'PaddleOCR-VL returned no OCR result.',
        );
      }

      debugPrint('PaddleOCR-VL scan time: ${scanResult.scanTimeMs} ms');
      debugPrint('PaddleOCR-VL result: ${scanResult.content}');

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Completed in ${scanResult.scanTimeMs} ms';
        _content = scanResult.content;
      });
    } catch (error, stackTrace) {
      debugPrint('PaddleOCR-VL benchmark failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Failed: $error';
      });
    }
  }

  void _updateStatus(String value) {
    if (!mounted) {
      return;
    }

    setState(() {
      _status = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline PaddleOCR-VL Test')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: <Widget>[
              const LinearProgressIndicator(),
              const SizedBox(height: 20),
              Text(_status, style: Theme.of(context).textTheme.titleMedium),
              if (_content.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                const Text('Recognized content:'),
                const SizedBox(height: 8),
                SelectableText(_content),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
