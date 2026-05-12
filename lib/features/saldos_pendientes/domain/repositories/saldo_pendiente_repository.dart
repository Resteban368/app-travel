import '../entities/saldo_pendiente.dart';

abstract class SaldoPendienteRepository {
  Future<({List<SaldoPendiente> items, int total, int page, int limit})>
      getSaldosPendientes({
    int page = 1,
    int limit = 20,
    String? tourId,
    String? responsable,
    String? idReserva,
    bool sinRecordatorioReciente = false,
  });

  Future<RecordatorioResult> enviarRecordatorio(
    int reservaId, {
    int? conversationId,
  });
}

class RecordatorioResult {
  final int reservaId;
  final String idReserva;
  final String responsable;
  final String telefono;
  final double saldoPendiente;
  final int conversationId;
  final int messageId;

  const RecordatorioResult({
    required this.reservaId,
    required this.idReserva,
    required this.responsable,
    required this.telefono,
    required this.saldoPendiente,
    required this.conversationId,
    required this.messageId,
  });

  factory RecordatorioResult.fromJson(Map<String, dynamic> j) =>
      RecordatorioResult(
        reservaId: j['reserva_id'] as int? ?? 0,
        idReserva: j['id_reserva'] as String? ?? '',
        responsable: j['responsable'] as String? ?? '',
        telefono: j['telefono'] as String? ?? '',
        saldoPendiente: (j['saldo_pendiente'] as num?)?.toDouble() ?? 0,
        conversationId: j['conversation_id'] as int? ?? 0,
        messageId: j['message_id'] as int? ?? 0,
      );
}
