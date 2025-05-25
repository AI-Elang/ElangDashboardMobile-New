import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/dse_tracking_list.dart';
import 'package:elang_dashboard_new_ui/detail_outlet.dart';
import 'package:elang_dashboard_new_ui/detail_site.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;

class DseTrackingMaps extends StatefulWidget {
  final String dseId;
  final int mcId;
  final String selectedRegion;
  final String selectedArea;
  final String selectedBranch;
  final String date;

  const DseTrackingMaps({
    super.key,
    required this.dseId,
    required this.mcId,
    required this.selectedRegion,
    required this.selectedArea,
    required this.selectedBranch,
    required this.date,
  });

  @override
  State<DseTrackingMaps> createState() => _DseTrackingMapsState();
}

class NearbyLocation {
  final String id;
  final String name;
  final String kecamatan;
  final String mc;
  final String branch;
  final String area;
  final String region;
  final double latitude;
  final double longitude;
  final String brand;
  final String status;
  final String distance;
  final String gaKondisi;
  final String kondisi;
  final String category;

  NearbyLocation({
    required this.id,
    required this.name,
    required this.kecamatan,
    required this.mc,
    required this.branch,
    required this.area,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.brand,
    required this.status,
    required this.distance,
    required this.gaKondisi,
    required this.kondisi,
    required this.category,
  });

  factory NearbyLocation.fromJson(Map<String, dynamic> json) {
    return NearbyLocation(
      id: json['id'],
      name: json['name'],
      kecamatan: json['kecamatan'],
      mc: json['mc'],
      branch: json['branch'],
      area: json['area'],
      region: json['region'],
      latitude: double.parse(json['lat']),
      longitude: double.parse(json['long']),
      brand: json['brand'],
      status: json['status'],
      distance: json['distance'],
      gaKondisi: json['ga_kondisi'],
      kondisi: json['kondisi'],
      category: json['category'] ?? '-',
    );
  }
}

class DseTrackingStatusLocation {
  final double latitude;
  final double longitude;
  final String timestamp;
  final List<NearbyLocation> nearby;

  DseTrackingStatusLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.nearby,
  });

  factory DseTrackingStatusLocation.fromJson(Map<String, dynamic> json) {
    return DseTrackingStatusLocation(
      latitude: double.parse(json['latitude']),
      longitude: double.parse(json['longitude']),
      timestamp: json['timestamp'],
      nearby: (json['nearby'] as List)
          .map((item) => NearbyLocation.fromJson(item))
          .toList(),
    );
  }
}

