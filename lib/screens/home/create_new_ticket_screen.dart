import 'dart:ui';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';

import 'package:naga_app/l10n/app_localizations.dart';
import '../../widgets/onboarding/background_image.dart';
import '../../widgets/shared/language_switcher.dart';
import '../../services/ticket_service.dart';

class CreateNewTicketScreen extends StatefulWidget {
  final String initialDescription;
  final List<String> detectedClasses;
  final String filePath;
  final bool isVideo;

  const CreateNewTicketScreen({
    super.key,
    required this.initialDescription,
    required this.detectedClasses,
    required this.filePath,
    required this.isVideo,
  });

  @override
  State<CreateNewTicketScreen> createState() =>
      _CreateNewTicketScreenState();
}

class _CreateNewTicketScreenState extends State<CreateNewTicketScreen> {
  final MapController _mapController = MapController();

  static const _navy = Color(0xFF04102A);
  static const _accent = Color(0xFF19C6FF);
  static const _accent2 = Color(0xff29B6F6);
  static const _glassBg = Color(0x1AFFFFFF);

  late TextEditingController _descriptionController;

  final Set<String> _selectedElements = {};

  bool _isElementsHidden = false;
  bool _isSubmitting = false;

  // =========================================================
  // Location
  // =========================================================

  // Nullable:
  // لو null معناها لسه مفيش Location حقيقية.
  LatLng? _selectedLocation;

  bool _isDetectingLocation = true;

  String _addressAr = "جاري تحديد الموقع...";
  String _addressEn = "Detecting location...";

  // ده مجرد مركز بصري للخريطة لو مفيش Location.
  // لا يتم استخدامه كـ Ticket Location ولا يتم إرساله للـ Backend.
  static const LatLng _mapFallbackCenter =
      LatLng(24.7136 , 46.6753);

  // =========================================================
  // Pollution Classes
  // =========================================================

  static const pollutionClassesAr = {
    'GRAFFITI': 'كتابة على الجدران',
    'FADED_SIGNAGE': 'لافتة باهتة',
    'POTHOLES': 'حفر في الطريق',
    'GARBAGE': 'قمامة',
    'CONSTRUCTION_ROAD': 'أعمال طرق',
    'BROKEN_SIGNAGE': 'لافتة مكسورة',
    'BAD_STREETLIGHT': 'إضاءة شارع سيئة',
    'BAD_BILLBOARD': 'لوحة إعلانية تالفة',
    'SAND_ON_ROAD': 'رمال على الطريق',
    'CLUTTER_SIDEWALK': 'رصيف غير منظم',
    'UNKEPT_FACADE': 'واجهة مهملة',
  };

  static const pollutionClassesEn = {
    'GRAFFITI': 'GRAFFITI',
    'FADED_SIGNAGE': 'FADED SIGNAGE',
    'POTHOLES': 'POTHOLES',
    'GARBAGE': 'GARBAGE',
    'CONSTRUCTION_ROAD': 'CONSTRUCTION ROAD',
    'BROKEN_SIGNAGE': 'BROKEN SIGNAGE',
    'BAD_STREETLIGHT': 'BAD STREETLIGHT',
    'BAD_BILLBOARD': 'BAD BILLBOARD',
    'SAND_ON_ROAD': 'SAND ON ROAD',
    'CLUTTER_SIDEWALK': 'CLUTTER SIDEWALK',
    'UNKEPT_FACADE': 'UNKEPT FACADE',
  };

  // =========================================================
  // Init
  // =========================================================

  @override
  void initState() {
    super.initState();

    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );

    for (var element in widget.detectedClasses) {
      if (pollutionClassesEn.containsKey(element)) {
        _selectedElements.add(element);
      }
    }

