import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

void main() {
  final bytes = File('Basti list - Copy.docx').readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final entry = archive.findFile('word/document.xml')!;
  final xml = String.fromCharCodes(entry.content as List<int>);
  final doc = XmlDocument.parse(xml);
  final rows = doc.findAllElements('w:tr').toList();
  
  print('Total table rows: ${rows.length}');
  final diseases = <String>{};
  final bastiNames = <String>{};
  final bastiTypeTags = <String, int>{};
  final rowsWithFormulation = <int>[];
  final rowsWithRef = <int>[];
  final rowsWithIndication = <int>[];
  final rowsWithIngredients = <int>[];

  // Header is row 0: DISEASES | INDICATION / STAGE | NAME OF BASTI | INGREDIENTS / DESCRIPTION | FORMULATION | REFERENCES
  for (int i = 1; i < rows.length; i++) {
    final cells = rows[i].findAllElements('w:tc').map((c) => c.findAllElements('w:t').map((t) => t.innerText).join('').trim()).toList();
    if (cells.length >= 6) {
      final disease = cells[0];
      final indication = cells[1];
      final bastiName = cells[2];
      final ingredients = cells[3];
      final formulation = cells[4];
      final reference = cells[5];

      if (disease.isNotEmpty) diseases.add(disease);
      if (bastiName.isNotEmpty) bastiNames.add(bastiName);
      if (indication.isNotEmpty) rowsWithIndication.add(i);
      if (ingredients.isNotEmpty) rowsWithIngredients.add(i);
      if (formulation.isNotEmpty) rowsWithFormulation.add(i);
      if (reference.isNotEmpty) rowsWithRef.add(i);

      // Check tags
      final tagMatch = RegExp(r'\(([^)]+)\)').allMatches(bastiName);
      for (final m in tagMatch) {
        final tag = m.group(1)!;
        bastiTypeTags[tag] = (bastiTypeTags[tag] ?? 0) + 1;
      }
    }
  }

  print('Unique diseases: ${diseases.length}');
  print('Unique Basti entries: ${bastiNames.length}');
  print('Total Data Rows: ${rows.length - 1}');
  print('Rows with Indication/Stage: ${rowsWithIndication.length}');
  print('Rows with Ingredients/Description: ${rowsWithIngredients.length}');
  print('Rows with Formulation: ${rowsWithFormulation.length}');
  print('Rows with References: ${rowsWithRef.length}');
  print('\nBasti Type Tags in Names:');
  bastiTypeTags.forEach((k, v) => print('  - "$k": $v rows'));

  print('\nAll unique disease names in document:');
  final sortedDiseases = diseases.toList()..sort();
  for (final d in sortedDiseases) {
    print('  - $d');
  }
}
