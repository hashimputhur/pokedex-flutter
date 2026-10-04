import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokemonApiService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';

  String? nextUrl;

  Future<List<Pokemon>> getPokemonList({int limit = 20, int offset = 0}) async {
    final url = nextUrl ?? '$baseUrl/pokemon?limit=$limit&offset=$offset';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon');
    }

    final data = jsonDecode(response.body);

    nextUrl = data['next'];

    final results = data['results'] as List;

    final List<Pokemon> pokemonList = [];

    for (final item in results) {
      final details = await getPokemonDetails(item['name']);

      pokemonList.add(Pokemon.fromJson(details));
    }

    return pokemonList;
  }

  Future<Map<String, dynamic>> getPokemonDetails(String name) async {
    final response = await http.get(Uri.parse('$baseUrl/pokemon/$name'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon details');
    }

    return jsonDecode(response.body);
  }
}
