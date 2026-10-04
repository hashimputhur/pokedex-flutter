class Pokemon {
  final int id;
  final String name;
  final String imageUrl;

  final List<String> types;
  final List<String> abilities;

  final int height;
  final int weight;

  final Map<String, int> stats;

  const Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.types = const [],
    this.abilities = const [],
    this.height = 0,
    this.weight = 0,
    this.stats = const {},
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final types = (json['types'] as List)
        .map((type) => type['type']['name'].toString())
        .toList();

    final abilities = (json['abilities'] as List)
        .map((ability) => ability['ability']['name'].toString())
        .toList();

    final stats = <String, int>{};

    for (final stat in json['stats']) {
      stats[stat['stat']['name']] = stat['base_stat'];
    }

    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl: json['sprites']['other']['official-artwork']['front_default'],
      types: types,
      abilities: abilities,
      height: json['height'],
      weight: json['weight'],
      stats: stats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sprites': {
        'other': {
          'official-artwork': {'front_default': imageUrl},
        },
      },
      'types': types
          .map(
            (type) => {
              'type': {'name': type},
            },
          )
          .toList(),
      'abilities': abilities
          .map(
            (ability) => {
              'ability': {'name': ability},
            },
          )
          .toList(),
      'height': height,
      'weight': weight,
      'stats': stats.entries
          .map(
            (stat) => {
              'base_stat': stat.value,
              'stat': {'name': stat.key},
            },
          )
          .toList(),
    };
  }
}
