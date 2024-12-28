import 'dart:io';

void main() {
  final directory = Directory('lib');
  final outputFile = File('combined_code.dart');

  // Write initial comment
  outputFile.writeAsStringSync('// Combined Flutter Code\n\n');

  // Recursively process all Dart files
  directory.listSync(recursive: true).forEach((file) {
    if (file is File && file.path.endsWith('.dart')) {
      // Write file header as a comment
      outputFile.writeAsStringSync(
          '\n// ==========================\n// File: ${file.path}\n// ==========================\n',
          mode: FileMode.append);

      // Write file content
      outputFile.writeAsStringSync(file.readAsStringSync(), mode: FileMode.append);
      outputFile.writeAsStringSync('\n\n', mode: FileMode.append);
    }
  });

  print('Combined code saved to combined_code.dart');
}