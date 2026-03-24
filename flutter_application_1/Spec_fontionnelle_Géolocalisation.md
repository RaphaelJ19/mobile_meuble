Holidaze
Spécification Technique — Carte Interactive & Géolocalisation

Version 1.0 — BTS SIO — Projet HAP

Élément	Valeur
Auteur	Ethan — BTS SIO
Fichier principal	lib/screens/map/map_screen.dart
Dépendances	flutter_map ^7.0.0, latlong2 ^0.9.1, geolocator ^13.0.0
Tuiles carte	OpenStreetMap (tile.openstreetmap.org)
Données biens	GET /php_api/api/mobile/get_biens_mobile.php
1. Introduction et périmètre

Ce document décrit le fonctionnement technique de l'écran MapScreen de HapMobile.
Cet écran est accessible depuis l'onglet Carte (index 1) de la navigation principale.

Il combine deux fonctionnalités distinctes :

l'affichage des biens sur une carte OpenStreetMap via flutter_map
la géolocalisation GPS de l'utilisateur via le package geolocator

Fichier : lib/screens/map/map_screen.dart
Widgets : MapScreen (principal), _UserLocationMarker (animé), _BienBottomSheet
État : StatefulWidget — _MapScreenState gère la carte, les biens et la position

2. Architecture du fichier
2.1 Classes et responsabilités
Classe	Rôle
_MapScreenState	État principal : biens, position GPS, sélection marqueur
_UserLocationMarker	Marqueur animé (halo pulsant) représentant l'utilisateur
_BienBottomSheet	Fiche résumée affichée au clic sur un marqueur de bien
2.2 Variables d'état
Variable	Type	Rôle
_biens	List<Bien>	Liste des biens chargés depuis l'API
_loading	bool	true pendant le chargement initial des biens
_error	String?	Message d'erreur si le chargement échoue
_selectedBien	Bien?	Bien actuellement sélectionné
_userPosition	LatLng?	Position GPS de l'utilisateur
_locating	bool	true pendant la recherche GPS
_mapController	MapController	Contrôle programmatique de la carte
2.3 Constantes de zoom
Constante	Valeur	Utilisation
_defaultCenter	46.60°N 1.88°E	Centre France au démarrage
_defaultZoom	6.0	Zoom France entière
_focusZoom	13.0	Zoom clic sur bien
_locationZoom	12.0	Zoom après géolocalisation
3. Chargement et affichage des biens
3.1 Appel API

Au démarrage (initState), _loadBiens() est appelé.

GET /php_api/api/mobile/get_biens_mobile.php?per_page=100
Timeout : 15 secondes
Filtre  : lat_commune ET long_commune non null

Les biens sans coordonnées GPS sont filtrés côté Flutter avec .where() avant d'être stockés dans _biens.

3.2 États de chargement
État	Comportement
_loading = true	Shimmer animé
_error != null	Écran d'erreur
Chargé	Carte OSM avec marqueurs
3.3 Affichage des marqueurs de biens
Propriété	Non sélectionné	Sélectionné
Taille	38 × 38 px	48 × 48 px
Couleur fond	#16213e	#e94560
Bordure	2px accent	3px blanc
Ombre	Légère	Prononcée
Icône	Maison accent	Maison blanche
Animation	200 ms	—
3.4 Interaction avec un marqueur

Au clic sur un marqueur :

Le bien devient _selectedBien
La carte se déplace vers le bien (zoom 13)
Un BottomSheet s'ouvre avec la fiche du bien
À la fermeture → _selectedBien = null
4. Géolocalisation
4.1 Principe général

La géolocalisation utilise geolocator.
La position utilisateur est stockée dans _userPosition et n'est jamais envoyée au serveur.

Elle sert uniquement à :

centrer la carte
calculer des distances
4.2 Initialisation silencieuse

Au démarrage _initLocation() :

Permission	Action
always / whileInUse	_fetchLocation(silent: true)
denied	aucune action
exception	ignorée
4.3 Flux de récupération de position
Étape	Vérification	Si échec
1	GPS activé	Snackbar GPS désactivé
2	Permission denied	Demande permission
3	Permission refusée	Snackbar refus
4	deniedForever	Snackbar paramètres
5	getCurrentPosition	Timeout
6	Succès	Centre carte
4.4 Paramètres GPS
accuracy  : LocationAccuracy.high
timeLimit : Duration(seconds: 10)

Pas de tracking continu — uniquement au clic.

4.5 Marqueur utilisateur

_UserLocationMarker affiche :

Un halo pulsant animé
Un point bleu central
Ombre bleue
Animation 2 secondes en boucle

Le halo ne dépasse jamais 44px.

4.6 Calcul de distance
meters = Geolocator.distanceBetween(
    userLat,
    userLng,
    bienLat,
    bienLng
)

Affichage :

< 1000 m → mètres

1000 m → kilomètres

4.7 Bouton Me localiser
État	Apparence
Non localisé	Fond #16213e
Localisation	Spinner
Localisé	Fond #e94560

Badge Localisé affiché en bas à gauche.

4.8 Bouton Recentrer
Situation	Action
Position connue	Centre sur utilisateur
Position inconnue	Centre sur France
5. BottomSheet fiche bien
5.1 Déclenchement

Widget : _BienBottomSheet
Ouverture via showModalBottomSheet avec coins arrondis.

Paramètres :

bien
userPosition
onNavigate
5.2 Contenu affiché
Photo du bien
Nom
Commune
Distance
Note
Prix semaine
Bouton Voir le détail

Navigation :

context.push('/bien/{id}')

À la fermeture → _selectedBien = null

6. Configuration des permissions
6.1 Android

AndroidManifest.xml

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
6.2 iOS

Info.plist

NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription

Sans ces clés → crash iOS.

6.3 Web

Sur Flutter Web, geolocator utilise navigator.geolocation.
Le navigateur gère la permission automatiquement.