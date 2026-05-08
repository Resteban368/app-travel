import '../entities/bus_layout.dart';

abstract class BusLayoutRepository {
  Future<List<BusLayout>> getBusLayouts();
  Future<BusLayout> getBusLayout(int id);
  Future<void> createBusLayout(BusLayout layout);
  Future<void> updateBusLayout(BusLayout layout);
  Future<void> deleteBusLayout(int id);
}
