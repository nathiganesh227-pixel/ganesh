import '../models/movie.dart';
import '../models/cinema_showtime.dart';

abstract class MovieRepository {
  Future<List<Movie>> getMovies();
  Future<Movie?> getMovieById(String id);
  Future<List<Theatre>> getTheatresForMovie(String movieId, {String? date, String? city});
  Future<List<Movie>> searchMovies(String query);
}
