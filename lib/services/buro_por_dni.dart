/// Perfil de buró determinista según el **último dígito** del DNI
/// (ENUNCIADOS_30_CASOS_CREDITO_FLUJO_MOVIL.pdf).
class PerfilBuroPorDni {
  final String calificacion;
  final int entidades;
  final double deudaTotal;
  final int diasMora;
  final bool enListaInhabilitados;
  final int scoreNumerico;

  const PerfilBuroPorDni({
    required this.calificacion,
    required this.entidades,
    required this.deudaTotal,
    required this.diasMora,
    this.enListaInhabilitados = false,
    required this.scoreNumerico,
  });

  /// Último dígito del documento → perfil esperado en los 30 casos académicos.
  static PerfilBuroPorDni fromDni(String dni) {
    final clean = dni.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      return const PerfilBuroPorDni(
        calificacion: 'NORMAL',
        entidades: 1,
        deudaTotal: 4500,
        diasMora: 0,
        scoreNumerico: 712,
      );
    }
    final ultimo = int.tryParse(clean[clean.length - 1]) ?? 0;
    return _porUltimoDigito[ultimo] ?? _porUltimoDigito[0]!;
  }

  static const Map<int, PerfilBuroPorDni> _porUltimoDigito = {
    0: PerfilBuroPorDni(
      calificacion: 'NORMAL',
      entidades: 1,
      deudaTotal: 4500,
      diasMora: 0,
      scoreNumerico: 712,
    ),
    1: PerfilBuroPorDni(
      calificacion: 'NORMAL',
      entidades: 2,
      deudaTotal: 12000,
      diasMora: 0,
      scoreNumerico: 712,
    ),
    2: PerfilBuroPorDni(
      calificacion: 'CPP',
      entidades: 2,
      deudaTotal: 18000,
      diasMora: 15,
      scoreNumerico: 580,
    ),
    3: PerfilBuroPorDni(
      calificacion: 'NORMAL',
      entidades: 0,
      deudaTotal: 0,
      diasMora: 0,
      scoreNumerico: 712,
    ),
    4: PerfilBuroPorDni(
      calificacion: 'DUDOSO',
      entidades: 3,
      deudaTotal: 25000,
      diasMora: 95,
      scoreNumerico: 420,
    ),
    5: PerfilBuroPorDni(
      calificacion: 'DEFICIENTE',
      entidades: 2,
      deudaTotal: 16000,
      diasMora: 45,
      scoreNumerico: 480,
    ),
    6: PerfilBuroPorDni(
      calificacion: 'NORMAL',
      entidades: 1,
      deudaTotal: 6000,
      diasMora: 0,
      scoreNumerico: 712,
    ),
    7: PerfilBuroPorDni(
      calificacion: 'PERDIDA',
      entidades: 4,
      deudaTotal: 40000,
      diasMora: 210,
      enListaInhabilitados: true,
      scoreNumerico: 350,
    ),
    8: PerfilBuroPorDni(
      calificacion: 'CPP',
      entidades: 1,
      deudaTotal: 9000,
      diasMora: 20,
      scoreNumerico: 580,
    ),
    9: PerfilBuroPorDni(
      calificacion: 'NORMAL',
      entidades: 2,
      deudaTotal: 14000,
      diasMora: 0,
      scoreNumerico: 712,
    ),
  };
}
