import '../models/buro_report_model.dart';
import '../services/consulta_buro.dart';

class BuroRepository {
  final ConsultaBuroService _service = ConsultaBuroService();

  Future<BuroReportModel> consultar({
    required String dni,
    String? clientId,
    String? clientName,
    String? officerId,
  }) =>
      _service.consultar(
        dni: dni,
        clientId: clientId,
        clientName: clientName,
        officerId: officerId,
      );
}
