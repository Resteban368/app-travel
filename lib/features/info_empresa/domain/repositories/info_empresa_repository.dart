import '../entities/info_empresa.dart';

abstract class InfoEmpresaRepository {
  Future<List<InfoEmpresa>> getInfo();
  Future<void> createInfo(InfoEmpresa info);
  Future<void> updateInfo(InfoEmpresa info);
  Future<void> deleteInfo(int id);
  Future<void> syncVectors();
}
