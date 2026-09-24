import '../models/event.dart';

abstract class EventRepository {
  Future<List<PlazaEvent>> getEvents({String? category});
  Future<PlazaEvent?> getEventById(String id);
  Future<bool> bookTickets(EventBooking booking);
}
