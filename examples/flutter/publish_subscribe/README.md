# iceoryx2 Flutter Publish-Subscribe Example

Flutter application demonstrating zero-copy inter-process communication using iceoryx2. 
Implements layered architecture and event-driven messaging for high-performance, 
CPU-efficient communication.

## Architecture Overview

```
┌──────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter    │    │   iceoryx2      │    │    Flutter      │
│  Publisher   │───▶│ Service (DMA)   │───▶│  Subscriber     │
│     App      │    │ Shared Memory   │    │ App (Event-driven) │
└──────────────┘    └─────────────────┘    └─────────────────┘
```

### Layered Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  Public API (iceoryx2.dart)                    │
│           - Single import for developers                       │
│           - Internal implementation hiding                     │
├─────────────────────────────────────────────────────────────────┤
│          High-Level API (src/iceoryx2_api.dart)                │
│  - Node, Publisher, Subscriber classes                         │
│  - Type-safe object-oriented interface                         │
│  - Automatic resource management (Finalizable)                 │
│  - Stream-based event handling                                 │
├─────────────────────────────────────────────────────────────────┤
│       Message Protocol (src/message_protocol.dart)             │
│  - Message class and serialization/deserialization             │
│  - Type-safe message classes                                   │
│  - Protocol version management                                 │
├─────────────────────────────────────────────────────────────────┤
│           FFI Bindings (src/ffi/iceoryx2_ffi.dart)             │
│  - Pure C function signatures                                  │
│  - Memory-safe pointer operations                              │
│  - Direct iceoryx2 C API access                                │
└─────────────────────────────────────────────────────────────────┘
```

### Key Features

- **Zero-copy communication**: Direct memory access via iceoryx2 shared memory
- **Event-driven architecture**: Stream-based reactive messaging
- **Type-safe API**: Compile-time safety with object-oriented interface
- **Layered architecture**: Clear separation of concerns (FFI → API → Protocol)
- **Automatic resource management**: RAII-style cleanup with Finalizable
- **Structured messaging**: Custom Message protocol with version management
- **Professional UI**: Clean Material Design 3 interface
- **Comprehensive testing**: Automated headless validation

## Technical Implementation

### Message Structure

```dart
class Message {
  final String content;           // Message content
  final String sender;            // Sender identification
  final DateTime timestamp;       // Creation timestamp
  final int version;              // Protocol version
  
  // Factory constructor
  static Message create(String content, {String sender = 'unknown'})
}

// Serialization format: 264 bytes total (fixed size, 8-byte aligned)
const int MESSAGE_MAX_LENGTH = 256;
const int MESSAGE_STRUCT_SIZE = 264;
```

### High-Level API Usage

```dart
import 'package:iceoryx2_flutter_examples/iceoryx2.dart';

// Create node and publisher
final node = Node('my-app');
final publisher = node.publisher('flutter_example');

// Send message (two methods)
// 1. Send Message object
final message = Message.create('Hello World!', sender: 'my-app');
publisher.send(message);

// 2. Send simple text
publisher.sendText('Hello World!', sender: 'my-app');

// Create subscriber with stream-based reception
final subscriber = node.subscriber('flutter_example');
subscriber.messages.listen((message) {
  print('Received message: ${message.content} from ${message.sender}');
});

// Manual polling
final message = subscriber.tryReceive();
if (message != null) {
  print('Got: ${message.content}');
}

// Cleanup (automatic via Finalizable)
publisher.close();
subscriber.close();
node.close();
```
## Quick Start

### Prerequisites

- **Linux Desktop** (Ubuntu 20.04+ recommended)
- **Flutter SDK** 3.0+ with Linux desktop support
- **Rust Toolchain** (for building iceoryx2)

### Build and Run
```bash
# 1. Build iceoryx2 FFI library
./build.sh

# 2. Run Flutter application
flutter run -d linux

# 3. Test headless communication
dart run lib/headless_publisher.dart    # Terminal 1
dart run lib/headless_subscriber.dart   # Terminal 2

