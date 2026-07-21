import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int count = 0;
  for (var file in files) {
    var content = file.readAsStringSync();
    
    if (content.contains('localhost:3001') || content.contains('10.0.2.2:3001')) {
      content = content.replaceAll('localhost:3001', '192.168.1.9:3001');
      content = content.replaceAll('10.0.2.2:3001', '192.168.1.9:3001');
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
      count++;
    }
  }
  print('Total updated URLs: $count');
}
