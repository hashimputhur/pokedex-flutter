import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon.dart';

class FavoritesProvider extends ChangeNotifier {
  final Map<String, Pokemon> _favorites = {};

  List<Pokemon> get favorites => _favorites.values.toList();

  bool isFavorite(String name) {
    return _favorites.containsKey(name);
  }

  Future<void> loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();

    final savedFavorites = preferences.getStringList('favorites') ?? [];

    _favorites.clear();

    for (final item in savedFavorites) {
      try {
        final data = jsonDecode(item);

        final pokemon = Pokemon.fromJson(data);

        _favorites[pokemon.name] = pokemon;
      } catch (e) {
        // Ignore old or invalid favorite data.
      }
    }

    notifyListeners();
  }

  Future<void> toggleFavorite(Pokemon pokemon) async {
    if (_favorites.containsKey(pokemon.name)) {
      _favorites.remove(pokemon.name);
    } else {
      _favorites[pokemon.name] = pokemon;
    }

    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    final savedFavorites = _favorites.values
        .map((pokemon) => jsonEncode(pokemon.toJson()))
        .toList();

    await preferences.setStringList('favorites', savedFavorites);
  }
}
