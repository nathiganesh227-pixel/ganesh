import '../models/movie.dart';
import '../models/dining.dart';
import '../models/event.dart';
import '../models/activity.dart';
import '../models/shopping.dart';
import '../models/stay.dart';
import '../models/sports.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../data/movie_mock_data.dart';
import '../data/dining_mock_data.dart';
import '../data/event_mock_data.dart';
import '../data/activity_mock_data.dart';
import '../data/shopping_mock_data.dart';
import '../data/stay_mock_data.dart';
import '../data/sports_mock_data.dart';

class SearchResults {
  final List<Movie> movies;
  final List<Restaurant> dining;
  final List<PlazaEvent> events;
  final List<PlazaActivity> activities;
  final List<Product> shopping;
  final List<Hotel> stays;
  final List<SportsVenue> sports;

  const SearchResults({
    this.movies = const [],
    this.dining = const [],
    this.events = const [],
    this.activities = const [],
    this.shopping = const [],
    this.stays = const [],
    this.sports = const [],
  });

  bool get isEmpty =>
      movies.isEmpty &&
      dining.isEmpty &&
      events.isEmpty &&
      activities.isEmpty &&
      shopping.isEmpty &&
      stays.isEmpty &&
      sports.isEmpty;

  int get totalCount =>
      movies.length +
      dining.length +
      events.length +
      activities.length +
      shopping.length +
      stays.length +
      sports.length;
}

abstract class SearchRepository {
  Future<SearchResults> search(String query);
}

class LocalSearchRepository implements SearchRepository {
  const LocalSearchRepository();

  @override
  Future<SearchResults> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const SearchResults();

    final movies = MovieMockData.movies.where((m) =>
      m.title.toLowerCase().includes(q) ||
      m.genres.any((g) => g.toLowerCase().includes(q))
    ).toList();

    final dining = DiningMockData.restaurants.where((r) =>
      r.name.toLowerCase().includes(q) ||
      r.location.toLowerCase().includes(q) ||
      r.cuisines.any((c) => c.label.toLowerCase().includes(q) || c.name.toLowerCase().includes(q))
    ).toList();

    final events = EventMockData.events.where((e) =>
      e.title.toLowerCase().includes(q) ||
      e.venue.toLowerCase().includes(q) ||
      e.category.label.toLowerCase().includes(q)
    ).toList();

    final activities = ActivityMockData.activities.where((a) =>
      a.title.toLowerCase().includes(q) ||
      a.location.toLowerCase().includes(q) ||
      a.category.label.toLowerCase().includes(q)
    ).toList();

    final shopping = ShoppingMockData.products.where((p) =>
      p.name.toLowerCase().includes(q) ||
      p.brand.toLowerCase().includes(q) ||
      p.category.label.toLowerCase().includes(q)
    ).toList();

    final stays = StayMockData.hotels.where((h) =>
      h.name.toLowerCase().includes(q) ||
      h.location.toLowerCase().includes(q) ||
      h.category.label.toLowerCase().includes(q)
    ).toList();

    final sports = SportsMockData.venues.where((s) =>
      s.name.toLowerCase().includes(q) ||
      s.location.toLowerCase().includes(q) ||
      s.supportedSports.any((item) => item.label.toLowerCase().includes(q))
    ).toList();

    return SearchResults(
      movies: movies,
      dining: dining,
      events: events,
      activities: activities,
      shopping: shopping,
      stays: stays,
      sports: sports,
    );
  }
}

class ApiSearchRepository implements SearchRepository {
  final ApiClient _client;
  final LocalSearchRepository _fallback;

  ApiSearchRepository({
    ApiClient? client,
    LocalSearchRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalSearchRepository();

  @override
  Future<SearchResults> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const SearchResults();

    try {
      final response = await _client.get<SearchResults>(
        ApiEndpoints.search,
        queryParams: {'q': q},
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return SearchResults(
              movies: (json['movies'] as List<dynamic>?)
                      ?.map((e) => Movie.fromJson(e as Map<String, dynamic>))
                      .toList() ??
                  [],
              dining: (json['dining'] as List<dynamic>?)
                      ?.map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
                      .toList() ??
                  [],
              events: (json['events'] as List<dynamic>?)
                      ?.map((e) => PlazaEvent.fromJson(e as Map<String, dynamic>))
                      .toList() ??
                  [],
              activities: (json['activities'] as List<dynamic>?)
                      ?.map((e) => PlazaActivity.fromJson(e as Map<String, dynamic>))
                      .toList() ??
                  [],
              shopping: (json['shopping'] as List<dynamic>?)
                      ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
                      .toList() ??
                  [],
              stays: (json['stays'] as List<dynamic>?)
                      ?.map((e) => Hotel.fromJson(e as Map<String, dynamic>))
                      .toList() ??
                  [],
              sports: (json['sports'] as List<dynamic>?)
                      ?.map((e) => SportsVenue.fromJson(e as Map<String, dynamic>))
                      .toList() ??
                  [],
            );
          }
          return const SearchResults();
        },
      );

      if (response.success && response.data != null && !response.data!.isEmpty) {
        return response.data!;
      }
    } catch (_) {}

    return _fallback.search(query);
  }
}

extension on String {
  bool includes(String s) => toLowerCase().contains(s.toLowerCase());
}
