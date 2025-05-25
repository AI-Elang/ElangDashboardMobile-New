import 'package:elang_dashboard_new_ui/detail_outlet.dart';
import 'package:elang_dashboard_new_ui/detail_site.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;

class McMaps extends StatefulWidget {
  const McMaps({
    super.key,
  });

  @override
  State<McMaps> createState() => _McMapsState();
}

class OutletLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String status;
  final String branch;
  final String brand;
  final String distance;
  final String gaKondisi;
  final String kondisi;
  final String category;

  OutletLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.branch,
    required this.brand,
    required this.distance,
    required this.gaKondisi,
    required this.kondisi,
    required this.category,
  });

  factory OutletLocation.fromJson(Map<String, dynamic> json) {
    return OutletLocation(
      id: json['id'],
      name: json['name'],
      latitude: double.parse(json['lat']),
      longitude: double.parse(json['long']),
      status: json['status'],
      branch: json['branch'],
      brand: json['brand'],
      distance: json['distance'],
      gaKondisi: json['ga_kondisi'],
      kondisi: json['kondisi'],
      category: json['category'] ?? '-',
    );
  }
}

class _McMapsState extends State<McMaps> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Position? userPosition;
  OutletLocation? selectedOutlet;
  StreamSubscription<Position>? _positionStreamSubscription;
  BitmapDescriptor? outletMarkerIcon;
  BitmapDescriptor? siteMarkerIcon;

  bool showInfo = false;
  bool isLoading = true;
  bool isLocationPermissionGranted = false;
  bool showOutlets = true;
  bool showSites = true;

  String gaKondisiFilter = 'ALL';

  var baseURL = dotenv.env['baseURL'];

  Future<BitmapDescriptor> createCustomMarkerIcon({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(75, 75); // Ukuran diubah menjadi 75x75

    // Draw the background circle
    final Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    // Draw the icon with adjusted size
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 30, // Ukuran font disesuaikan
        fontFamily: icon.fontFamily,
        color: iconColor,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    final image = await pictureRecorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );

    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> initCustomMarkers() async {
    try {
      outletMarkerIcon = await createCustomMarkerIcon(
        icon: Icons.home,
        backgroundColor: Colors.green,
        iconColor: Colors.white,
      );

      siteMarkerIcon = await createCustomMarkerIcon(
        icon: Icons.cell_tower,
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );

      if (mounted) {
        await fetchOutletLocations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load custom markers')),
      );
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        userPosition = position;
        isLocationPermissionGranted = true;
      });

      await fetchOutletLocations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location error')),
      );
    }
  }

  Future<void> fetchOutletLocations() async {
    if (userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User position is not available')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$baseURL/api/v1/maps/site-outlet?latitude=${userPosition!.latitude}&longitude=${userPosition!.longitude}'),
        headers: {
          'Authorization':
              'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> locationsData = jsonResponse['data'];
        final outlets =
            locationsData.map((data) => OutletLocation.fromJson(data)).toList();

        Set<Marker> newMarkers = {};
        if (userPosition != null) {
          newMarkers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: LatLng(userPosition!.latitude, userPosition!.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );
        }

        for (var outlet in outlets) {
          if ((showOutlets && outlet.status == 'OUTLET') ||
              (showSites && outlet.status == 'SITE')) {
            if (gaKondisiFilter == 'ALL' ||
                (gaKondisiFilter == 'GA' && outlet.gaKondisi == 'GA') ||
                (gaKondisiFilter == 'NO_GA' && outlet.gaKondisi == 'NO_GA')) {
              BitmapDescriptor icon;
              if (outlet.status == 'OUTLET' && outlet.kondisi == '1') {
                icon = await createCustomMarkerIcon(
                  icon: Icons.home,
                  backgroundColor: Colors.green, // OUTLET WITH QSSO
                  iconColor: Colors.white,
                );
              } else if (outlet.status == 'OUTLET' && outlet.kondisi == '0') {
                icon = await createCustomMarkerIcon(
                  icon: Icons.home,
                  backgroundColor: Colors.grey, // OUTLET NO QSSO
                  iconColor: Colors.white,
                );
              } else if (outlet.status == 'SITE' && outlet.kondisi == '1') {
                if (outlet.category == 'NEW SITE') {
                  icon = await createCustomMarkerIcon(
                    icon: Icons.cell_tower,
                    backgroundColor: Colors.yellow, // NEW SITE NO LRS
                    iconColor: Colors.white,
                  );
                } else {
                  icon = await createCustomMarkerIcon(
                    icon: Icons.cell_tower,
                    backgroundColor: Colors.red, // Default for SITE NO LRS
                    iconColor: Colors.white,
                  );
                }
              } else {
                if (outlet.category == 'NEW SITE') {
                  icon = await createCustomMarkerIcon(
                    icon: Icons.cell_tower,
                    backgroundColor: Colors.yellow, // NEW SITE WITH LRS
                    iconColor: Colors.white,
                  );
                } else {
                  icon = await createCustomMarkerIcon(
                    icon: Icons.cell_tower,
                    backgroundColor: Colors.black, // Default for SITE WITH LRS
                    iconColor: Colors.white,
                  );
                }
              }

              newMarkers.add(
                Marker(
                  markerId: MarkerId(outlet.id),
                  position: LatLng(outlet.latitude, outlet.longitude),
                  icon: icon,
                  onTap: () {
                    setState(() {
                      selectedOutlet = outlet;
                      showInfo = true;
                    });
                  },
                ),
              );
            }
          }
        }

        setState(() {
          markers = newMarkers;
          isLoading = false;
        });

        if (markers.isNotEmpty) {
          final bounds = LatLngBounds(
            southwest: LatLng(
              userPosition!.latitude - 0.01,
              userPosition!.longitude - 0.01,
            ),
            northeast: LatLng(
              userPosition!.latitude + 0.01,
              userPosition!.longitude + 0.01,
            ),
          );

          mapController
              ?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to load outlet locations: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load outlet locations: $e')),
      );
    }
  }

  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      distanceFilter: 10,
      accuracy: LocationAccuracy.high,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        userPosition = position;
      });
      fetchOutletLocations();
    });
  }

  void navigateToDetail(String status, String id, String brand) {
    if (status == 'OUTLET') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailOutlet(qrCode: id),
        ),
      );
    } else if (status == 'SITE') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailSite(siteId: id, brand: brand),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLocationPermission().then((_) {
      if (isLocationPermissionGranted) {
        _startLocationStream();
        initCustomMarkers();
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Widget _buildInfoWindow() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: showInfo ? 70 : -200,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: showInfo ? 1.0 : 0.0,
        child: GestureDetector(
          onTap: () {
            setState(() {
              showInfo = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedOutlet?.name ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${selectedOutlet?.id ?? ''}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Branch: ${selectedOutlet?.branch ?? ''}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Distance: ${selectedOutlet?.distance ?? ''} km',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${selectedOutlet?.category ?? '-'}',
                ),
                const SizedBox(height: 8),
                Text(
                  (selectedOutlet?.status == 'OUTLET' &&
                          selectedOutlet?.kondisi == '1')
                      ? 'OUTLET WITH QSSO'
                      : (selectedOutlet?.status == 'OUTLET' &&
                              selectedOutlet?.kondisi == '0')
                          ? 'OUTLET NO QSSO'
                          : (selectedOutlet?.status == 'SITE' &&
                                  selectedOutlet?.kondisi == '1')
                              ? 'SITE NO LRS'
                              : 'SITE WITH LRS',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (selectedOutlet?.status == 'OUTLET')
                  ElevatedButton(
                    onPressed: () {
                      if (selectedOutlet != null) {
                        navigateToDetail(
                            selectedOutlet!.status, selectedOutlet!.id, "");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                    child: const Text('DETAIL OUTLET'),
                  )
                else if (selectedOutlet?.status == 'SITE')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (selectedOutlet != null) {
                            navigateToDetail(selectedOutlet!.status,
                                selectedOutlet!.id, "IM3");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 10),
                        ),
                        child: const Text('DETAIL SITE IM3'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (selectedOutlet != null) {
                            navigateToDetail(selectedOutlet!.status,
                                selectedOutlet!.id, "3ID");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 10),
                        ),
                        child: const Text('DETAIL SITE 3ID'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('Show Outlets'),
                  value: showOutlets,
                  onChanged: (bool? value) {
                    setState(() {
                      showOutlets = value ?? true;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Show Sites'),
                  value: showSites,
                  onChanged: (bool? value) {
                    setState(() {
                      showSites = value ?? true;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status GA', style: TextStyle(fontSize: 16)),
                      DropdownButton<String>(
                        value: gaKondisiFilter,
                        items: const [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text('ALL'),
                          ),
                          DropdownMenuItem(
                            value: 'GA',
                            child: Text('GA'),
                          ),
                          DropdownMenuItem(
                            value: 'NO_GA',
                            child: Text('NO GA'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            gaKondisiFilter = newValue ?? 'ALL';
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      fetchOutletLocations();
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      userPosition?.latitude ?? 0.0,
                      userPosition?.longitude ?? 0.0,
                    ),
                    zoom: 15.0,
                  ),
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                  onTap: (_) {
                    setState(() {
                      showInfo = false;
                    });
                  },
                ),
          if (selectedOutlet != null) _buildInfoWindow(),
          Positioned(
            bottom: 20,
            left: 20,
            child: Opacity(
              opacity: 0.75,
              child: FloatingActionButton(
                onPressed: _showFilterMenu,
                backgroundColor: Colors.white,
                child: const Icon(Icons.filter_list, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