class _DseTrackingMapsState extends State<DseTrackingMaps> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<DseTrackingStatusLocation> sortedDseLocations = [];
  Position? userPosition;
  DseTrackingStatusLocation? selectedDseStatus;
  NearbyLocation? selectedNearbyLocation;
  StreamSubscription<Position>? _positionStreamSubscription;

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
    const size = Size(75, 75);

    final Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 30,
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

  Future<BitmapDescriptor> createCompositeMarker({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required int number,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(75, 75);
    const numberCircleRadius = 26.25; // Increased from 15.0 (1.75x)

    // Draw main marker
    final Paint mainPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      mainPaint,
    );

    // Draw main icon
    TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 30,
        fontFamily: icon.fontFamily,
        color: iconColor,
      ),
    );

    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size.width - iconPainter.width) / 2,
        (size.height - iconPainter.height) / 2,
      ),
    );

    // Draw number circle in top-right corner
    final Paint numberCirclePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width - numberCircleRadius, numberCircleRadius),
      numberCircleRadius,
      numberCirclePaint,
    );

    // Draw number with larger font size
    TextPainter numberPainter = TextPainter(textDirection: TextDirection.ltr);
    numberPainter.text = TextSpan(
      text: number.toString(),
      style: const TextStyle(
        fontSize: 28, // Increased from 16 (1.75x)
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    numberPainter.layout();
    numberPainter.paint(
      canvas,
      Offset(
        size.width -
            numberCircleRadius * 2 +
            (numberCircleRadius * 2 - numberPainter.width) / 2,
        numberCircleRadius - (numberPainter.height / 2),
      ),
    );

    final image = await pictureRecorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

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

      await fetchDseTrackingStatus(token);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location error')),
      );
    }
  }

  Future<void> addNearbyMarkers(List<NearbyLocation> nearbyLocations) async {
    for (var nearbyLocation in nearbyLocations) {
      BitmapDescriptor icon;

      if (nearbyLocation.status == 'OUTLET' && nearbyLocation.kondisi == '1') {
        icon = await createCustomMarkerIcon(
          icon: Icons.home,
          backgroundColor: Colors.green, // OUTLET WITH QSSO
          iconColor: Colors.white,
        );
      } else if (nearbyLocation.status == 'OUTLET' &&
          nearbyLocation.kondisi == '0') {
        icon = await createCustomMarkerIcon(
          icon: Icons.home,
          backgroundColor: Colors.grey, // OUTLET NO QSSO
          iconColor: Colors.white,
        );
      } else if (nearbyLocation.status == 'SITE' &&
          nearbyLocation.kondisi == '1') {
        if (nearbyLocation.category == 'NEW SITE') {
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
        if (nearbyLocation.category == 'NEW SITE') {
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

      markers.add(
        Marker(
          markerId: MarkerId('nearby_${nearbyLocation.id}'),
          position: LatLng(nearbyLocation.latitude, nearbyLocation.longitude),
          icon: icon,
          onTap: () {
            setState(() {
              selectedNearbyLocation = nearbyLocation;
              selectedDseStatus = null;
              showInfo = true;
            });
          },
        ),
      );
    }
  }

  Future<void> fetchDseTrackingStatus(String? token) async {
    try {
      final url = Uri.parse(
        '$baseURL/api/v1/dse/tracking-status/maps/${widget.dseId}?date=${widget.date}',
      );

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers);
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (jsonResponse['meta']['success'] == true) {
        final statusData = jsonResponse['data'] as List<dynamic>;

        if (statusData.isNotEmpty) {
          try {
            setState(() {
              // Clear existing markers
              markers.clear();
              polylines.clear();
            });

            // Convert and sort the DSE locations by timestamp
            sortedDseLocations = statusData
                .map((data) => DseTrackingStatusLocation.fromJson(data))
                .toList()
              ..sort((a, b) => DateTime.parse(a.timestamp)
                  .compareTo(DateTime.parse(b.timestamp)));

            // Create polyline points
            List<LatLng> polylinePoints = sortedDseLocations
                .map((loc) => LatLng(loc.latitude, loc.longitude))
                .toList();

            // Add the polyline
            setState(() {
              polylines.add(
                Polyline(
                  polylineId: const PolylineId('dse_path'),
                  points: polylinePoints,
                  color: Colors.blue,
                  width: 3,
                ),
              );
            });

            // Add markers for DSE locations and nearby locations
            for (var i = 0; i < sortedDseLocations.length; i++) {
              final dseStatus = sortedDseLocations[i];
              final numberedIcon = await createCompositeMarker(
                icon: Icons.location_on,
                backgroundColor: Colors.pink[600]!,
                iconColor: Colors.white,
                number: i + 1,
              );

              setState(() {
                markers.add(
                  Marker(
                    markerId: MarkerId('dse_location_$i'),
                    position: LatLng(dseStatus.latitude, dseStatus.longitude),
                    icon: numberedIcon,
                    onTap: () {
                      setState(() {
                        selectedDseStatus = dseStatus;
                        selectedNearbyLocation = null;
                        showInfo = true;
                      });
                    },
                  ),
                );
              });

              // Add nearby location markers
              await addNearbyMarkers(dseStatus.nearby);
            }

            // Move camera to the most recent DSE location
            if (sortedDseLocations.isNotEmpty) {
              mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(
                      sortedDseLocations.first.latitude,
                      sortedDseLocations.first.longitude,
                    ),
                    zoom: 15.0,
                  ),
                ),
              );
            }

            setState(() {
              isLoading = false;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Error fetching DSE tracking status')),
            );
            setState(() {
              isLoading = false;
            });
          }
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'API request failed: ${jsonResponse['meta']['message']}')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('??')),
      );
      setState(() {
        isLoading = false;
      });
    }
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
                      fetchDseTrackingStatus(
                          Provider.of<AuthProvider>(context, listen: false)
                              .token);
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
                if (selectedDseStatus != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDseStatus!.timestamp,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                else if (selectedNearbyLocation != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedNearbyLocation!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${selectedNearbyLocation!.id}'),
                      const SizedBox(height: 8),
                      Text('Branch: ${selectedNearbyLocation!.branch}'),
                      const SizedBox(height: 8),
                      Text('Distance: ${selectedNearbyLocation!.distance} km'),
                      const SizedBox(height: 8),
                      Text('Category: ${selectedNearbyLocation!.category}'),
                      const SizedBox(height: 8),
                      Text(
                        (selectedNearbyLocation!.status == 'OUTLET' &&
                                selectedNearbyLocation!.kondisi == '1')
                            ? 'OUTLET WITH QSSO'
                            : (selectedNearbyLocation!.status == 'OUTLET' &&
                                    selectedNearbyLocation!.kondisi == '0')
                                ? 'OUTLET NO QSSO'
                                : (selectedNearbyLocation!.status == 'SITE' &&
                                        selectedNearbyLocation!.kondisi == '1')
                                    ? 'SITE NO LRS'
                                    : 'SITE WITH LRS',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (selectedNearbyLocation!.status == 'OUTLET')
                        ElevatedButton(
                          onPressed: () {
                            navigateToDetail(selectedNearbyLocation!.status,
                                selectedNearbyLocation!.id, "");
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            textStyle: const TextStyle(fontSize: 10),
                          ),
                          child: const Text('DETAIL OUTLET'),
                        )
                      else if (selectedNearbyLocation!.status == 'SITE')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                navigateToDetail(selectedNearbyLocation!.status,
                                    selectedNearbyLocation!.id, "IM3");
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
                                navigateToDetail(selectedNearbyLocation!.status,
                                    selectedNearbyLocation!.id, "3ID");
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    _checkLocationPermission().then((_) {
      if (isLocationPermissionGranted) {
        fetchDseTrackingStatus(token);
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Cari rute sebelumnya dalam tumpukan navigasi
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DseTrackingList(
              mcId: widget.mcId,
              selectedRegion: widget.selectedRegion,
              selectedArea: widget.selectedArea,
              selectedBranch: widget.selectedBranch,
            ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DseTrackingList(
                    mcId: widget.mcId,
                    selectedRegion: widget.selectedRegion,
                    selectedArea: widget.selectedArea,
                    selectedBranch: widget.selectedBranch,
                  ),
                ),
              );
            },
          ),
          title: Text(
            widget.dseId,
            style: const TextStyle(color: Colors.black),
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
                    polylines: polylines,
                    onTap: (_) {
                      setState(() {
                        showInfo = false;
                      });
                    },
                  ),
            if (showInfo) _buildInfoWindow(),
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
      ),
    );
  }
}
