import 'dart:ffi';
import 'dart:io';
import 'dart:async';
import 'iceoryx2_bindings.dart';

/// Headless publisher for testing - sends messages automatically
/// No UI, pure console output for validation
void main() async {
  print('=== Headless iceoryx2 Publisher Test ===');
  print('Starting automatic message publisher...');

  final publisher = HeadlessPublisher();
  await publisher.initialize();

  // Handle graceful shutdown
  ProcessSignal.sigint.watch().listen((signal) {
    print('\nReceived SIGINT, shutting down gracefully...');
    publisher.stop();
    exit(0);
  });

  // Start publishing messages
  await publisher.startAutoPublish();

  // Keep main thread alive
  while (true) {
    await Future.delayed(Duration(seconds: 1));
  }
}

class HeadlessPublisher {
  Pointer<Void>? _node;
  Pointer<Void>? _publisher;
  Timer? _publishTimer;
  int _messageCounter = 0;
  int _successCount = 0;
  int _failureCount = 0;
  DateTime? _startTime;

  Future<void> initialize() async {
    try {
      print('[Publisher] Initializing iceoryx2...');

      // Create node
      print('[Publisher] Creating iceoryx2 node...');
      _node = Iceoryx2.createNode();
      print('[Publisher] ✓ Node created successfully');

      // Create publisher for service "flutter_example"
      print('[Publisher] Creating publisher for service "flutter_example"...');
      _publisher = Iceoryx2.createPublisher(_node!, "flutter_example");
      print('[Publisher] ✓ Publisher created successfully');

      print('[Publisher] ✓ Initialization completed');
    } catch (e) {
      print('[Publisher] ✗ Initialization failed: $e');
      rethrow;
    }
  }

  Future<void> startAutoPublish() async {
    if (_publisher == null) {
      throw Exception('Publisher not initialized');
    }

    print('[Publisher] Starting automatic message publishing...');
    print('[Publisher] Publishing interval: 500ms');

    _startTime = DateTime.now();

    // Publish messages every 500ms
    _publishTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _publishMessage();
    });

    print('[Publisher] ✓ Auto-publish started');
    print('[Publisher] Press Ctrl+C to stop');
  }

  void _publishMessage() {
    if (_publisher == null) return;

    _messageCounter++;
    final timestamp = DateTime.now().toIso8601String();
    final message = 'Test message #$_messageCounter at $timestamp';

    try {
      print('[Publisher] Publishing: "$message"');
      Iceoryx2.publish(_publisher!, message);

      _successCount++;
      print('[Publisher] ✓ Message #$_messageCounter published successfully');

      // Print stats every 10 messages
      if (_messageCounter % 10 == 0) {
        _printStats();
      }
    } catch (e) {
      _failureCount++;
      print('[Publisher] ✗ Error publishing message #$_messageCounter: $e');
    }
  }

  void _printStats() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      final rate = _messageCounter / duration.inSeconds;
      print(
          '[Stats] Total: $_messageCounter, Success: $_successCount, Failed: $_failureCount, Rate: ${rate.toStringAsFixed(2)} msg/s');
    }
  }

  void stop() {
    print('[Publisher] Stopping...');

    _publishTimer?.cancel();
    _publishTimer = null;

    // Clean up iceoryx2 resources
    if (_publisher != null) {
      print('[Publisher] Dropping publisher...');
      Iceoryx2.dropPublisher(_publisher!);
    }
    if (_node != null) {
      print('[Publisher] Dropping node...');
      Iceoryx2.dropNode(_node!);
    }

    _printFinalStats();
    print('[Publisher] ✓ Cleanup completed');
  }

  void _printFinalStats() {
    print('\n=== Final Statistics ===');
    print('Total messages: $_messageCounter');
    print('Successfully published: $_successCount');
    print('Failed to publish: $_failureCount');
    print(
        'Success rate: ${(_successCount / _messageCounter * 100).toStringAsFixed(2)}%');
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      final rate = _messageCounter / duration.inSeconds;
      print('Total duration: ${duration.inSeconds} seconds');
      print('Average publish rate: ${rate.toStringAsFixed(2)} messages/second');
    }
    print('========================');
  }
}
