import '../entities/opinion.dart';

abstract class OpinionRepository {
  Future<List<Opinion>> getOpiniones();
  Future<void> setAprobada(int id, bool aprobada);
  Future<void> deleteOpinion(int id);
}
