import '../network/environment_config.dart';
import 'movie_repository.dart';
import 'local_movie_repository.dart';
import 'api_movie_repository.dart';
import 'dining_repository.dart';
import 'local_dining_repository.dart';
import 'api_dining_repository.dart';
import 'event_repository.dart';
import 'local_event_repository.dart';
import 'api_event_repository.dart';
import 'activity_repository.dart';
import 'local_activity_repository.dart';
import 'api_activity_repository.dart';
import 'shopping_repository.dart';
import 'local_shopping_repository.dart';
import 'api_shopping_repository.dart';
import 'stay_repository.dart';
import 'local_stay_repository.dart';
import 'api_stay_repository.dart';
import 'sports_repository.dart';
import 'local_sports_repository.dart';
import 'api_sports_repository.dart';
import 'booking_repository.dart';
import 'local_booking_repository.dart';
import 'api_booking_repository.dart';
import 'search_repository.dart';

class RepositoryProvider {
  static final RepositoryProvider instance = RepositoryProvider._internal();
  factory RepositoryProvider() => instance;
  RepositoryProvider._internal();

  MovieRepository movieRepo = EnvironmentConfig.useMockData
      ? const LocalMovieRepository()
      : ApiMovieRepository();

  DiningRepository diningRepo = EnvironmentConfig.useMockData
      ? const LocalDiningRepository()
      : ApiDiningRepository();

  EventRepository eventRepo = EnvironmentConfig.useMockData
      ? const LocalEventRepository()
      : ApiEventRepository();

  ActivityRepository activityRepo = EnvironmentConfig.useMockData
      ? const LocalActivityRepository()
      : ApiActivityRepository();

  ShoppingRepository shoppingRepo = EnvironmentConfig.useMockData
      ? const LocalShoppingRepository()
      : ApiShoppingRepository();

  StayRepository stayRepo = EnvironmentConfig.useMockData
      ? const LocalStayRepository()
      : ApiStayRepository();

  SportsRepository sportsRepo = EnvironmentConfig.useMockData
      ? const LocalSportsRepository()
      : ApiSportsRepository();

  BookingRepository bookingRepo = EnvironmentConfig.useMockData
      ? const LocalBookingRepository()
      : ApiBookingRepository();

  SearchRepository searchRepo = EnvironmentConfig.useMockData
      ? const LocalSearchRepository()
      : ApiSearchRepository();

  void configureForTesting({
    MovieRepository? movies,
    DiningRepository? dining,
    EventRepository? events,
    ActivityRepository? activities,
    ShoppingRepository? shopping,
    StayRepository? stays,
    SportsRepository? sports,
    BookingRepository? bookings,
    SearchRepository? search,
  }) {
    if (movies != null) movieRepo = movies;
    if (dining != null) diningRepo = dining;
    if (events != null) eventRepo = events;
    if (activities != null) activityRepo = activities;
    if (shopping != null) shoppingRepo = shopping;
    if (stays != null) stayRepo = stays;
    if (sports != null) sportsRepo = sports;
    if (bookings != null) bookingRepo = bookings;
    if (search != null) searchRepo = search;
  }
}
