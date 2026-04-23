import '../entities/hotel.dart';

abstract class HotelRepository {
  Future<List<Hotel>> getHoteles();
  Future<void> createHotel(Hotel hotel);
  Future<void> updateHotel(Hotel hotel);
  Future<void> deleteHotel(int id);
}
