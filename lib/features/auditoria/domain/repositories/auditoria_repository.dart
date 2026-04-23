import '../entities/sesion_usuario.dart';
import '../entities/auditoria_general.dart';

abstract class AuditoriaRepository {
  Future<List<SesionUsuario>> getSesiones({DateTime? fecha});
  Future<List<AuditoriaGeneral>> getAuditoriaGeneral();
}
