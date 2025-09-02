abstract class ITextExtractor {
  List<String> extractPatterns(String inputText);
}

class DocumentReferenceExtractor implements ITextExtractor {
  final List<RegExp> _regExps = [
    RegExp(r'SI No\.: *\n*\d+'),
    RegExp(r'DR No\.: *\n*\d+'),
    RegExp(r'DR Na\.: *\n*\d+'), // Consider normalizing this to DR No.
    RegExp(r'IT No\.: *\n*\d+'),
    RegExp(r'GI No\.: *\n*\d+'),
    RegExp(r'PO No\.: *\n*[A-Za-z0-9-]+'),
    RegExp(r'SIS#: *\n*\d{5}')
  ];

  @override
  List<String> extractPatterns(String inputText) {
    List<String> matchList = [];
    for (RegExp regExp in _regExps) {
      Match? match = regExp.firstMatch(inputText);
      String validation = match != null ? match.group(0) ?? '' : 'No match found';
      if (validation != 'No match found') {
        String extractedText = match!.group(0) ?? '';
        // Consider moving the normalization logic here as well
        String normalizedText = extractedText.replaceAll(RegExp(r'\s+'), '');
        if (normalizedText == 'DRNa.:') {
          normalizedText = 'DRNo.:'; // Example normalization
        }
        matchList.add(normalizedText); // Or the original 'extractedText' based on needs
      }
    }
    return matchList;
  }
}