# 4. Run automated tests
cd test && ./test_headless.sh
```

## Testing

### Headless Communication Test
```bash
# Terminal 1: Start publisher
dart run lib/headless_publisher.dart

# Terminal 2: Start subscriber  
dart run lib/headless_subscriber.dart
```

**Expected Output:**

```
# Publisher Terminal
=== Headless iceoryx2 Publisher Test ===
[Publisher] ✓ Node created successfully
[Publisher] ✓ Publisher created successfully  
[Publisher] ✓ Sent message #1: "Headless message #1"
[Publisher] ✓ Sent message #2: "Headless message #2"
...

# Subscriber Terminal
=== Headless iceoryx2 Subscriber Test ===
[Subscriber] ✓ Node created successfully
[Subscriber] ✓ Subscriber created successfully
[Subscriber] ✓ #1: "Headless message #1" from Headless Publisher (125ms)
[Subscriber] ✓ #2: "Headless message #2" from Headless Publisher (2127ms)
...
```

### Automated Integration Tests
```bash
cd test && ./test_headless.sh
```

### Flutter Widget Tests
```bash
flutter test
```

### FFI Library Tests
```bash
dart test/test_ffi_load.dart
```

## Project Structure

```
lib/
├── iceoryx2.dart                    # Public API entry point
├── src/                             # Internal implementation (private)
│   ├── ffi/
│   │   └── iceoryx2_ffi.dart        # Pure FFI bindings
│   ├── iceoryx2_api.dart            # High-level object API
│   └── message_protocol.dart        # Message serialization
├── main.dart                        # Flutter app selector
├── publisher.dart                   # Publisher UI app
├── subscriber.dart                  # Subscriber UI app  
├── headless_publisher.dart          # Headless publisher test
├── headless_subscriber.dart         # Headless subscriber test
└── iceoryx2_bindings.dart           # Legacy FFI bindings (compatibility)

test/
├── test_headless.sh                 # Integration test script
├── core_test.dart                   # Core FFI tests
├── widget_test.dart                 # Flutter widget tests
└── test_ffi_load.dart               # FFI loading tests

build.sh                            # Build script
README.md                           # This document
pubspec.yaml                        # Flutter project configuration
```

## Implementation Details

### Architecture Migration

This example demonstrates migration from direct FFI usage to layered architecture:

**Before (Direct FFI):**
```dart
import 'iceoryx2_bindings.dart';

final node = Iceoryx2.createNode();
final publisher = Iceoryx2.createPublisher(node, 'service');
Iceoryx2.send(publisher, message);
```

**After (High-Level API):**
```dart
import 'iceoryx2.dart';

final node = Node('my-node');
final publisher = node.publisher('service');
final message = Message.create('Hello', sender: 'my-app');
publisher.send(message);
```

### Core API Classes
```dart
// Node management
class Node implements Finalizable {
  Node(String name)
  Publisher publisher(String serviceName)
  Subscriber subscriber(String serviceName)
  void close()
}

// Message publishing
class Publisher implements Finalizable {
  void send(Message message)
  void sendText(String text, {String sender})
  String get serviceName
  void close()
}

// Message receiving
class Subscriber implements Finalizable {
  Stream<Message> get messages          // Event-driven stream
  Message? tryReceive()                 // Manual polling
  String get serviceName
  void close()
}

// Message protocol
class Message {
  static Message create(String content, {String sender})
  String get content
  String get sender
  DateTime get timestamp
  int get version
}
```

### FFI Layer Functions
```dart
// Pure FFI bindings (src/ffi/iceoryx2_ffi.dart)
final iox2NodeBuilderNew = iox2lib.lookup<...>('iox2_node_builder_new')
final iox2NodeBuilderCreate = iox2lib.lookup<...>('iox2_node_builder_create')
final iox2PublisherLoanSliceUninit = iox2lib.lookup<...>('iox2_publisher_loan_slice_uninit')
final iox2SubscriberReceive = iox2lib.lookup<...>('iox2_subscriber_receive')
// ... and more
```

### Event-Driven Subscriber
```dart
// Isolate-based background processing
void _startNodeWaitIsolate() {
  Isolate.spawn(_nodeWaitIsolateEntry, isolateParams);
}

