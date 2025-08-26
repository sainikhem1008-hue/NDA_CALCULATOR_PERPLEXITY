double calculateNda(double basicPay, double daPercent, double totalNightHours) {
  return ((basicPay + (basicPay * daPercent / 100)) / 200) * (totalNightHours / 6);
}
