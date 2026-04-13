import '../entities/politica_reserva.dart';

abstract class PoliticaReservaRepository {
  Future<List<PoliticaReserva>> getPoliticas();
  Future<void> createPolitica(PoliticaReserva politica);
  Future<void> updatePolitica(PoliticaReserva politica);
  Future<void> deletePolitica(int id);
}
