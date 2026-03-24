import 'package:flutter/material.dart';
import '../models/bien.dart';
import '../services/bien_service.dart';

class BienDetailPage extends StatefulWidget {
  final int idBien;

  const BienDetailPage({Key? key, required this.idBien}) : super(key: key);

  @override
  State<BienDetailPage> createState() => _BienDetailPageState();
}

class _BienDetailPageState extends State<BienDetailPage> {
  late Future<Bien> _bienFuture;

  @override
  void initState() {
    super.initState();
    _bienFuture = BienService.fetchBienDetail(widget.idBien);
  }

  void _showReservationSheet(BuildContext context, Bien bien) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ReservationSheet(bien: bien),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la propriété'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Bien>(
        future: _bienFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _bienFuture = BienService.fetchBienDetail(widget.idBien);
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Aucune donnée'));
          }

          final bien = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: DecorationImage(
                      image: NetworkImage(bien.photoUrl),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {},
                    ),
                  ),
                  child: bien.photoUrl.isEmpty
                      ? const Icon(Icons.image, size: 64, color: Colors.grey)
                      : null,
                ),
                // Info principale
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bien.nomBien,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${bien.rueBien}, ${bien.ville}',
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(height: 4),
                              Text(
                                '${bien.noteMoyenne}/5',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '(${bien.nbAvis})',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Prix
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Prix par nuit',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            Text(
                              '${bien.prixNuit}€',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bien.descriptionBien,
                        style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Caractéristiques
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Caractéristiques',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.square_foot, label: 'Superficie', value: bien.superficieBien),
                      _InfoRow(icon: Icons.bed, label: 'Couchages', value: '${bien.nbCouchage}'),
                      _InfoRow(icon: Icons.pets, label: 'Animaux', value: bien.animauxBien),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Prestations
                if (bien.prestations != null && bien.prestations!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prestations',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: bien.prestations!
                              .map((p) => Chip(
                                    label: Text(p.nom),
                                    backgroundColor: const Color(0xFF1A237E),
                                    labelStyle: const TextStyle(color: Colors.white),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Avis
                if (bien.avis != null && bien.avis!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Avis récents',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bien.avis!.length > 5 ? 5 : bien.avis!.length,
                          itemBuilder: (context, index) {
                            final avis = bien.avis![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: List.generate(
                                            5,
                                            (i) => Icon(
                                              Icons.star,
                                              size: 16,
                                              color: i < avis.note ? Colors.amber : Colors.grey,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          avis.date,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      avis.commentaire,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                // Bouton réservation
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Builder(
                      builder: (btnContext) => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showReservationSheet(btnContext, bien),
                        child: const Text(
                          'Réserver maintenant',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Bottom sheet de réservation ────────────────────────────────────────────

class _ReservationSheet extends StatefulWidget {
  final Bien bien;
  const _ReservationSheet({required this.bien});

  @override
  State<_ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<_ReservationSheet> {
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _loading = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
  }

  int get _nbNuits {
    if (_dateDebut == null || _dateFin == null) return 0;
    return _dateFin!.difference(_dateDebut!).inDays;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate(bool isDebut) async {
    final now = DateTime.now();
    final first = isDebut
        ? now
        : (_dateDebut?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1)));
    final initial = isDebut ? (_dateDebut ?? now) : (_dateFin ?? first);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('fr'),
    );
    if (picked == null) return;

    setState(() {
      if (isDebut) {
        _dateDebut = picked;
        if (_dateFin != null && !_dateFin!.isAfter(picked)) _dateFin = null;
      } else {
        _dateFin = picked;
      }
    });
  }

  void _confirmer() async {
    if (_dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner vos dates de séjour'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Capturer les valeurs et le messenger AVANT tout await
    final dateDebut  = _dateDebut!;
    final dateFin    = _dateFin!;
    final nbNuits    = _nbNuits;
    final messenger  = ScaffoldMessenger.of(context);
    final navigator  = Navigator.of(context);

    setState(() => _verifying = true);

    try {
      final result = await BienService.verifierDisponibilite(
        idBien: widget.bien.idBien,
        dateDebut: dateDebut,
        dateFin: dateFin,
      );

      if (!mounted) return;
      setState(() => _verifying = false);

      if (result['success'] != true) {
        messenger.showSnackBar(SnackBar(
          content: Text('Erreur : ${result['error']}'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      if (result['disponible'] == false) {
        final conflit = result['conflit'] as Map<String, dynamic>;
        final debut   = conflit['date_debut'].toString().split('-').reversed.join('/');
        final fin     = conflit['date_fin'].toString().split('-').reversed.join('/');
        setState(() { _dateDebut = null; _dateFin = null; });
        messenger.showSnackBar(SnackBar(
          content: Text('La période sélectionnée est déjà occupée (réservation du $debut au $fin)'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
        return;
      }

      // Période libre — créer la réservation en BDD
      final reservation = await BienService.creerReservation(
        idBien: widget.bien.idBien,
        dateDebut: dateDebut,
        dateFin: dateFin,
      );

      if (!mounted) return;
      setState(() => _verifying = false);

      if (reservation['success'] != true) {
        messenger.showSnackBar(SnackBar(
          content: Text('Erreur : ${reservation['error']}'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Réservation confirmée du ${_fmt(dateDebut)} au ${_fmt(dateFin)} — ${nbNuits * widget.bien.prixNuit}€',
        ),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifying = false);
      messenger.showSnackBar(SnackBar(
        content: Text('Erreur de connexion : $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _nbNuits * widget.bien.prixNuit;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Réserver', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Text(widget.bien.nomBien, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 20),
          const Text('Date d\'arrivée', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _DateTile(
            date: _dateDebut,
            hint: 'Sélectionner une date',
            onTap: _verifying ? null : () => _pickDate(true),
          ),
          const SizedBox(height: 14),
          const Text('Date de départ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _DateTile(
            date: _dateFin,
            hint: _dateDebut == null ? 'Choisissez d\'abord l\'arrivée' : 'Sélectionner une date',
            onTap: (_verifying || _dateDebut == null) ? null : () => _pickDate(false),
          ),
          if (_nbNuits > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _RecapRow(label: 'Durée', value: '$_nbNuits nuit${_nbNuits > 1 ? 's' : ''}'),
                  const SizedBox(height: 6),
                  _RecapRow(label: '${widget.bien.prixNuit}€ × $_nbNuits nuits', value: '${total}€'),
                  const Divider(height: 16),
                  _RecapRow(label: 'Total', value: '${total}€', bold: true),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _verifying ? null : _confirmer,
              child: _verifying
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirmer la réservation',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final VoidCallback? onTap;

  const _DateTile({required this.date, required this.hint, this.onTap});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null
                ? const Color(0xFF1A237E)
                : active
                    ? Colors.grey[400]!
                    : Colors.grey[200]!,
          ),
          borderRadius: BorderRadius.circular(10),
          color: date != null
              ? const Color(0xFF1A237E).withOpacity(0.05)
              : active
                  ? Colors.white
                  : Colors.grey[100],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: date != null ? const Color(0xFF1A237E) : Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(
              date != null ? _fmt(date!) : hint,
              style: TextStyle(
                fontSize: 14,
                fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                color: date != null ? const Color(0xFF1A237E) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _RecapRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: bold ? const Color(0xFF1A237E) : Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({Key? key, required this.icon, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A237E), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
