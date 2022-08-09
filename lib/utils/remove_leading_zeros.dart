RegExp _removeLeadingZerosRegExp = RegExp(r'([.]*0)(?!.*\d)');

String removeLeadingZeros(String str) {
  return str.replaceAll(_removeLeadingZerosRegExp, '');
}
