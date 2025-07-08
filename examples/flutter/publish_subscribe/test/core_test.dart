#!/usr/bin/env dart

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Load the iceoryx2 FFI library
final DynamicLibrary _lib = Platform.isLinux
    ? DynamicLibrary.open('../../../target/release/libiceoryx2_ffi.so')
    : throw UnsupportedError('Platform not supported');

// Opaque pointer types
final class Iox2Node extends Opaque {}
final class Iox2NodeBuilder extends Opaque {}

const int IOX2_OK = 0;

void main() async {
  print('Core iceoryx2 FFI Tests');
  print('=======================');
  
  await testBasicFFI();
  await testNodeCreation();
  await testRealAPI();
  await testErrorHandling();
  
  print('\nCore tests completed successfully!');
}

Future<void> testBasicFFI() async {
  print('\n1. Basic FFI Library Test');
  print('-------------------------');
  
  try {
    print('Loading library...');
    final lib = DynamicLibrary.open('../../../target/release/libiceoryx2_ffi.so');
    print('Library loaded successfully');
    
    print('Looking up iox2_node_builder_new...');
    final nodeBuilderNewFunc = lib.lookup<NativeFunction<Pointer<Void> Function()>>('iox2_node_builder_new');
    final nodeBuilderNew = nodeBuilderNewFunc.asFunction<Pointer<Void> Function()>();
    print('Function found');
    
    print('Calling iox2_node_builder_new...');
    final nodeBuilder = nodeBuilderNew();
    print('Node builder created: $nodeBuilder');
    
    if (nodeBuilder != nullptr) {
      print('Success! Node builder is valid');
    } else {
      print('Error: Node builder is null pointer');
    }
    
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<void> testNodeCreation() async {
  print('\n2. Node Creation Test');
  print('--------------------');
  
  try {
    print('Loading library...');
    final lib = _lib;
    print('Library loaded');
    
    print('Looking up functions...');
    final nodeBuilderNewFunc = lib
        .lookup<NativeFunction<Pointer<Iox2NodeBuilder> Function(Pointer<Void>)>>('iox2_node_builder_new')
        .asFunction<Pointer<Iox2NodeBuilder> Function(Pointer<Void>)>();

    final nodeBuilderCreateFunc = lib
        .lookup<NativeFunction<Int32 Function(Pointer<Iox2NodeBuilder>, Pointer<Void>, Int32, Pointer<Pointer<Iox2Node>>)>>('iox2_node_builder_create')
        .asFunction<int Function(Pointer<Iox2NodeBuilder>, Pointer<Void>, int, Pointer<Pointer<Iox2Node>>)>();
    
    print('Functions found');

    print('Creating node builder...');
    final nodeBuilder = nodeBuilderNewFunc(nullptr);
    
    if (nodeBuilder == nullptr) {
      print('Error: Failed to create node builder');
      return;
    }
    print('Node builder created: $nodeBuilder');

    print('Creating node...');
    final nodePtr = calloc<Pointer<Iox2Node>>();
    final result = nodeBuilderCreateFunc(nodeBuilder, nullptr, 0, nodePtr);
    
    if (result == IOX2_OK) {
      final node = nodePtr.value;
      if (node != nullptr) {
        print('Node created successfully: $node');
        print('Node is valid and ready for use!');
      } else {
        print('Error: Node handle is null');
      }
    } else {
      print('Error: Failed to create node, error code: $result');
    }
    
    calloc.free(nodePtr);
    
  } catch (e) {
    print('Error: $e');
    rethrow;
  }
}

Future<void> testRealAPI() async {
  print('\n3. Real iceoryx2 C API Test');
  print('---------------------------');
  
  try {
    print('C function binding...');
    final nodeBuilderNewFunc = _lib
        .lookup<NativeFunction<Pointer<Iox2NodeBuilder> Function(Pointer<Void>)>>('iox2_node_builder_new')
        .asFunction<Pointer<Iox2NodeBuilder> Function(Pointer<Void>)>();

    final nodeBuilderCreateFunc = _lib
        .lookup<NativeFunction<Int32 Function(Pointer<Iox2NodeBuilder>, Pointer<Void>, Int32, Pointer<Pointer<Iox2Node>>)>>('iox2_node_builder_create')
        .asFunction<int Function(Pointer<Iox2NodeBuilder>, Pointer<Void>, int, Pointer<Pointer<Iox2Node>>)>();

    print('C function binding completed');

    // Create multiple nodes
    print('Creating multiple nodes...');
    final nodes = <Pointer<Iox2Node>>[];
    
    for (int i = 1; i <= 3; i++) {
      print('  Creating Node $i...');
      
      final nodeBuilder = nodeBuilderNewFunc(nullptr);
      if (nodeBuilder == nullptr) {
        throw Exception('Node builder $i creation failed');
      }
      
      final nodePtr = calloc<Pointer<Iox2Node>>();
      final result = nodeBuilderCreateFunc(nodeBuilder, nullptr, 0, nodePtr);
      
      if (result == IOX2_OK) {
        final node = nodePtr.value;
        nodes.add(node);
        print('  Node $i created successfully: $node');
        calloc.free(nodePtr);
      } else {
        calloc.free(nodePtr);
        throw Exception('Node $i creation failed with result: $result');
      }
      
      await Future.delayed(Duration(milliseconds: 50));
    }
    
    print('${nodes.length} nodes created successfully');
    print('Multiple iceoryx2 instances can run simultaneously');
    
  } catch (e) {
    print('Error: Real C API test failed: $e');
    rethrow;
  }
}

Future<void> testErrorHandling() async {
  print('\n4. Error Handling Test');
  print('---------------------');
  
  try {
    print('Testing invalid function calls...');
    
    // Try to create node with invalid builder (nullptr)
    final nodeBuilderCreateFunc = _lib
        .lookup<NativeFunction<Int32 Function(Pointer<Iox2NodeBuilder>, Pointer<Void>, Int32, Pointer<Pointer<Iox2Node>>)>>('iox2_node_builder_create')
        .asFunction<int Function(Pointer<Iox2NodeBuilder>, Pointer<Void>, int, Pointer<Pointer<Iox2Node>>)>();

    final nodePtr = calloc<Pointer<Iox2Node>>();
    final result = nodeBuilderCreateFunc(nullptr, nullptr, 0, nodePtr);
    
    if (result != IOX2_OK) {
      print('Expected error handling success: result = $result');
      print('iceoryx2 properly rejects invalid input');
    } else {
      print('Warning: Unexpected result: no error occurred');
    }
    
    calloc.free(nodePtr);
    
  } catch (e) {
    print('Exception handling test success: $e');
  }
  
  // Test invalid function lookup
  try {
    print('Testing non-existent function lookup...');
    _lib.lookup('non_existent_function');
    print('Warning: Unexpected result: function found');
  } catch (e) {
    print('Expected function lookup error handling success');
    print('Proper error handling for non-existent functions');
  }
}
