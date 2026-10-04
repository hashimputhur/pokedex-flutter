import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/pokemon.dart';
import 'providers/favorites_provider.dart';
import 'services/pokemon_api_service.dart';
import 'screens/pokemon_detail_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FavoritesProvider()..loadFavorites(),
      child: const PokedexApp(),
    ),
  );
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PokedexHomeScreen(),
    );
  }
}

class PokedexHomeScreen extends StatefulWidget {
  const PokedexHomeScreen({super.key});

  @override
  State<PokedexHomeScreen> createState() => _PokedexHomeScreenState();
}

class _PokedexHomeScreenState extends State<PokedexHomeScreen> {
  final PokemonApiService apiService = PokemonApiService();

  final ScrollController scrollController = ScrollController();

  List<Pokemon> pokemonList = [];

  bool isLoading = true;
  bool isLoadingMore = false;

  String? errorMessage;
  String searchText = '';

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    loadPokemon();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        loadMorePokemon();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadPokemon() async {
    try {
      final pokemon = await apiService.getPokemonList(limit: 20, offset: 0);

      if (!mounted) return;

      setState(() {
        pokemonList = pokemon;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load Pokémon';
      });
    }
  }

  Future<void> loadMorePokemon() async {
    if (isLoadingMore || isLoading) {
      return;
    }

    if (apiService.nextUrl == null) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    try {
      final newPokemon = await apiService.getPokemonList();

      if (!mounted) return;

      setState(() {
        pokemonList.addAll(newPokemon);
        isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void openPokemonDetails(Pokemon pokemon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PokemonDetailScreen(pokemon: pokemon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Pokédex',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: selectedIndex == 0 ? buildPokedexScreen() : buildFavoritesScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.catching_pokemon),
            label: 'Pokédex',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  Widget buildPokedexScreen() {
    final filteredPokemon = pokemonList.where((pokemon) {
      return pokemon.name.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Pokémon',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search Pokémon',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pokémon',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: loadPokemon,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : filteredPokemon.isEmpty
                ? const Center(
                    child: Text(
                      'No Pokémon found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filteredPokemon.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredPokemon.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final pokemon = filteredPokemon[index];

                      return PokemonCard(
                        pokemon: pokemon,
                        isFavorite: context
                            .watch<FavoritesProvider>()
                            .isFavorite(pokemon.name),
                        onFavoriteToggle: () {
                          context.read<FavoritesProvider>().toggleFavorite(
                            pokemon,
                          );
                        },
                        onTap: () {
                          openPokemonDetails(pokemon);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildFavoritesScreen() {
    final favoritesProvider = context.watch<FavoritesProvider>();

    final favorites = favoritesProvider.favorites;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Favorites',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: favorites.isEmpty
                ? const Center(
                    child: Text(
                      'No favorite Pokémon yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final pokemon = favorites[index];

                      return PokemonCard(
                        pokemon: pokemon,
                        isFavorite: true,
                        onFavoriteToggle: () {
                          context.read<FavoritesProvider>().toggleFavorite(
                            pokemon,
                          );
                        },
                        onTap: () {
                          openPokemonDetails(pokemon);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Image.network(
          pokemon.imageUrl,
          width: 70,
          height: 70,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image_not_supported);
          },
        ),
        title: Text(
          pokemon.name.toUpperCase(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('#${pokemon.id.toString().padLeft(3, '0')}'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final type in pokemon.types)
                  Chip(
                    label: Text(
                      type.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: onFavoriteToggle,
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
          ),
        ),
      ),
    );
  }
}
