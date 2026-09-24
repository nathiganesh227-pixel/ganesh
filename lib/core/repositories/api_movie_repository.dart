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
  Future<List<Theatre>> getTheatresForMovie(String movieId) async {
    try {
      final response = await _client.get<List<Theatre>>(
        ApiEndpoints.movieShowtimes(movieId),
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => Theatre.fromJson(item as Map<String, dynamic>)).toList();
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
    return _fallback.getTheatresForMovie(movieId);
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
