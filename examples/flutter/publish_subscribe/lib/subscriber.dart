import 'dart:isolate';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'iceoryx2_bindings.dart';

void main() {
  runApp(const SubscriberApp());
}

class SubscriberApp extends StatelessWidget {
  const SubscriberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iceoryx2 Subscriber',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const SubscriberScreen(),
    );
  }
}

class SubscriberScreen extends StatefulWidget {
  const SubscriberScreen({super.key});

  @override
  State<SubscriberScreen> createState() => _SubscriberScreenState();
}

class _SubscriberScreenState extends State<SubscriberScreen> {
  Pointer<Void>? _node;
  Pointer<Void>? _subscriber;
  final List<String> _receivedMessages = [];
  bool _isInitialized = false;
  bool _isListening = false;
  String _status = 'Not initialized';
  Isolate? _waitsetIsolate;
  ReceivePort? _waitsetReceivePort;

  @override
  void initState() {
    super.initState();
    _initializeIceoryx2();
  }

  void _initializeIceoryx2() async {
    try {
      print('[Subscriber] Starting initialization...');
      setState(() {
        _status = 'Initializing...';
      });

      // Create node
      print('[Subscriber] Creating iceoryx2 node...');
      _node = Iceoryx2.createNode();
      print('[Subscriber] Node created successfully');

      // Create subscriber for service "flutter_example"
      print(
          '[Subscriber] Creating subscriber for service "flutter_example"...');
      _subscriber = Iceoryx2.createSubscriber(_node!, "flutter_example");
      print('[Subscriber] Subscriber created successfully');

      setState(() {
        _isInitialized = true;
        _status = 'Ready to receive';
      });
      print('[Subscriber] Initialization completed successfully');
    } catch (e) {
      print('[Subscriber] Initialization failed: $e');
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  void _startListening() async {
    if (!_isInitialized || _subscriber == null) {
      print(
          '[Subscriber] Cannot start listening: not initialized or subscriber is null');
      return;
    }

    print('[Subscriber] Starting WaitSet-based message listening...');
    setState(() {
      _isListening = true;
      _status = 'WaitSet listening (CPU efficient)';
    });

    _waitsetReceivePort = ReceivePort();
    _waitsetIsolate = await Isolate.spawn<_WaitSetIsolateArgs>(
      _waitsetIsolateEntry,
      _WaitSetIsolateArgs(
        sendPort: _waitsetReceivePort!.sendPort,
        subscriberAddress: _subscriber!.address,
      ),
    );

    _waitsetReceivePort!.listen((message) {
      if (message is String) {
        setState(() {
          _receivedMessages.insert(
              0, '${DateTime.now().toIso8601String()}: $message');
          _status = 'Received: $message';
        });
      }
    });
  }

  void _stopListening() {
    print('[Subscriber] Stopping WaitSet listener...');
    setState(() {
      _isListening = false;
      _status = 'Stopped WaitSet listening';
    });
    _waitsetIsolate?.kill(priority: Isolate.immediate);
    _waitsetIsolate = null;
    _waitsetReceivePort?.close();
    _waitsetReceivePort = null;
    print('[Subscriber] WaitSet listener stopped');
  }

  void _checkOnce() {
    if (!_isInitialized || _subscriber == null) {
      print('[Subscriber] Cannot check: not initialized or subscriber is null');
      return;
    }

    print('[Subscriber] Checking for messages once...');
    try {
      final message = Iceoryx2.receive(_subscriber!);
      if (message != null) {
        print('[Subscriber] Found message: "$message"');
        setState(() {
          _receivedMessages.insert(
              0, '${DateTime.now().toIso8601String()}: $message');
          _status = 'Received: $message';
        });
      } else {
        print('[Subscriber] No messages available');
        setState(() {
          _status = 'No messages available';
        });
      }
    } catch (e) {
      print('[Subscriber] Error checking for messages: $e');
      setState(() {
        _status = 'Error receiving: $e';
      });
    }
  }

  @override
  void dispose() {
    print('[Subscriber] Starting cleanup...');
    _stopListening();
    // Clean up iceoryx2 resources
    if (_subscriber != null) {
      print('[Subscriber] Dropping subscriber...');
      Iceoryx2.dropSubscriber(_subscriber!);
      print('[Subscriber] Subscriber dropped');
    }
    if (_node != null) {
      print('[Subscriber] Dropping node...');
      Iceoryx2.dropNode(_node!);
      print('[Subscriber] Node dropped');
    }
    print('[Subscriber] Cleanup completed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iceoryx2 Subscriber'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isInitialized
                              ? (_isListening
                                  ? Icons.play_arrow
                                  : Icons.check_circle)
                              : Icons.error,
                          color: _isInitialized
                              ? (_isListening ? Colors.orange : Colors.green)
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_status)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isInitialized && !_isListening
                              ? _startListening
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Event-Driven'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isListening ? _stopListening : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Stop Event-Driven'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isInitialized && !_isListening
                              ? _checkOnce
                              : null,
                          child: const Text('Check Once'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Received messages list
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Received Messages (${_receivedMessages.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_receivedMessages.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _receivedMessages.clear();
                                });
                              },
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _receivedMessages.isEmpty
                            ? const Center(
                                child: Text('No messages received yet'),
                              )
                            : ListView.builder(
                                itemCount: _receivedMessages.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: ListTile(
                                      dense: true,
                                      leading:
                                          const Icon(Icons.inbox, size: 16),
                                      title: Text(
                                        _receivedMessages[index],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitSetIsolateArgs {
  final SendPort sendPort;
  final int subscriberAddress;
  _WaitSetIsolateArgs(
      {required this.sendPort, required this.subscriberAddress});
}

void _waitsetIsolateEntry(_WaitSetIsolateArgs args) {
  final Pointer<Void> sub = Pointer.fromAddress(args.subscriberAddress);
  final waitset = Iceoryx2.createWaitSet();
  Iceoryx2.attachSubscriberToWaitSet(waitset, sub);
  while (true) {
    Iceoryx2.waitForEvent(waitset); // 이벤트 발생 시까지 블록
    final msg = Iceoryx2.receive(sub);
    if (msg != null) {
      args.sendPort.send(msg);
    }
  }
}
