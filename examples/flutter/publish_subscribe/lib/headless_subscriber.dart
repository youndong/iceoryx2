import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:ffi';
import 'iceoryx2_bindings.dart';

class HeadlessSubscriber {
  Pointer<Void>? _node;
  Pointer<Void>? _subscriber;
  bool _isRunning = false;
  int _messageCount = 0;
  
  ReceivePort? _receivePort;
  Isolate? _isolate;
  final _serviceName = 'flutter_example';
  DateTime? _startTime;

  Future<void> initialize() async {
    try {
      print('[Subscriber] Initializing iceoryx2...');
      
      print('[Subscriber] Creating iceoryx2 node...');
      _node = Iceoryx2.createNode();
      print('[Subscriber] ✓ Node created successfully');
      
      print('[Subscriber] Creating subscriber for service "$_serviceName"...');
      _subscriber = Iceoryx2.createSubscriber(_node!, _serviceName);
      print('[Subscriber] ✓ Subscriber created successfully');
      
      print('[Subscriber] ✓ Initialization completed');
    } catch (e) {
      print('[Subscriber] ✗ Initialization failed: $e');
      rethrow;
    }
  }

  Future<void> startListening() async {
    if (_subscriber == null || _node == null) {
      throw Exception('Subscriber or node not initialized');
    }

    print('[Subscriber] Starting event-driven listening with iox2_node_wait...');
    _isRunning = true;
    _startTime = DateTime.now();
    
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn<_NodeWaitArgs>(
      _nodeWaitIsolateEntry,
      _NodeWaitArgs(
        sendPort: _receivePort!.sendPort,
        nodeAddress: _node!.address,
        subscriberAddress: _subscriber!.address,
      ),
    );

    _receivePort!.listen((message) {
      if (message is String) {
        if (message.startsWith('ERROR:')) {
          print('[Subscriber] ✗ Error from node wait isolate: ${message.substring(6)}');
          return;
        }
        
        _messageCount++;
        print('[Subscriber] ✓ Received message #$_messageCount: "$message"');
        
        // Print stats every 10 messages
        if (_messageCount % 10 == 0) {
          _printStats();
        }
      }
    });
    
    print('[Subscriber] ✓ Event-driven listener started (CPU efficient, no polling)');
  }

  void _printStats() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      final rate = _messageCount / duration.inSeconds;
      print('[Stats] Received: $_messageCount messages, Rate: ${rate.toStringAsFixed(2)} msg/s');
    }
  }

  Future<void> stop() async {
    print('[Subscriber] Stopping...');
    _isRunning = false;
    
    if (_isolate != null) {
      print('[Subscriber] Terminating isolate...');
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }
    
    if (_receivePort != null) {
      _receivePort!.close();
      _receivePort = null;
    }
    
    await cleanup();
  }

  Future<void> cleanup() async {
    if (_subscriber != null) {
      print('[Subscriber] Dropping subscriber...');
      Iceoryx2.dropSubscriber(_subscriber!);
      _subscriber = null;
    }
    
    if (_node != null) {
      print('[Subscriber] Dropping node...');
      Iceoryx2.dropNode(_node!);
      _node = null;
    }
  }

  int get messageCount => _messageCount;
  bool get isRunning => _isRunning;
}

// Isolate args
class _NodeWaitArgs {
  final SendPort sendPort;
  final int nodeAddress;
  final int subscriberAddress;
  
  _NodeWaitArgs({
    required this.sendPort,
    required this.nodeAddress, 
    required this.subscriberAddress,
  });
}

// Isolate entry point for event-driven node waiting
void _nodeWaitIsolateEntry(_NodeWaitArgs args) {
  try {
    print('[Node Wait Isolate] Starting...');
    
    // Reconstruct pointers from addresses
    final node = Pointer<Void>.fromAddress(args.nodeAddress);
    final subscriber = Pointer<Void>.fromAddress(args.subscriberAddress);
    
    print('[Node Wait Isolate] Starting event-driven loop...');
    
    while (true) {
      try {
        // Block and wait for events on the node (event-driven, no polling!)
        final waitResult = Iceoryx2.nodeWait(node, timeoutSecs: 1);
        
        if (waitResult == 0) { // IOX2_OK
          // Check for messages
          final message = Iceoryx2.receive(subscriber);
          if (message != null) {
            args.sendPort.send(message);
          }
        }
        // If timeout or other result, continue loop
        
      } catch (e) {
        args.sendPort.send('ERROR:Exception in event loop: $e');
        break;
      }
    }
    
  } catch (e) {
    args.sendPort.send('ERROR:Fatal isolate error: $e');
  }
}

// Main function for headless testing
void main() async {
  print('=== Headless iceoryx2 Subscriber Test ===');
  print('Starting event-driven subscriber...');
  
  final subscriber = HeadlessSubscriber();
  
  // Handle graceful shutdown
  ProcessSignal.sigint.watch().listen((signal) async {
    print('\\nReceived SIGINT, shutting down gracefully...');
    await subscriber.stop();
    print('\\n=== Final Statistics ===');
    print('Total messages received: ${subscriber.messageCount}');
    print('========================');
    print('[Subscriber] ✓ Cleanup completed');
    exit(0);
  });
  
  try {
    await subscriber.initialize();
    await subscriber.startListening();
    
    print('Subscriber is running. Press Ctrl+C to stop.');
    
    // Keep the main isolate alive
    while (subscriber.isRunning) {
      await Future.delayed(Duration(seconds: 1));
    }
    
  } catch (e) {
    print('Error: $e');
    await subscriber.cleanup();
    exit(1);
  }
}
