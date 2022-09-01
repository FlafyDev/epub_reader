T enumFromIndex<T extends Enum>(List<T> values, int index, { T? def, }) {
  if (index > 0 && index < values.length) {
    return values[index];
  }
  return def ?? values.first;
}

