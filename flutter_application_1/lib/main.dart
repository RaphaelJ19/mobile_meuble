import 'package:flutter/material.dart';
import 'models/prestation.dart' as prestation_model;
import 'models/bien.dart';
import 'services/prestation_service.dart';
import 'services/bien_service.dart';
import 'pages/bien_detail_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Meublés',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  double _minPrice = 0;
  double _maxPrice = 500;
  int _bedrooms = 1;
  int _beds = 1;
  bool _petsAllowed = false;
  Map<int, bool> _selectedPrestations = {};
  List<prestation_model.Prestation> _prestations = [];
  bool _prestationsLoaded = false;
  String? _prestationsError;

  // Pour les biens
  late Future<Map<String, dynamic>> _biensFuture;
  int _currentPage = 1;

  // Filtres actuels appliqués
  double _appliedMinPrice = 0;
  double _appliedMaxPrice = 500;
  int _appliedBedrooms = 1;
  int _appliedBeds = 1;
  bool _appliedPetsAllowed = false;
  List<int> _appliedPrestations = [];

  @override
  void initState() {
    super.initState();
    _loadPrestations();
    _biensFuture = BienService.fetchBiens(page: _currentPage);
  }

  /// Charger les prestations depuis l'API
  void _loadPrestations() async {
    try {
      final prestations = await PrestationService.fetchPrestations();
      setState(() {
        _prestations = prestations;
        _prestationsLoaded = true;
        // Initialiser la map de sélection
        for (var p in prestations) {
          _selectedPrestations[p.id] = false;
        }
      });
    } catch (e) {
      setState(() {
        _prestationsError = e.toString();
        _prestationsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
      _loadBiens();
    });
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _loadBiens();
      });
    }
  }

  void _loadBiens() {
    // Utiliser le maximum entre chambres et lits pour le filtre
    final minCouchage = (_appliedBedrooms > _appliedBeds ? _appliedBedrooms : _appliedBeds);
    
    _biensFuture = BienService.fetchBiens(
      page: _currentPage,
      prixMin: _appliedMinPrice,
      prixMax: _appliedMaxPrice,
      nbCouchageMin: minCouchage,
      animaux: _appliedPetsAllowed ? 'Oui' : null,
      prestations: _appliedPrestations,
    );
  }

  void _applyFilters() {
    setState(() {
      _appliedMinPrice = _minPrice;
      _appliedMaxPrice = _maxPrice;
      _appliedBedrooms = _bedrooms;
      _appliedBeds = _beds;
      _appliedPetsAllowed = _petsAllowed;
      _appliedPrestations = _selectedPrestations.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      _currentPage = 1; // Réinitialiser à la première page
      _loadBiens();
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtres appliqués'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _searchCity() {
    final city = _searchController.text.trim();
    if (city.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Recherche pour: $city')));
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Filtres',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Prix par nuit (€)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RangeSlider(
                          values: RangeValues(_minPrice, _maxPrice),
                          min: 0,
                          max: 500,
                          divisions: 50,
                          labels: RangeLabels(
                            '${_minPrice.round()}€',
                            '${_maxPrice.round()}€',
                          ),
                          onChanged: (values) {
                            setModalState(() {
                              _minPrice = values.start;
                              _maxPrice = values.end;
                            });
                          },
                        ),
                        Text(
                          '${_minPrice.round()}€ - ${_maxPrice.round()}€',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Prestations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!_prestationsLoaded)
                          const Center(child: CircularProgressIndicator())
                        else if (_prestationsError != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Erreur: ${_prestationsError?.replaceAll('Exception: ', '')}',
                              style: TextStyle(
                                color: Colors.red[800],
                                fontSize: 12,
                              ),
                            ),
                          )
                        else if (_prestations.isEmpty)
                          const Text(
                            'Aucune prestation disponible',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _prestations
                                    .map(
                                      (prestation) => FilterChip(
                                        label: Text(prestation.nom),
                                        selected:
                                            _selectedPrestations[prestation
                                                .id] ??
                                            false,
                                        avatar: Icon(
                                          _getIconDataFromString(
                                            prestation.icon,
                                          ),
                                          size: 18,
                                        ),
                                        onSelected: (selected) {
                                          setModalState(() {
                                            _selectedPrestations[prestation
                                                    .id] =
                                                selected;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chambres',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed:
                                            _bedrooms > 1
                                                ? () => setModalState(
                                                  () => _bedrooms--,
                                                )
                                                : null,
                                      ),
                                      Text(
                                        '$_bedrooms',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed:
                                            () => setModalState(
                                              () => _bedrooms++,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lits',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed:
                                            _beds > 1
                                                ? () =>
                                                    setModalState(() => _beds--)
                                                : null,
                                      ),
                                      Text(
                                        '$_beds',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onPressed:
                                            () => setModalState(() => _beds++),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CheckboxListTile(
                          title: const Text('Animaux acceptés'),
                          value: _petsAllowed,
                          onChanged:
                              (value) =>
                                  setModalState(() => _petsAllowed = value!),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Appliquer les filtres',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trouvez votre logement meublé',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Appartements, maisons, gîtes...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => _searchCity(),
                              decoration: InputDecoration(
                                hintText: 'Rechercher une ville...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.blue,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.blue,
                                  ),
                                  onPressed: _searchCity,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune, color: Colors.blue),
                            onPressed: _showFilters,
                            tooltip: 'Filtres',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Propriétés disponibles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _biensFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadBiens,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: Text('Aucune donnée'));
                    }

                    final data = snapshot.data!;
                    final biens = data['biens'] as List<Bien>;
                    final totalPages = data['pages'] as int;

                    if (biens.isEmpty) {
                      return const Center(
                        child: Text('Aucune propriété disponible'),
                      );
                    }

                    return Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: biens.length,
                          itemBuilder: (context, index) {
                            final bien = biens[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            BienDetailPage(idBien: bien.idBien),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Photo
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          color: Colors.grey[300],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          child:
                                              bien.photoUrl.isEmpty
                                                  ? const Center(
                                                    child: Icon(
                                                      Icons.image,
                                                      size: 48,
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                                  : Image.network(
                                                    bien.photoUrl,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          value:
                                                              loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                          .cumulativeBytesLoaded /
                                                                      loadingProgress
                                                                          .expectedTotalBytes!
                                                                  : null,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: Colors.grey[400],
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 48,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                        ),
                                      ),
                                    ),
                                    // Info
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bien.nomBien,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              bien.ville,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${bien.prixNuit}€/nuit',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Color(0xFF1A237E),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      size: 12,
                                                      color: Colors.amber,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${bien.noteMoyenne}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Pagination
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  _currentPage > 1 ? _previousPage : null,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Précédent'),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Page $_currentPage / $totalPages',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed:
                                  _currentPage < totalPages ? _nextPage : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Suivant'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convertir un nom d'icône string en IconData
  IconData _getIconDataFromString(String iconName) {
    final icons = {
      'wifi': Icons.wifi,
      'directions_car': Icons.directions_car,
      'restaurant': Icons.restaurant,
      'tv': Icons.tv,
      'hotel': Icons.hotel,
      'check_circle': Icons.check_circle,
    };
    return icons[iconName] ?? Icons.check_circle;
  }
}