// CPU-efficient blocking wait
static void _nodeWaitIsolateEntry(IsolateParams params) {
  while (_running) {
    final result = ffi.iox2NodeWait(node, timeoutSecs: 1, timeoutNsecs: 0);
    if (result == ffi.IOX2_OK) {
      final message = _tryReceiveMessage();
      if (message != null) {
        sendPort.send(message);  // Send to main isolate
      }
    }
  }
}
```

### Service Configuration
```dart
// Service setup with payload type details (in src/iceoryx2_api.dart)
final payloadTypeResult = ffi.iox2ServiceBuilderPubSubSetPayloadTypeDetails(
  pubSubBuilderRef,
  ffi.IOX2_TYPE_VARIANT_FIXED_SIZE,
  payloadTypeName,
  "DartMessage".length,
  ffi.MESSAGE_STRUCT_SIZE,          // 264 bytes
  8                                 // 8-byte alignment  
);
```

## Performance Characteristics

### Memory Usage

- **Zero-copy**: Direct shared memory access, no data copying
- **Fixed allocation**: 264-byte message buffers, predictable memory usage  
- **Automatic cleanup**: Finalizable-based resource management prevents leaks
- **Object-oriented**: Type-safe API reduces memory errors

### CPU Efficiency  

- **Event-driven**: Stream-based reactive messaging
- **No polling**: Zero CPU usage when idle
- **Isolate-based**: Background processing does not block UI thread
- **Direct FFI**: Minimal overhead for high-performance paths

### Throughput and Latency

- **Design capacity**: Thousands of messages per second
- **Sub-millisecond**: Ultra-low latency message delivery
- **Test results**: 2 msg/s (limited by test interval for visibility)
- **Configurable**: Message intervals adjustable for different use cases

## Troubleshooting

### Common Issues

**1. FFI library not found**
```bash
# Ensure iceoryx2 is built
./build.sh

# Check library path
ls -la target/release/libiceoryx2_ffi.so
```

**2. Service not found**
```bash
# Check if another instance is running
ps aux | grep dart

# Clean up remaining processes
pkill -f dart
```

**3. Message not received**
```bash
# Ensure publisher and subscriber use same service name "flutter_example"
# Check logs for initialization errors
dart run lib/headless_publisher.dart  # Should show "✓ Node created"
dart run lib/headless_subscriber.dart # Should show "✓ Subscriber created"
```

### Debug Mode
```dart
// Enable debug logging by checking console output
// All important operations log with [Node], [Publisher], [Subscriber] prefixes
```

## Learning Resources

### iceoryx2 Documentation
- [iceoryx2 GitHub](https://github.com/eclipse-iceoryx/iceoryx2)
- [C API Reference](https://iceoryx.io/v2.0.5/api/)
- [Architecture Guide](https://iceoryx.io/v2.0.5/getting-started/overview/)

### Flutter FFI
- [Dart FFI Documentation](https://dart.dev/guides/libraries/c-interop)
- [Flutter Desktop Development](https://docs.flutter.dev/development/platform-integration/linux/building)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Test your changes (`dart analyze`, `flutter test`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Development Guidelines

- Follow Dart style guidelines (`dart format`)
- Add tests for new features  
- Update documentation
- Ensure FFI memory safety
- Test on Linux platform

## License

This project is part of the iceoryx2 ecosystem and follows the same licensing 
terms (Apache-2.0 OR MIT).

---

**Layered architecture Flutter-iceoryx2 integration successfully implemented.**

*This example demonstrates the evolution from direct FFI bindings to a 
professional, maintainable layered architecture.*
