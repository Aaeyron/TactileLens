import 'dart:convert';

import 'package:flutter/material.dart';

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

class _PaddleOnnxBenchmarkScreenState
    extends State<PaddleOnnxBenchmarkScreen> {
  final PaddleOnnxNativeService _service =
      const PaddleOnnxNativeService();

  bool _isRunning = true;
  String _status = 'Preparing ONNX Runtime...';
  String _output = '';

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
      final Map<String, dynamic> runtime =
          await _service.runtimeInfo();

      if (!mounted) {
        return;
      }

      setState(() {
        _status =
            'ONNX Runtime ${runtime['version']}\n'
            'Copying and validating models...';
      });

      final Map<String, dynamic> validation =
          await _service.validateModels(
            threadCount: 4,
          );

      const JsonEncoder encoder = JsonEncoder.withIndent('  ');

      if (!mounted) {
        return;
      }

      setState(() {
        _isRunning = false;
        _status = 'All ONNX models loaded successfully.';
        _output = encoder.convert(
          <String, dynamic>{
            'runtime': runtime,
            'validation': validation,
          },
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Paddle ONNX Test'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: <Widget>[
              if (_isRunning) ...<Widget>[
                const LinearProgressIndicator(),
                const SizedBox(height: 20),
              ],
              Text(
                _status,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_output.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                SelectableText(_output),
              ],
              if (!_isRunning) ...<Widget>[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _runValidation,
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
}