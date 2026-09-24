import '../models/movie.dart';
import '../models/cinema_showtime.dart';
import '../data/movie_mock_data.dart';
import 'movie_repository.dart';

class LocalMovieRepository implements MovieRepository {
  const LocalMovieRepository();

  @override
  Future<List<Movie>> getMovies() async {
    return List.from(MovieMockData.movies);
  }

  @override
  Future<Movie?> getMovieById(String id) async {
    try {
      return MovieMockData.movies.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Theatre>> getTheatresForMovie(String movieId) async {
    return MovieMockData.getTheatresForMovie(movieId);
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    final q = query.toLowerCase();
    return MovieMockData.movies.where((m) {
      return m.title.toLowerCase().contains(q) ||
          m.genres.any((g) => g.toLowerCase().contains(q)) ||
          m.director.toLowerCase().contains(q);
    }).toList();
  }
}
