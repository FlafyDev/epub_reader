T enumFromIndex<T extends Enum>(
  List<T> values,
  dynamic index, {
  T? def,
}) {
  if (index is! int) {
    index = def?.index ?? 0;
  }
  
  if (index > 0 && index < values.length) {
    return values[index];
  }

  return def ?? values.first;
}
