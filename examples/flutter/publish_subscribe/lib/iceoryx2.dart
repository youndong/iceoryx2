/// iceoryx2 Flutter Package
///
/// This library provides a high-level Dart API for iceoryx2 inter-process communication.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:iceoryx2_flutter_examples/iceoryx2.dart';
///
/// // Create a node
/// final node = Node('my-app');
///
/// // Create a publisher
/// final publisher = node.publisher('my-service');
/// publisher.sendText('Hello, World!');
///
/// // Create a subscriber
/// final subscriber = node.subscriber('my-service');
/// subscriber.messages.listen((message) {
///   print('Received: ${message.content}');
/// });
///
/// // Clean up
/// publisher.close();
/// subscriber.close();
/// node.close();
/// ```
library iceoryx2;

// Export public API
export 'src/iceoryx2_api.dart'
    show Node, Publisher, Subscriber, Iceoryx2Exception;
export 'src/message_protocol.dart' show Message, MessageProtocol;

// Private implementations are not exported:
// - src/ffi/iceoryx2_ffi.dart (FFI bindings)
// - Legacy MessageHelper (deprecated)
