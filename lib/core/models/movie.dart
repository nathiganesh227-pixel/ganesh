enum MovieFormat {
  format2D('2D'),
  format3D('3D'),
  imax3D('IMAX 3D'),
  fourDX('4DX'),
  dolbyAtmos('Dolby Atmos');

  final String label;
  const MovieFormat(this.label);

  static MovieFormat fromString(String val) {
    return MovieFormat.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => MovieFormat.format2D,
    );
  }
}

enum MovieLanguage {
  telugu('Telugu'),
  hindi('Hindi'),
  tamil('Tamil'),
  english('English');

  final String label;
  const MovieLanguage(this.label);

  static MovieLanguage fromString(String val) {
    return MovieLanguage.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => MovieLanguage.english,
    );
  }
}

class CastMember {
  final String name;
  final String role;
  final String imageUrl;

  const CastMember({
    required this.name,
    required this.role,
    required this.imageUrl,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'imageUrl': imageUrl,
  };
}

class Movie {
  final String id;
  final String title;
  final String tagline;
  final String synopsis;
  final String posterUrl;
  final String backdropUrl;
  final double rating;
  final int votesCount;
  final List<String> genres;
  final String duration;
  final MovieLanguage primaryLanguage;
  final List<MovieLanguage> availableLanguages;
  final List<MovieFormat> formats;
  final String certificate; // U, UA, A
  final DateTime releaseDate;
  final double startingPrice;
  final String trailerYoutubeId;
  final List<CastMember> cast;
  final String director;
  final bool isNowShowing;
  final bool isTrending;
  final bool isComingSoon;

  const Movie({
    required this.id,
    required this.title,
    required this.tagline,
    required this.synopsis,
    required this.posterUrl,
    required this.backdropUrl,
    required this.rating,
    required this.votesCount,
    required this.genres,
    required this.duration,
    required this.primaryLanguage,
    required this.availableLanguages,
    required this.formats,
    required this.certificate,
    required this.releaseDate,
    required this.startingPrice,
    required this.trailerYoutubeId,
    required this.cast,
    required this.director,
    this.isNowShowing = true,
    this.isTrending = false,
    this.isComingSoon = false,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      synopsis: json['synopsis'] as String? ?? '',
      posterUrl: json['posterUrl'] as String? ?? '',
      backdropUrl: json['backdropUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      votesCount: (json['votesCount'] as num?)?.toInt() ?? 0,
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      duration: json['duration'] as String? ?? '',
      primaryLanguage: MovieLanguage.fromString(json['primaryLanguage'] as String? ?? 'English'),
      availableLanguages: (json['availableLanguages'] as List<dynamic>?)
              ?.map((e) => MovieLanguage.fromString(e.toString()))
              .toList() ??
          [],
      formats: (json['formats'] as List<dynamic>?)
              ?.map((e) => MovieFormat.fromString(e.toString()))
              .toList() ??
          [],
      certificate: json['certificate'] as String? ?? 'UA',
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startingPrice: (json['startingPrice'] as num?)?.toDouble() ?? 0.0,
      trailerYoutubeId: json['trailerYoutubeId'] as String? ?? '',
      cast: (json['cast'] as List<dynamic>?)
              ?.map((e) => CastMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      director: json['director'] as String? ?? '',
      isNowShowing: json['isNowShowing'] as bool? ?? false,
      isTrending: json['isTrending'] as bool? ?? false,
      isComingSoon: json['isComingSoon'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'tagline': tagline,
    'synopsis': synopsis,
    'posterUrl': posterUrl,
    'backdropUrl': backdropUrl,
    'rating': rating,
    'votesCount': votesCount,
    'genres': genres,
    'duration': duration,
    'primaryLanguage': primaryLanguage.label,
    'availableLanguages': availableLanguages.map((e) => e.label).toList(),
    'formats': formats.map((e) => e.label).toList(),
    'certificate': certificate,
    'releaseDate': releaseDate.toIso8601String(),
    'startingPrice': startingPrice,
    'trailerYoutubeId': trailerYoutubeId,
    'cast': cast.map((e) => e.toJson()).toList(),
    'director': director,
    'isNowShowing': isNowShowing,
    'isTrending': isTrending,
    'isComingSoon': isComingSoon,
  };
}

