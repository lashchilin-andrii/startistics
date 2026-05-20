String formatTauntName(String rawName) {

  final RegExp vowelsRegExp = RegExp(r'[aeiouyаеёиоуыэюя]', caseSensitive: false);

  String processedName = '';

  for (int charIndex = 0; charIndex < rawName.length; charIndex++) {
    final String char = rawName[charIndex];
    
    if (charIndex == 0 || charIndex == 1) {
      processedName += char;
    } else {
      if (!vowelsRegExp.hasMatch(char)) {
        processedName += char;
      }
    }
  }

  return processedName.length > 3 
      ? processedName.substring(0, 3) 
      : processedName;
}