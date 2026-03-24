import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bien.dart';
import '../services/bien_service.dart';
import 'bien_detail_page.dart';

const _defaultCenter = LatLng(46.60, 1.88);
const _defaultZoom = 6.0;
const _focusZoom = 13.0;
const _locationZoom = 12.0;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();

  List<Bien> _biens = [];
  bool _loading = true;
  String? _error;
  Bien? _selectedBien;
  LatLng? _userPosition;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _loadBiens();
    _initLocation();
  }

  Future<void> _loadBiens() async {
    try {
      final data = await BienService.fetchBiens(page: 1, perPage: 100);
      final biens = (data['biens'] as List<Bien>)
          .where((b) => b.latitude != 0 && b.longitude != 0)
          .toList();
      setState(() {
        _biens = biens;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        await _fetchLocation(silent: true);
      }
    } catch (_) {}
  }

  Future<void> _fetchLocation({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS désactivé')),
          );
        }
        setState(() => _locating = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!silent && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission de localisation refusée')),
            );
          }
          setState(() => _locating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activez la localisation dans les paramètres'),
            ),
          );
        }
        setState(() => _locating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userPosition = latlng;
        _locating = false;
      });
      _mapController.move(latlng, _locationZoom);
    } catch (_) {
      setState(() => _locating = false);
    }
  }

  void _onMarkerTap(Bien bien) {
    setState(() => _selectedBien = bien);
    _mapController.move(LatLng(bien.latitude, bien.longitude), _focusZoom);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BienBottomSheet(
        bien: bien,
        userPosition: _userPosition,
        onNavigate: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BienDetailPage(idBien: bien.idBien),
            ),
          );
        },
      ),
    ).whenComplete(() => setState(() => _selectedBien = null));
  }

  void _recenter() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, _locationZoom);
    } else {
      _mapController.move(_defaultCenter, _defaultZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadBiens();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_application_1',
              ),
              MarkerLayer(
                markers: [
                  ..._biens.map((bien) {
                    final selected = _selectedBien?.idBien == bien.idBien;
                    final size = selected ? 48.0 : 38.0;
                    return Marker(
                      point: LatLng(bien.latitude, bien.longitude),
                      width: size,
                      height: size,
                      child: GestureDetector(
                        onTap: () => _onMarkerTap(bien),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFe94560)
                                : const Color(0xFF16213e),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? Colors.white : const Color(0xFFe94560),
                              width: selected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(selected ? 0.4 : 0.2),
                                blurRadius: selected ? 8 : 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.house,
                            color: selected ? Colors.white : const Color(0xFFe94560),
                            size: size * 0.55,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_userPosition != null)
                    Marker(
                      point: _userPosition!,
                      width: 44,
                      height: 44,
                      child: const _UserLocationMarker(),
                    ),
                ],
              ),
            ],
          ),
          // Bouton Me localiser
          Positioned(
            top: 50,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate',
                  backgroundColor: _userPosition != null
                      ? const Color(0xFFe94560)
                      : const Color(0xFF16213e),
                  onPressed: _locating ? null : () => _fetchLocation(),
                  child: _locating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.my_location, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: const Color(0xFF16213e),
                  onPressed: _recenter,
                  child: const Icon(Icons.center_focus_strong, color: Colors.white),
                ),
              ],
            ),
          ),
          // Badge localisé
          if (_userPosition != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFe94560),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Localisé', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44 * _animation.value,
            height: 44 * _animation.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.3 * (1 - _animation.value + 0.3)),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BienBottomSheet extends StatelessWidget {
  final Bien bien;
  final LatLng? userPosition;
  final VoidCallback onNavigate;

  const _BienBottomSheet({
    required this.bien,
    required this.userPosition,
    required this.onNavigate,
  });

  String _formatDistance() {
    if (userPosition == null) return '';
    final meters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      bien.latitude,
      bien.longitude,
    );
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final distance = _formatDistance();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bien.photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                bien.photoUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            bien.nomBien,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(bien.ville, style: TextStyle(color: Colors.grey[600])),
              if (distance.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.directions_walk, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Text(distance, style: const TextStyle(color: Colors.blue, fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${bien.noteMoyenne}', style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Text(
                '${bien.prixNuit}€/nuit',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNavigate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe94560),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Voir le détail'),
            ),
          ),
        ],
      ),
    );
  }
}
