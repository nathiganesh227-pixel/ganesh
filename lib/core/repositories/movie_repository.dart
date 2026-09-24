import '../models/movie.dart';
import '../models/cinema_showtime.dart';

abstract class MovieRepository {
  Future<List<Movie>> getMovies();
  Future<Movie?> getMovieById(String id);
  Future<List<Theatre>> getTheatresForMovie(String movieId);
  Future<List<Movie>> searchMovies(String query);
}
