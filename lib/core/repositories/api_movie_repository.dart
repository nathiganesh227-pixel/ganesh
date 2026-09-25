import '../models/movie.dart';
import '../models/cinema_showtime.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'movie_repository.dart';
import 'local_movie_repository.dart';

class ApiMovieRepository implements MovieRepository {
  final ApiClient _client;
  final LocalMovieRepository _fallback;

  ApiMovieRepository({
    ApiClient? client,
    LocalMovieRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalMovieRepository();

  @override
  Future<List<Movie>> getMovies() async {
    try {
      final response = await _client.get<List<Movie>>(
        ApiEndpoints.movies,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (_) {
      // Fallback gracefully on network failure
    }
    return _fallback.getMovies();
  }

  @override
  Future<Movie?> getMovieById(String id) async {
    try {
      final response = await _client.get<Movie?>(
        ApiEndpoints.movieDetails(id),
        fromJson: (json) => json != null ? Movie.fromJson(json as Map<String, dynamic>) : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }
    } catch (_) {
      // Fallback
    }
    return _fallback.getMovieById(id);
  }

  @override
  Future<List<Theatre>> getTheatresForMovie(String movieId, {String? date, String? city}) async {
    try {
      final queryParams = <String, String>{};
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;

      final response = await _client.get<List<Theatre>>(
        ApiEndpoints.movieShows(movieId),
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json is List) {
            // Group shows by theatreId
            final Map<String, List<ShowtimeSlot>> theatreShowsMap = {};
            final Map<String, Map<String, dynamic>> theatreMetaMap = {};

            for (final item in json) {
              if (item is! Map<String, dynamic>) continue;
              final tId = item['theatreId'] as String? ?? 'theatre_default';
              final slot = ShowtimeSlot.fromJson(item);

              theatreShowsMap.putIfAbsent(tId, () => []).add(slot);
              theatreMetaMap.putIfAbsent(tId, () => {
                'id': tId,
                'name': item['theatreName'] ?? 'PLAZA Cinema',
                'location': item['theatreLocation'] ?? '',
                'city': item['theatreCity'] ?? 'Hyderabad',
              });
            }

            final List<Theatre> result = [];
            theatreShowsMap.forEach((tId, slots) {
              final meta = theatreMetaMap[tId]!;
              result.add(
                Theatre(
                  id: tId,
                  name: meta['name'] as String,
                  location: meta['location'] as String,
                  city: meta['city'] as String,
                  distance: '2.5 km',
                  amenities: const ['Dolby Atmos', '4K Laser Projection', 'Recliners'],
                  showtimes: slots,
                ),
              );
            });

            return result;
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (_) {
      // Fallback
    }
    return _fallback.getTheatresForMovie(movieId, date: date, city: city);
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await _client.get<List<Movie>>(
        ApiEndpoints.movies,
        queryParams: {'q': query},
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (_) {
      // Fallback
    }
    return _fallback.searchMovies(query);
  }
}
