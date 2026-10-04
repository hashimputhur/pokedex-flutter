import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pokemon.dart';
import '../providers/favorites_provider.dart';
import '../services/pokemon_api_service.dart';

class PokemonDetailScreen extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({super.key, required this.pokemon});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final PokemonApiService apiService = PokemonApiService();

  Pokemon? pokemon;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  Future<void> loadDetails() async {
    try {
      final data = await apiService.getPokemonDetails(widget.pokemon.name);

      final details = Pokemon.fromJson(data);

      if (!mounted) return;

      setState(() {
        pokemon = details;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Failed to load Pokémon details';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pokemon.name.toUpperCase()),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              final isFavorite = favoritesProvider.isFavorite(
                widget.pokemon.name,
              );

              return IconButton(
                onPressed: () {
                  favoritesProvider.toggleFavorite(widget.pokemon);
                },
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(errorMessage!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: loadDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : buildDetails(),
    );
  }

  Widget buildDetails() {
    final currentPokemon = pokemon!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.network(
              currentPokemon.imageUrl,
              width: 220,
              height: 220,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              currentPokemon.name.toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '#${currentPokemon.id.toString().padLeft(3, '0')}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Types',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final type in currentPokemon.types)
                Chip(label: Text(type.toUpperCase())),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: buildInfoCard(
                  'Height',
                  '${currentPokemon.height / 10} m',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildInfoCard(
                  'Weight',
                  '${currentPokemon.weight / 10} kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Abilities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final ability in currentPokemon.abilities)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• ${ability.replaceAll('-', ' ')}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Base Stats',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final stat in currentPokemon.stats.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      stat.key.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(value: stat.value / 200),
                  ),
                  const SizedBox(width: 10),
                  Text(stat.value.toString()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildInfoCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
