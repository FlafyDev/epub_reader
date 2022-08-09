double progressValue<T extends num>(T start, T end, double progress) {
  return (end - start) * progress + start;
}
