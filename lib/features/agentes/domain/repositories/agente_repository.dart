import '../entities/agente.dart';

abstract class AgenteRepository {
  Future<List<Agente>> getAgentes();
  Future<Agente> getAgenteById(int id);
  Future<void> createAgente(Agente agente);
  Future<void> updateAgente(Agente agente);
  Future<void> deleteAgente(int id);
}
