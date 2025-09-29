class LeakSeverityCalculator {
  static String calculate(int detectedCount) {
    // Example rule-based algorithm:
    if (detectedCount == 0) return 'None';
    if (detectedCount == 1) return 'Low';
    if (detectedCount <= 3) return 'Moderate';
    return 'High';
  }
}