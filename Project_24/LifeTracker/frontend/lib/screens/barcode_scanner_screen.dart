import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isStartingScanner = false;
  bool _handlingScanResult = false;
  String? _scannerErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScanner());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_handlingScanResult) {
          unawaited(_startScanner());
        }
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_controller.stop());
    }
  }

  Future<void> _startScanner() async {
    if (!mounted || _handlingScanResult) return;
    if (_isStartingScanner ||
        _controller.value.isStarting ||
        _controller.value.isRunning) {
      return;
    }

    _isStartingScanner = true;
    if (mounted) {
      setState(() {
        _scannerErrorMessage = null;
      });
    }

    var startedSuccessfully = false;
    try {
      await _controller.start();
      startedSuccessfully = true;
    } on MobileScannerException catch (error) {
      if (!mounted) return;
      setState(() {
        _scannerErrorMessage = _friendlyErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _scannerErrorMessage =
            'Unable to open the camera scanner. Please try again.';
      });
      debugPrint('Barcode scanner start failed: $error');
    } finally {
      _isStartingScanner = false;
    }

    if (!startedSuccessfully || !mounted) {
      return;
    }

    final controllerError = _controller.value.error;
    if (controllerError != null) {
      setState(() {
        _scannerErrorMessage = _friendlyErrorMessage(controllerError);
      });
      return;
    }

    if (!_controller.value.hasCameraPermission) {
      setState(() {
        _scannerErrorMessage =
            'Camera permission is required to scan barcodes.';
      });
      return;
    }

    setState(() {
      _scannerErrorMessage = null;
    });
  }

  String _friendlyErrorMessage(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera permission is required to scan barcodes.',
      MobileScannerErrorCode.unsupported =>
        'Barcode scanning is not supported on this device.',
      MobileScannerErrorCode.controllerAlreadyInitialized =>
        'The scanner is already running.',
      MobileScannerErrorCode.controllerInitializing =>
        'The scanner is still starting. Please wait a moment.',
      MobileScannerErrorCode.controllerNotAttached =>
        'The scanner is still preparing. Please try again.',
      MobileScannerErrorCode.controllerDisposed =>
        'The scanner was closed unexpectedly.',
      MobileScannerErrorCode.controllerUninitialized =>
        'The scanner is not ready yet.',
      MobileScannerErrorCode.genericError =>
        error.errorDetails?.message ??
            'An unexpected error occurred while opening the camera.',
    };
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_handlingScanResult || !mounted) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    _handlingScanResult = true;
    await _controller.stop();
    if (!mounted) return;
    Navigator.pop(context, barcode);
  }

  Future<void> _retryScanner() async {
    await _startScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.stop());
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scannerError = _scannerErrorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product Barcode'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            useAppLifecycleState: false,
            onDetect: _handleBarcode,
            errorBuilder: (context, error) {
              return _ScannerErrorView(
                title: 'Scanner unavailable',
                message: _friendlyErrorMessage(error),
                icon: Icons.no_photography_outlined,
                actionLabel: 'Try again',
                onActionPressed: _retryScanner,
              );
            },
            placeholderBuilder: (context) {
              return ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
          if (_handlingScanResult)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (scannerError != null)
            ColoredBox(
              color: colorScheme.surface.withValues(alpha: 0.92),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _ScannerErrorView(
                    title: 'Camera access needed',
                    message: scannerError,
                    icon: Icons.camera_alt_outlined,
                    actionLabel: 'Try again',
                    onActionPressed: _retryScanner,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({
    required this.title,
    required this.message,
    required this.icon,
    required this.actionLabel,
    required this.onActionPressed,
  });

  final String title;
  final String message;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
