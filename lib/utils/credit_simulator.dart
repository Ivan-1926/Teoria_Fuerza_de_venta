import 'dart:math' as math;

/// Simulador de crédito en tiempo real (cuota francesa con TEA anual).
class CreditSimulationResult {
  final double monthlyPayment;
  final double totalInterest;
  final double totalAmount;

  const CreditSimulationResult({
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalAmount,
  });
}

class CreditSimulator {
  static CreditSimulationResult calculate({
    required double amount,
    required int termMonths,
    required double teaPercent,
  }) {
    if (amount <= 0 || termMonths <= 0) {
      return const CreditSimulationResult(
        monthlyPayment: 0,
        totalInterest: 0,
        totalAmount: 0,
      );
    }

    final monthlyRate = _teaToMonthlyRate(teaPercent);
    if (monthlyRate <= 0) {
      final payment = amount / termMonths;
      return CreditSimulationResult(
        monthlyPayment: payment,
        totalInterest: 0,
        totalAmount: payment * termMonths,
      );
    }

    final factor = math.pow(1 + monthlyRate, termMonths).toDouble();
    final payment = amount * (monthlyRate * factor) / (factor - 1);
    final total = payment * termMonths;
    return CreditSimulationResult(
      monthlyPayment: payment,
      totalInterest: total - amount,
      totalAmount: total,
    );
  }

  static double _teaToMonthlyRate(double teaPercent) {
    final tea = teaPercent / 100;
    return math.pow(1 + tea, 1 / 12).toDouble() - 1;
  }
}
