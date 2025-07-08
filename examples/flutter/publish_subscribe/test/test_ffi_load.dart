import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Simple FFI library loading test for iceoryx2
/// This test verifies that the iceoryx2 FFI library can be loaded and basic functions are accessible
void main() {
  print('=== iceoryx2 FFI Library Loading Test ===');
  
  try {
    // Try to find the library in different possible locations
    String? libPath;
    final possiblePaths = [
      '/home/youndong/projects/iceoryx2/iceoryx2/target/release/libiceoryx2_ffi.so',
      '../../../target/release/libiceoryx2_ffi.so',
      '../../../../target/release/libiceoryx2_ffi.so'
    ];
    
    for (final path in possiblePaths) {
      if (File(path).existsSync()) {
        libPath = path;
        break;
      }
    }
    
    if (libPath == null) {
      throw Exception('Could not find libiceoryx2_ffi.so in any of the expected locations');
    }
    
    // Load the library
    final lib = Platform.isLinux
        ? DynamicLibrary.open(libPath)
        : DynamicLibrary.open('libiceoryx2_ffi.so');
    
    print('✓ Library loaded successfully: $lib');
    
    // Test function lookup with correct signature
    final nodeBuilderNew = lib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>),
        Pointer<Void> Function(Pointer<Void>)>('iox2_node_builder_new');
    
    print('✓ Function lookup successful: $nodeBuilderNew');
    
    // Test calling the function with nullptr (as done in C examples)
    print('Testing function call with nullptr...');
    final result = nodeBuilderNew(nullptr);
    print('✓ Function call successful, result: $result');
    
    print('\\n=== Test Summary ===');
    print('✅ FFI library loading: SUCCESS');
    print('✅ Function lookup: SUCCESS'); 
    print('✅ Function call: SUCCESS');
    print('✅ All tests passed!');
    
  } catch (e, stackTrace) {
    print('\\n=== Test Summary ===');
    print('❌ FFI library test: FAILED');
    print('Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