    // محاولة تحديد الموقع
    _extractLocationFromImage();
  }

  // =========================================================
  // Location Detection
  // =========================================================

  Future<void> _extractLocationFromImage() async {
    if (mounted) {
      setState(() {
        _isDetectingLocation = true;
      });
    }

    if (!widget.isVideo) {
      try {
        final bytes = await File(widget.filePath).readAsBytes();

        final tags = await readExifFromBytes(bytes);

        final hasLatitude =
            tags.containsKey('GPS GPSLatitude');

        final hasLongitude =
            tags.containsKey('GPS GPSLongitude');

        if (hasLatitude && hasLongitude) {
          final latData =
              tags['GPS GPSLatitude']!.values.toList();

          final lngData =
              tags['GPS GPSLongitude']!.values.toList();

          final latRef =
              tags['GPS GPSLatitudeRef']?.printable;

          final lngRef =
              tags['GPS GPSLongitudeRef']?.printable;

          double lat = _convertGpsToDouble(latData);
          double lng = _convertGpsToDouble(lngData);

          if (latRef == 'S') {
            lat = -lat;
          }

          if (lngRef == 'W') {
            lng = -lng;
          }

          final location = LatLng(lat, lng);

          if (!mounted) return;

          setState(() {
            _selectedLocation = location;
            _isDetectingLocation = false;
          });

          // تحريك الخريطة إلى مكان الصورة
          _mapController.move(
            location,
            14.0,
          );

          // Reverse Geocoding
          await _getAddressFromLatLng(
            lat,
            lng,
          );

          return;
        }
      } catch (e) {
        debugPrint(
          "Error reading EXIF GPS: $e",
        );
      }
    }

    await _getDeviceLocation();
  }

  double _convertGpsToDouble(List<dynamic> values) {
    double degrees =
        values[0].numerator / values[0].denominator;

    double minutes =
        values[1].numerator / values[1].denominator;

    double seconds =
        values[2].numerator / values[2].denominator;

    return degrees +
        (minutes / 60.0) +
        (seconds / 3600.0);
  }

  // =========================================================
  // Device GPS
  // =========================================================

  Future<void> _getDeviceLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint(
          "Location services are disabled.",
        );

        _locationUnavailable();
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        debugPrint(
          "Location permission denied.",
        );

        _locationUnavailable();
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selectedLocation = location;
        _isDetectingLocation = false;
      });

      _mapController.move(
        location,
        14.0,
      );

      await _getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint(
        "Error getting device location: $e",
      );

      _locationUnavailable();
    }
  }

  // =========================================================
  // Location unavailable
  // =========================================================

  void _locationUnavailable() {
    if (!mounted) return;

    setState(() {
      _selectedLocation = null;
      _isDetectingLocation = false;

      _addressAr = "لم يتم تحديد الموقع";
      _addressEn = "Location not available";
    });
  }

  // =========================================================
  // Reverse Geocoding
  // =========================================================

  Future<void> _getAddressFromLatLng(
    double lat,
    double lng,
  ) async {
    try {
      final urlAr = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=$lat'
        '&lon=$lng'
        '&accept-language=ar',
      );

      final responseAr = await http.get(
        urlAr,
        headers: {
          'User-Agent': 'com.naga.app',
        },
      );

      final urlEn = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=$lat'
        '&lon=$lng'
        '&accept-language=en',
      );

      final responseEn = await http.get(
        urlEn,
        headers: {
          'User-Agent': 'com.naga.app',
        },
      );

      if (responseAr.statusCode == 200 &&
          responseEn.statusCode == 200) {
        final dataAr =
            jsonDecode(responseAr.body);

        final dataEn =
            jsonDecode(responseEn.body);

        if (mounted) {
          setState(() {
            _addressAr =
                _formatAddress(dataAr['address']);

            _addressEn =
                _formatAddress(dataEn['address']);
          });
        }
      }
    } catch (e) {
      debugPrint(
        "Error fetching address: $e",
      );

      if (mounted) {
        setState(() {
          _addressAr = "الموقع غير معروف";
          _addressEn = "Unknown Location";
        });
      }
    }
  }

  // =========================================================
  // Format Address
  // =========================================================

  String _formatAddress(
    Map<String, dynamic>? addressInfo,
  ) {
    if (addressInfo == null) {
      return "Unknown Location";
    }

    final List<String> parts = [];

    if (addressInfo['road'] != null) {
      parts.add(addressInfo['road']);
    } else if (addressInfo['pedestrian'] != null) {
      parts.add(addressInfo['pedestrian']);
    }

    if (addressInfo['suburb'] != null) {
      parts.add(addressInfo['suburb']);
    } else if (addressInfo['neighbourhood'] != null) {
      parts.add(addressInfo['neighbourhood']);
    }

    if (addressInfo['city'] != null) {
      parts.add(addressInfo['city']);
    } else if (addressInfo['town'] != null) {
      parts.add(addressInfo['town']);
    } else if (addressInfo['county'] != null) {
      parts.add(addressInfo['county']);
    }

    if (addressInfo['state'] != null) {
      parts.add(addressInfo['state']);
    }

    if (addressInfo['postcode'] != null) {
      parts.add(addressInfo['postcode']);
    }

    if (parts.isEmpty) {
      return "Unknown Location";
    }

    return parts.join(", ");
  }

  // =========================================================
  // Dispose
  // =========================================================

  @override
  void dispose() {
    _descriptionController.dispose();
    _mapController.dispose();

    super.dispose();
  }

  // =========================================================
  // Submit Ticket
  // =========================================================

  Future<void> _submitTicket() async {
    if (_isSubmitting) return;

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a description.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a location before submitting the ticket.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final location = _selectedLocation!;

      final payloadAddress =
          "$_addressAr - $_addressEn";

      final isSuccess =
          await TicketService.createTicket(
        description:
            _descriptionController.text.trim(),

        pollutionTypes:
            _selectedElements.toList(),

        latitude:
            location.latitude,

        longitude:
            location.longitude,

        address:
            payloadAddress,
      );

      if (!mounted) return;

      final isArabic =
          Localizations.localeOf(context)
                  .languageCode ==
              'ar';

      // ----------------------------------------------------
      // Success
      // ----------------------------------------------------

      if (isSuccess) {
        _showCustomPopup(
          isSuccess: true,
          title: isArabic
              ? "تم إرسال البلاغ"
              : "Ticket Submitted",
          message: isArabic
              ? "شكراً لك! تم تسجيل البلاغ بنجاح وجاري مراجعته."
              : "Thank you! Your ticket has been created successfully.",
          buttonText: isArabic
              ? "العودة للرئيسية"
              : "Back to Home",
          onPressed: () {
            // 🚀 نقفل الـ popup
            Navigator.of(context).pop();

            // 🚀 نقفل الشاشة دي (CreateNewTicketScreen) ونمرر true
            // للشاشة اللي فتحتها (CreateTicketScreen)، واللي بدورها
            // هتقفل نفسها وتمرر true لـ HomeScreen عشان تعمل Refresh.
            Navigator.of(context).pop(true);
          },
        );
      }

      // ----------------------------------------------------
      // Failed
      // ----------------------------------------------------

      else {
        _showCustomPopup(
          isSuccess: false,
          title: isArabic
              ? "فشل الإرسال"
              : "Submission Failed",
          message: isArabic
              ? "حدث خطأ أثناء إرسال البلاغ. تأكد من اتصالك بالإنترنت وحاول مجدداً."
              : "An error occurred while submitting. Please check your connection and try again.",
          buttonText: isArabic
              ? "حاول مجدداً"
              : "Try Again",
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      debugPrint(
        "Submit Error: $e",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An unexpected error occurred.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // =========================================================
  // Custom Popup
  // =========================================================

  void _showCustomPopup({
    required bool isSuccess,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(28),
                border: Border.all(
                  color:
                      Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.2),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),

                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSuccess
                          ? Colors.green.withOpacity(0.2)
                          : Colors.redAccent
                              .withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: (isSuccess
                                  ? Colors.green
                                  : Colors.redAccent)
                              .withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isSuccess
                            ? Icons.check
                            : Icons.close,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    message,
                    style: TextStyle(
                      color:
                          Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isSuccess
                            ? [
                                _accent,
                                _accent2,
                              ]
                            : [
                                const Color(0xFFFF5E62),
                                const Color(0xFFFF9966),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSuccess
                                  ? _accent
                                  : Colors.redAccent)
                              .withOpacity(0.4),
                          blurRadius: 12,
                          offset:
                              const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.transparent,
                        shadowColor:
                            Colors.transparent,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      onPressed: onPressed,
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    final isArabic =
        Localizations.localeOf(context)
                .languageCode ==
            'ar';

    return Stack(
      children: [
        const Positioned.fill(
          child: BackgroundImage(
            imagePath: 'assets/images/bg3.png',
          ),
        ),

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _navy.withOpacity(.85),
                  _navy.withOpacity(.70),
                  _navy.withOpacity(.95),
                ],
              ),
            ),
          ),
        ),

        Scaffold(
          backgroundColor:
              Colors.transparent,

          extendBodyBehindAppBar: true,

          body: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              child: Column(
                children: [
                  _buildHeader(isArabic),

                  const SizedBox(height: 20),

                  const Icon(
                    Icons.confirmation_number,
                    color: _accent,
                    size: 40,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    l10n.createNewTicketTitle,
                    style:
                        const TextStyle(
                      color: _accent,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    l10n.enterDetails,
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          Colors.white.withOpacity(
                        0.8,
                      ),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildDescriptionSection(
                    l10n,
                    isArabic,
                  ),

                  const SizedBox(height: 25),

                  _buildElementsSection(
                    l10n,
                    isArabic,
                  ),

                  const SizedBox(height: 25),

                  _buildMapSection(
                    l10n,
                    isArabic,
                  ),

                  const SizedBox(height: 30),

                  _buildActionButtons(
                    l10n,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Header
  // =========================================================

  Widget _buildHeader(
    bool isArabic,
  ) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
          ),

          Transform.scale(
            scale: .85,
            child:
                const LanguageSwitcher(),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Description
  // =========================================================

  Widget _buildDescriptionSection(
    AppLocalizations l10n,
    bool isArabic,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.description_outlined,
              color: _accent,
              size: 20,
            ),

            const SizedBox(width: 8),

            Text(
              l10n.descriptionLabel,
              style: const TextStyle(
                color: _accent,
                fontSize: 15,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5,
              sigmaY: 5,
            ),
            child: TextFormField(
              controller:
                  _descriptionController,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration:
                  InputDecoration(
                filled: true,
                fillColor: _glassBg,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  borderSide:
                      BorderSide(
                    color: Colors.white
                        .withOpacity(0.2),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  borderSide:
                      BorderSide(
                    color: Colors.white
                        .withOpacity(0.2),
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  borderSide:
                      const BorderSide(
                    color: _accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Pollution Elements
  // =========================================================

  Widget _buildElementsSection(
    AppLocalizations l10n,
    bool isArabic,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  color: _accent,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Text(
                  l10n.selectPollutionElements,
                  style:
                      const TextStyle(
                    color: _accent,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            InkWell(
              onTap: () {
                setState(() {
                  _isElementsHidden =
                      !_isElementsHidden;
                });
              },
              borderRadius:
                  BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white.withOpacity(
                    0.1,
                  ),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isElementsHidden
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white,
                      size: 16,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      _isElementsHidden
                          ? (isArabic
                              ? "إظهار"
                              : "Show")
                          : l10n.hide,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        AnimatedCrossFade(
          firstChild:
              const SizedBox(
            height: 0,
            width: double.infinity,
          ),

          secondChild:
              ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5,
                sigmaY: 5,
              ),
              child: Container(
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  color: _glassBg,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  border:
                      Border.all(
                    color:
                        _accent.withOpacity(
                      0.4,
                    ),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          pollutionClassesEn
                              .keys
                              .map(
                        (key) {
                          final isSelected =
                              _selectedElements
                                  .contains(
                            key,
                          );

                          final label =
                              isArabic
                                  ? pollutionClassesAr[
                                      key]!
                                  : pollutionClassesEn[
                                      key]!;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedElements
                                      .remove(
                                    key,
                                  );
                                } else {
                                  _selectedElements
                                      .add(
                                    key,
                                  );
                                }
                              });
                            },
                            child:
                                Container(
                              width:
                                  (MediaQuery.of(
                                              context)
                                          .size
                                          .width -
                                      85) /
                                  2,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 16,
                                horizontal: 8,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: isSelected
                                    ? _accent
                                        .withOpacity(
                                        0.2,
                                      )
                                    : Colors.black
                                        .withOpacity(
                                        0.3,
                                      ),

                                border:
                                    Border.all(
                                  color: isSelected
                                      ? _accent
                                      : Colors.white
                                          .withOpacity(
                                          0.1,
                                        ),
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),

                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons
                                            .check_box
                                        : Icons
                                            .square,
                                    color: isSelected
                                        ? _accent
                                        : Colors
                                            .white38,
                                    size: 22,
                                  ),

                                  const SizedBox(
                                      height: 8),

                                  Text(
                                    label,
                                    textAlign:
                                        TextAlign
                                            .center,
                                    style:
                                        TextStyle(
                                      color: isSelected
                                          ? _accent
                                          : Colors
                                              .white70,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(
                        height: 20),

                    Row(
                      children: [
                        Expanded(
                          child:
                              _buildSecondaryButton(
                            label:
                                l10n.selectAll,
                            icon:
                                Icons.check_box,
                            onTap: () {
                              setState(() {
                                _selectedElements
                                    .addAll(
                                  pollutionClassesEn
                                      .keys,
                                );
                              });
                            },
                          ),
                        ),

                        const SizedBox(
                            width: 10),

                        Expanded(
                          child:
                              _buildSecondaryButton(
                            label:
                                l10n.clearAll,
                            icon:
                                Icons.square,
                            onTap: () {
                              setState(() {
                                _selectedElements
                                    .clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          crossFadeState:
              _isElementsHidden
                  ? CrossFadeState
                      .showFirst
                  : CrossFadeState
                      .showSecond,

          duration:
              const Duration(
            milliseconds: 300,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Secondary Button
  // =========================================================

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 12,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.black87,
              size: 18,
            ),

            const SizedBox(width: 6),

            Text(
              label,
              style:
                  const TextStyle(
                color: Colors.black87,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Map
  // =========================================================

  Widget _buildMapSection(
    AppLocalizations l10n,
    bool isArabic,
  ) {
    final mapCenter =
        _selectedLocation ??
            _mapFallbackCenter;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.map_outlined,
              color: _accent,
              size: 20,
            ),

            const SizedBox(width: 8),

            Text(
              l10n.searchLocation,
              style: const TextStyle(
                color: _accent,
                fontSize: 15,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5,
              sigmaY: 5,
            ),
            child: Container(
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(
                color: _glassBg,
                borderRadius:
                    BorderRadius.circular(20),
                border:
                    Border.all(
                  color:
                      _accent.withOpacity(
                    0.4,
                  ),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      border:
                          Border.all(
                        color: Colors.white
                            .withOpacity(
                          0.1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(
                            0.2,
                          ),
                          blurRadius: 8,
                          offset:
                              const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController:
                                _mapController,
                            options:
                                MapOptions(
                              initialCenter:
                                  mapCenter,
                              initialZoom:
                                  14.0,

                              onTap:
                                  (
                                tapPosition,
                                point,
                              ) {
                                setState(() {
                                  _selectedLocation =
                                      point;

                                  _addressAr =
                                      "جاري تحديث الموقع...";

                                  _addressEn =
                                      "Updating location...";
                                });

                                _getAddressFromLatLng(
                                  point.latitude,
                                  point.longitude,
                                );
                              },
                            ),

                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://mt1.google.com/vt/lyrs=m&hl=${isArabic ? "ar" : "en"}&x={x}&y={y}&z={z}',
                                userAgentPackageName:
                                    'com.naga.app',
                              ),

                              MarkerLayer(
                                markers:
                                    _selectedLocation ==
                                            null
                                        ? []
                                        : [
                                            Marker(
                                              point:
                                                  _selectedLocation!,
                                              width:
                                                  45,
                                              height:
                                                  45,
                                              child:
                                                  const Icon(
                                                Icons
                                                    .location_on,
                                                color:
                                                    Colors.redAccent,
                                                size:
                                                    45,
                                              ),
                                            ),
                                          ],
                              ),
                            ],
                          ),

                          if (_isDetectingLocation)
                            Positioned.fill(
                              child:
                                  Container(
                                color: Colors
                                    .black
                                    .withOpacity(
                                  0.45,
                                ),
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        _accent,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                      height: 16),

                  Divider(
                    color: Colors.white
                        .withOpacity(0.1),
                    thickness: 1,
                  ),

                  const SizedBox(
                      height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: _accent,
                        size: 18,
                      ),

                      const SizedBox(
                          width: 8),

                      Text(
                        l10n.selectedAddress,
                        style:
                            const TextStyle(
                          color: _accent,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 8),

                  Text(
                    isArabic
                        ? _addressAr
                        : _addressEn,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(
                      height: 10),

                  if (!_isDetectingLocation)
                    Row(
                      children: [
                        Icon(
                          _selectedLocation !=
                                  null
                              ? Icons.check_circle
                              : Icons
                                  .warning_amber,
                          color:
                              _selectedLocation !=
                                      null
                                  ? Colors.greenAccent
                                  : Colors
                                      .orangeAccent,
                          size: 16,
                        ),

                        const SizedBox(
                            width: 6),

                        Expanded(
                          child: Text(
                            _selectedLocation !=
                                    null
                                ? (isArabic
                                    ? "تم تحديد الموقع. يمكنك الضغط على الخريطة لتغييره."
                                    : "Location detected. Tap the map to change it.")
                                : (isArabic
                                    ? "لم يتم تحديد الموقع. اضغط على الخريطة لتحديده يدويًا."
                                    : "Location unavailable. Tap the map to select it manually."),
                            style:
                                TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Action Buttons
  // =========================================================

  Widget _buildActionButtons(
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: InkWell(
            onTap:
                _isSubmitting
                    ? null
                    : _submitTicket,
            borderRadius:
                BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                gradient:
                    const LinearGradient(
                  colors: [
                    _accent,
                    Color(0xFF29B6F6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        _accent.withOpacity(
                      .4,
                    ),
                    blurRadius: 12,
                    offset:
                        const Offset(0, 4),
                  ),
                ],
              ),
              alignment:
                  Alignment.center,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      l10n.submitTicketBtn,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          flex: 3,
          child: InkWell(
            onTap: _isSubmitting
                ? null
                : () =>
                    Navigator.pop(context),
            borderRadius:
                BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white.withOpacity(
                  0.15,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              alignment:
                  Alignment.center,
              child: Text(
                l10n.cancelBtn,
                style: TextStyle(
                  color: _isSubmitting
                      ? Colors.white54
                      : Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}