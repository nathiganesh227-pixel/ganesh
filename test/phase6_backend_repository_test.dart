import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/movie.dart';
import 'package:plaza/core/repositories/local_movie_repository.dart';
import 'package:plaza/core/repositories/api_movie_repository.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/network/environment_config.dart';

void main() {
  group('Phase 6 - Architecture & Repository Tests', () {
    test('EnvironmentConfig provides valid endpoints for each environment', () {
      EnvironmentConfig.setEnvironment(AppEnvironment.dev);
      expect(EnvironmentConfig.baseUrl, contains('3000'));

      EnvironmentConfig.setEnvironment(AppEnvironment.staging);
      expect(EnvironmentConfig.baseUrl, anyOf(contains('staging-api'), contains('onrender.com')));

      EnvironmentConfig.setEnvironment(AppEnvironment.prod);
      expect(EnvironmentConfig.baseUrl, anyOf(contains('api.plaza.app'), contains('onrender.com')));

      // Reset to dev
      EnvironmentConfig.setEnvironment(AppEnvironment.dev);
    });

    test('ApiResponse parses success and failure states accurately', () {
      final success = ApiResponse.success({'key': 'value'}, message: 'OK', statusCode: 200);
      expect(success.success, isTrue);
      expect(success.data, isNotNull);
      expect(success.statusCode, 200);

      final failure = ApiResponse.failure('Network timeout', statusCode: 504);
      expect(failure.success, isFalse);
      expect(failure.data, isNull);
      expect(failure.message, 'Network timeout');
      expect(failure.statusCode, 504);
    });

    test('LocalMovieRepository retrieves movies, showtimes and searches', () async {
      const repo = LocalMovieRepository();
      final movies = await repo.getMovies();
      expect(movies, isNotEmpty);
      expect(movies.first.title, isNotEmpty);

      final movie = await repo.getMovieById(movies.first.id);
      expect(movie, isNotNull);
      expect(movie!.id, movies.first.id);

      final theatres = await repo.getTheatresForMovie(movies.first.id);
      expect(theatres, isNotEmpty);

      final searchResults = await repo.searchMovies('Dune');
      expect(searchResults, isNotEmpty);
      expect(searchResults.first.title, contains('Dune'));
    });

    test('ApiMovieRepository falls back to local data gracefully when offline', () async {
      final repo = ApiMovieRepository();
      // Should not throw even if network calls fail; must return fallback movies
      final movies = await repo.getMovies();
      expect(movies, isNotEmpty);

      final theatres = await repo.getTheatresForMovie('mov_1');
      expect(theatres, isNotEmpty);
    });

    test('Movie JSON serialization roundtrips correctly', () {
      final original = Movie(
        id: 'test_mov_1',
        title: 'Test Cinema',
        tagline: 'Sample tagline',
        synopsis: 'Sample synopsis',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
        rating: 4.8,
        votesCount: 1200,
        genres: ['Action', 'Sci-Fi'],
        duration: '2h 15m',
        primaryLanguage: MovieLanguage.telugu,
        availableLanguages: [MovieLanguage.telugu, MovieLanguage.english],
        formats: [MovieFormat.format2D, MovieFormat.imax3D],
        certificate: 'UA',
        releaseDate: DateTime(2026, 1, 1),
        startingPrice: 250,
        trailerYoutubeId: 'xyz123',
        cast: const [
          CastMember(name: 'Hero', role: 'Protagonist', imageUrl: 'https://example.com/hero.jpg'),
        ],
        director: 'Director Name',
      );

      final json = original.toJson();
      final parsed = Movie.fromJson(json);

      expect(parsed.id, original.id);
      expect(parsed.title, original.title);
      expect(parsed.rating, original.rating);
      expect(parsed.cast.first.name, 'Hero');
      expect(parsed.primaryLanguage, MovieLanguage.telugu);
    });
  });
}
