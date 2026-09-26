import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _initialPosition = const LatLng(11.5564, 104.9282); // កូអរដោនេភ្នំពេញ (Default)
  LatLng? _selectedLocation;
  String _selectedAddress = "សូមជ្រើសរើសទីតាំងនៅលើផែនទី...";
  GoogleMapController? _mapController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // 📍 ទាញយកទីតាំងបច្ចុប្បន្នរបស់ទូរស័ព្ទ (GPS)
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      _selectedLocation = _initialPosition;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_initialPosition, 16),
    );
    _getAddressFromLatLng(_initialPosition);
  }

  // 📝 បម្លែង LatLng ទៅជាឈ្មោះអាសយដ្ឋានជាអក្សរ
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoading = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedAddress = "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
        });
      }
    } catch (e) {
      setState(() => _selectedAddress = "រកមិនឃើញអាសយដ្ឋានទីតាំងនេះទេ");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ជ្រើសរើសទីតាំងនៅលើផែនទី",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            // 🗺️ ពេលចុចលើផែនទី វានឹងកំណត់ Pin និងទាញយកអាសយដ្ឋាន
            onTap: (LatLng position) {
              setState(() {
                _selectedLocation = position;
              });
              _getAddressFromLatLng(position);
            },
            markers: _selectedLocation == null
                ? {}
                : {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selectedLocation!,
              ),
            },
          ),

          // 🏷️ ប្រអប់បង្ហាញអាសយដ្ឋាន និងប៊ូតុងបញ្ជាក់ទីតាំងនៅខាងក្រោម
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "អាសយដ្ឋានដែលបានជ្រើសរើស៖",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _isLoading
                      ? const LinearProgressIndicator(color: Colors.green)
                      : Text(
                    _selectedAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _selectedLocation == null
                          ? null
                          : () {
                        // 🚀 បញ្ជូនទិន្នន័យ (អាសយដ្ឋាន និងកូអរដោនេ) กลับទៅកាន់ DeliveryScreen វិញ
                        Navigator.pop(context, {
                          'address': _selectedAddress,
                          'lat': _selectedLocation!.latitude,
                          'lng': _selectedLocation!.longitude,
                        });
                      },
                      child: const Text(
                        "បញ្ជាក់ទីតាំងនេះ (Confirm Location)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}