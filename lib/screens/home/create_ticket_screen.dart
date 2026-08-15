import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:naga_app/l10n/app_localizations.dart';
import '../../widgets/onboarding/background_image.dart';
import '../../widgets/shared/language_switcher.dart';
import 'create_new_ticket_screen.dart';

class CreateTicketScreen extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const CreateTicketScreen({
    super.key,
    required this.filePath,
    required this.isVideo,
  });

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF04102A);
  static const _accent = Color(0xFF19C6FF);
  static const _accent2 = Color(0xFF29B6F6);
  static const _success = Color(0xFF00E676);
  static const _glassBg = Color(0x1AFFFFFF);

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

  static const classDescriptionsAr = {
    'GRAFFITI': 'كتابة على الجدار',
    'FADED_SIGNAGE': 'لافتة مرور أو معلومات باهتة',
    'POTHOLES': 'حفرة في الطريق',
    'GARBAGE': 'نفايات متراكمة في المنطقة',
    'CONSTRUCTION_ROAD': 'أعمال بناء طريق جارية',
    'BROKEN_SIGNAGE': 'لافتة مرور مكسورة',
    'BAD_STREETLIGHT': 'عمود إنارة معطل',
    'BAD_BILLBOARD': 'لوحة إعلانات تالفة',
    'SAND_ON_ROAD': 'رمال متراكمة على الطريق',
    'CLUTTER_SIDEWALK': 'رصيف مزدحم أو غير منظم',
    'UNKEPT_FACADE': 'واجهة مبنى غير نظيفة أو مهملة',
  };

  static const classDescriptionsEn = {
    'GRAFFITI': 'graffiti on the wall',
    'FADED_SIGNAGE': 'a faded traffic or informational sign',
    'POTHOLES': 'a pothole on the road',
    'GARBAGE': 'accumulated garbage in the area',
    'CONSTRUCTION_ROAD': 'ongoing road construction work',
    'BROKEN_SIGNAGE': 'a broken traffic sign',
    'BAD_STREETLIGHT': 'a malfunctioning streetlight',
    'BAD_BILLBOARD': 'a damaged billboard',
    'SAND_ON_ROAD': 'sand accumulated on the road',
    'CLUTTER_SIDEWALK': 'a cluttered sidewalk',
    'UNKEPT_FACADE': 'an unkept building facade',
  };

  bool _isProcessed = false;
  bool _isDetecting = false;

  List<dynamic> _detections = [];
  List<Map<String, dynamic>> _groupedResults = [];

  double _imageOriginalWidth = 0;
  double _imageOriginalHeight = 0;

  String? _originalVideoUrl;
  String? _processedVideoUrl;

  VideoPlayerController? _originalVideoController;
  VideoPlayerController? _processedVideoController;

  late AnimationController _animationController;
  late Animation<double> _analysisAnimation;

@override
void initState() {
  super.initState();

  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  _analysisAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutCubic,
  );

  if (widget.isVideo) {
    _initializeOriginalVideo();
  }
}

  @override
  void dispose() {
    _animationController.dispose();
    _originalVideoController?.dispose();
    _processedVideoController?.dispose();
    super.dispose();
  }

  double _getOverallConfidence() {
    if (_detections.isEmpty) return 0;

    double total = 0;
    int count = 0;

    for (final detection in _detections) {
      try {
        total += (detection['confidence'] as num).toDouble();
        count++;
      } catch (_) {}
    }

    return count == 0 ? 0 : (total / count).clamp(0.0, 1.0);
  }

  String _generateDescription(bool isArabic) {
    final classes = <String>[];

    for (final detection in _detections) {
      try {
        final name = detection['className'].toString().toUpperCase();
        if (!classes.contains(name)) classes.add(name);
      } catch (_) {}
    }

    if (classes.isEmpty) {
      return isArabic
          ? 'لم يتم اكتشاف أي مشكلة في ${widget.isVideo ? 'الفيديو' : 'الصورة'}.'
          : 'No pollution issues were detected in the ${widget.isVideo ? 'video' : 'image'}.';
    }

    final descriptions = classes.map((name) {
      return isArabic
          ? (classDescriptionsAr[name] ?? 'مشكلة غير معروفة')
          : (classDescriptionsEn[name] ?? 'an unknown issue');
    }).toList();

    if (descriptions.length == 1) {
      return isArabic
          ? 'اكتشف النظام ${descriptions.first}.'
          : 'The system detected ${descriptions.first}.';
    }

    if (descriptions.length == 2) {
      return isArabic
          ? 'اكتشف النظام ${descriptions[0]} و${descriptions[1]}.'
          : 'The system detected ${descriptions[0]} and ${descriptions[1]}.';
    }

    return isArabic
        ? 'اكتشف النظام ${descriptions[0]}، ${descriptions[1]} والمزيد من المشاكل.'
        : 'The system detected ${descriptions[0]}, ${descriptions[1]} and more issues.';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _navy,
      body: Stack(
        children: [
          const BackgroundImage(imagePath: 'assets/images/bg3.png'),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _navy.withOpacity(.80),
                  _navy.withOpacity(.60),
                  _navy.withOpacity(.92),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildHeader(l10n, isArabic),
                  const SizedBox(height: 35),

                  _buildSection(
                    title: widget.isVideo
                        ? l10n.originalVideo
                        : l10n.originalImage,
                    icon: widget.isVideo
                        ? Icons.videocam_outlined
                        : Icons.image_outlined,
                    iconColor: _accent,
                    borderColor: _accent.withOpacity(.35),
                    child: widget.isVideo
                        ? _buildOriginalVideo()
                        : _buildImagePreview(false, isArabic),
                  ),

                  if (_isProcessed) ...[
                    const SizedBox(height: 24),
                    _buildAnimated(
                      child: _buildAIAnalysis(l10n, isArabic),
                    ),
                  ],

                  const SizedBox(height: 28),
                  _buildDetectionButtons(l10n),

                  if (_isProcessed) ...[
                    const SizedBox(height: 14),
                    _buildAnimated(
                      child: _buildOpenTicketButton(l10n),
                    ),
                  ],

                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isArabic) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              SizedBox(width: isArabic ? 52 : 22),
              Text(
                l10n.createTicket,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: .85,
            child: const LanguageSwitcher(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: iconColor.withOpacity(.25),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberCircle(String number) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_accent, _accent2],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(.30),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAnimated({required Widget child}) {
    final slide = Tween<Offset>(
      begin: const Offset(0, .05),
      end: Offset.zero,
    ).animate(_analysisAnimation);

    final scale = Tween<double>(
      begin: .97,
      end: 1,
    ).animate(_analysisAnimation);

    return FadeTransition(
      opacity: _analysisAnimation,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool processed, bool isArabic) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: processed
              ? _success.withOpacity(.25)
              : Colors.white.withOpacity(.10),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildImageWithDetection(processed, isArabic),
    );
  }

  Widget _buildImageWithDetection(bool processed, bool isArabic) {
    if (!processed ||
        _imageOriginalWidth <= 0 ||
        _imageOriginalHeight <= 0) {
      return Image.file(
        File(widget.filePath),
        fit: BoxFit.contain,
      );
    }

    return AspectRatio(
      aspectRatio: _imageOriginalWidth / _imageOriginalHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(widget.filePath),
            fit: BoxFit.contain,
          ),
          if (_detections.isNotEmpty)
            CustomPaint(
              painter: BoundingBoxPainter(
                detections: _detections,
                imageOriginalWidth: _imageOriginalWidth,
                imageOriginalHeight: _imageOriginalHeight,
                isArabic: isArabic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOriginalVideo() {
    if (_originalVideoController == null ||
        !_originalVideoController!.value.isInitialized) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    return _buildVideoPlayer(_originalVideoController!);
  }

  Widget _buildProcessedVideo() {
    if (_processedVideoController == null ||
        !_processedVideoController!.value.isInitialized) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: CircularProgressIndicator(color: _success),
        ),
      );
    }

    final ratio = _originalVideoController != null &&
            _originalVideoController!.value.isInitialized &&
            _originalVideoController!.value.aspectRatio > 0
        ? _originalVideoController!.value.aspectRatio
        : _processedVideoController!.value.aspectRatio > 0
            ? _processedVideoController!.value.aspectRatio
            : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _processedVideoController!.value.size.width > 0
                      ? _processedVideoController!.value.size.width
                      : 1920,
                  height: _processedVideoController!.value.size.height > 0
                      ? _processedVideoController!.value.size.height
                      : 1080,
                  child: VideoPlayer(_processedVideoController!),
                ),
              ),
              _VideoPlayButton(
                controller: _processedVideoController!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController controller) {
    final ratio = controller.value.aspectRatio > 0
        ? controller.value.aspectRatio
        : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: controller.value.size.width > 0
                      ? controller.value.size.width
                      : 1920,
                  height: controller.value.size.height > 0
                      ? controller.value.size.height
                      : 1080,
                  child: VideoPlayer(controller),
                ),
              ),
              _VideoPlayButton(controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIAnalysis(
    AppLocalizations l10n,
    bool isArabic,
  ) {
    final confidence = _getOverallConfidence();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _success.withOpacity(.35),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalysisHeader(l10n, isArabic),
              const SizedBox(height: 18),

              _buildProcessedMedia(
                l10n,
                isArabic,
              ),

              const SizedBox(height: 22),
              _buildDivider(),

              const SizedBox(height: 20),
              _buildConfidenceAndIssues(
                confidence,
                l10n,
                isArabic,
              ),

              const SizedBox(height: 18),
              _buildDivider(),

              const SizedBox(height: 20),
              _buildDescriptionContent(isArabic),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisHeader(
    AppLocalizations l10n,
    bool isArabic,
  ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _success.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _success.withOpacity(.25),
            ),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: _success,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.aiAnalysisResults,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // const Icon(
        //   Icons.analytics_outlined,
        //   color: _success,
        //   size: 22,
        // ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _success.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _success.withOpacity(.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: _success,
                size: 12,
              ),
              const SizedBox(width: 3),
              Text(
                isArabic ? 'مكتمل' : 'Completed',
                style: const TextStyle(
                  color: _success,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessedMedia(
    AppLocalizations l10n,
    bool isArabic,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.isVideo
                  ? Icons.auto_awesome_motion
                  : Icons.auto_awesome,
              color: _success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.isVideo
                  ? l10n.processedVideo
                  : l10n.processedImage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.40),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _success.withOpacity(.22),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: widget.isVideo
              ? _buildProcessedVideo()
              : _buildImagePreview(true, isArabic),
        ),
      ],
    );
  }

  Widget _buildConfidenceAndIssues(
  double confidence,
  AppLocalizations l10n,
  bool isArabic,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ==========================================
      // Detected Issues Header
      // ==========================================
      Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: _accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isArabic ? 'المشاكل المكتشفة' : 'Detected Issues',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),

      // ==========================================
      // Chart + Issues List
      // ==========================================
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------
          // Overall Confidence Chart
          // ----------------------------------------
          SizedBox(
            width: 115,
            height: 115,
            child: CustomPaint(
              painter: OverallConfidencePainter(
                confidence: confidence,
                progressColor: _accent,
                secondaryColor: const Color(0xFF6C4DFF),
                backgroundColor: Colors.white.withOpacity(.08),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(confidence * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'الثقة العامة'
                          : 'Overall\nConfidence',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.75),
                        fontSize: 9,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ----------------------------------------
          // Detected Issues List
          // ----------------------------------------
          Expanded(
            child: _groupedResults.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      l10n.noPollutionDetected,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.70),
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._groupedResults.map(
                        (item) => _buildResultItem(
                          item,
                          isArabic,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildResultItem(
    Map<String, dynamic> item,
    bool isArabic,
  ) {
    final confidence = item['confidence'] as double;
    final color = item['color'] as Color;
    final className = item['label'].toString().toUpperCase();
    final count = item['count'] as int;

    final label = isArabic
        ? (pollutionClassesAr[className] ?? className)
        : _getEnglishClassName(className);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getClassIcon(className),
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isArabic
                          ? '$count اكتشاف'
                          : '$count ${count == 1 ? 'detection' : 'detections'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.50),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(confidence * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: Colors.white.withOpacity(.08),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionContent(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: _accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic
                    ? 'الوصف المُولَّد بالذكاء الاصطناعي'
                    : 'AI Generated Description',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _accent.withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _generateDescription(isArabic),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isArabic
              ? 'يمكنك تعديل هذا الوصف عند فتح البلاغ.'
              : 'You can edit this description while opening the ticket.',
          style: TextStyle(
            color: Colors.white.withOpacity(.65),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withOpacity(.08),
    );
  }

  Widget _buildDetectionButtons(AppLocalizations l10n) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final label = _isProcessed
        ? (isArabic ? 'إعادة التحليل' : 'Re-analyze')
        : l10n.detectPollution;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _buildButton(
            label: label,
            icon: _isProcessed ? Icons.refresh : Icons.auto_awesome,
            isPrimary: !_isProcessed,
            backgroundColor: _isProcessed
                ? Colors.white.withOpacity(.10)
                : null,
            isLoading: _isDetecting,
            onTap: _isDetecting
                ? () {}
                : () => _startDetection(l10n),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildButton(
            label: l10n.clear,
            icon: Icons.delete_outline,
            isPrimary: false,
            textColor: Colors.black87,
            backgroundColor: Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

 Widget _buildOpenTicketButton(AppLocalizations l10n) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  
  return _buildButton(
    label: l10n.openTicket,
    icon: Icons.confirmation_number_outlined,
    isPrimary: true,
    onTap: () async { // 👈 1. إضافة async هنا
      final detectedClasses = _detections
          .map((d) => d['className'].toString().toUpperCase())
          .toSet()
          .toList();

      final generatedDescription = _generateDescription(isArabic);

      // 👈 2. إضافة await واستقبال النتيجة في متغير (result)
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateNewTicketScreen(
            initialDescription: generatedDescription,
            detectedClasses: detectedClasses,
            filePath: widget.filePath,
            isVideo: widget.isVideo,
          ),
        ),
      );

      // 👈 3. لو النتيجة true (تم الإرسال بنجاح)، نقفل شاشة CreateTicketScreen
      if (result == true && mounted) {
        Navigator.pop(context);
      }
    },
  );
}

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
    Color? textColor,
    Color? backgroundColor,
    bool isLoading = false,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [_accent, _accent2],
                )
              : null,
          color: backgroundColor,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: _accent.withOpacity(.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isLoading
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.isVideo
                            ? (isArabic
                                ? 'جاري تحليل الفيديو...'
                                : 'Analyzing video...')
                            : (isArabic
                                ? 'جاري التحليل...'
                                : 'Analyzing...'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: ValueKey('$label-$icon'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: textColor ?? Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: textColor ?? Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _startDetection(AppLocalizations l10n) async {
    if (_isDetecting) return;

    setState(() => _isDetecting = true);
    _animationController.reset();
    _showAnalyzingDialog(l10n);

    try {
      final file = File(widget.filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      if (!widget.isVideo) {
        final bytes = await file.readAsBytes();
        final image = await decodeImageFromList(bytes);

        _imageOriginalWidth = image.width.toDouble();
        _imageOriginalHeight = image.height.toDouble();
      }

      final baseUrl = dotenv.env['API_BASE_URL'] ??
          'http://192.168.1.100:5021/api';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/TestDetection/upload'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          widget.filePath,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final setCookie = response.headers['set-cookie'];
      if (setCookie != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_cookie', setCookie);
        debugPrint('✅ Session Cookie Saved: $setCookie');
      }

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _showError('API Error: ${response.statusCode}');
        return;
      }

      final jsonData = jsonDecode(responseData);

      if (jsonData is Map && jsonData.containsKey('error')) {
        _showError(jsonData['error'].toString());
        return;
      }

      final responseType = jsonData is Map
          ? jsonData['type']?.toString().toLowerCase()
          : null;

      if (widget.isVideo || responseType == 'video') {
        await _handleVideoResponse(jsonData);
      } else {
        _handleImageResponse(jsonData);
      }

      if (!mounted) return;

      setState(() {
        _isProcessed = true;
        _isDetecting = false;
      });

      _animationController.forward(from: 0);
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();

        setState(() => _isDetecting = false);
        _showError(l10n.connectionError);
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  void _handleImageResponse(dynamic jsonData) {
    final raw = jsonData['detections'];

    _detections = raw is List ? List<dynamic>.from(raw) : [];
    _processResultsForCards();
  }

  Future<void> _handleVideoResponse(dynamic jsonData) async {
    final originalUrl = jsonData['originalVideoUrl']?.toString();
    final processedUrl = jsonData['processedVideoUrl']?.toString();
    final raw = jsonData['detections'];

    _detections = raw is List ? List<dynamic>.from(raw) : [];
    _processResultsForCards();

    if (processedUrl != null && processedUrl.isNotEmpty) {
      _processedVideoUrl = _normalizeMediaUrl(processedUrl);
      await _initializeProcessedVideo();
    }
  }

  String _normalizeMediaUrl(String url) {
    final baseUrl = dotenv.env['API_BASE_URL'] ??
        'http://192.168.1.100:5021/api';

    final uri = Uri.parse(url);

    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      final baseUri = Uri.parse(baseUrl);

      return Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : 80,
        path: uri.path,
        query: uri.query,
      ).toString();
    }

    return url;
  }

  Future<void> _initializeOriginalVideo() async {
  await _originalVideoController?.dispose();

  final controller = VideoPlayerController.file(
    File(widget.filePath),
  );

  _originalVideoController = controller;

  try {
    await controller.initialize();

    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    debugPrint('Original video initialization error: $e');
  }
}

  Future<void> _initializeProcessedVideo() async {
    if (_processedVideoUrl == null) return;

    await _processedVideoController?.dispose();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_processedVideoUrl!),
    );

    _processedVideoController = controller;
    await controller.initialize();

    if (mounted) setState(() {});
  }

  void _processResultsForCards() {
    final confidence = <String, double>{};
    final count = <String, int>{};

    for (final detection in _detections) {
      try {
        final name = detection['className'].toString().toUpperCase();
        final value = (detection['confidence'] as num).toDouble();

        count[name] = (count[name] ?? 0) + 1;

        if (!confidence.containsKey(name) ||
            value > confidence[name]!) {
          confidence[name] = value;
        }
      } catch (_) {}
    }

    _groupedResults = confidence.entries.map((entry) {
      return {
        'label': entry.key,
        'confidence': entry.value,
        'count': count[entry.key] ?? 0,
        'color': _getClassColor(entry.key),
      };
    }).toList();

    _groupedResults.sort(
      (a, b) => (b['confidence'] as double)
          .compareTo(a['confidence'] as double),
    );
  }

  String _getEnglishClassName(String className) {
    const names = {
      'GARBAGE': 'Garbage',
      'GRAFFITI': 'Graffiti',
      'FADED_SIGNAGE': 'Faded Signage',
      'POTHOLES': 'Potholes',
      'CONSTRUCTION_ROAD': 'Construction Road',
      'BROKEN_SIGNAGE': 'Broken Signage',
      'BAD_STREETLIGHT': 'Bad Streetlight',
      'BAD_BILLBOARD': 'Bad Billboard',
      'SAND_ON_ROAD': 'Sand on Road',
      'CLUTTER_SIDEWALK': 'Cluttered Sidewalk',
      'UNKEPT_FACADE': 'Unkept Facade',
    };

    return names[className] ?? className;
  }

  IconData _getClassIcon(String className) {
    switch (className.toUpperCase()) {
      case 'GARBAGE':
        return Icons.delete_outline;
      case 'GRAFFITI':
        return Icons.auto_fix_high;
      case 'POTHOLES':
        return Icons.warning_amber_rounded;
      case 'FADED_SIGNAGE':
      case 'BROKEN_SIGNAGE':
        return Icons.signpost_outlined;
      case 'BAD_STREETLIGHT':
        return Icons.lightbulb_outline;
      case 'BAD_BILLBOARD':
        return Icons.dashboard_outlined;
      case 'CONSTRUCTION_ROAD':
        return Icons.construction_outlined;
      case 'SAND_ON_ROAD':
        return Icons.landscape_outlined;
      case 'CLUTTER_SIDEWALK':
        return Icons.directions_walk;
      case 'UNKEPT_FACADE':
        return Icons.home_work_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getClassColor(String className) {
    switch (className.toUpperCase()) {
      case 'GRAFFITI':
        return const Color(0xFFFF5252);
      case 'GARBAGE':
        return const Color(0xFFFFB74D);
      default:
        return const Color(0xFFFFB74D);
    }
  }

  void _showAnalyzingDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final isArabic =
            Localizations.localeOf(context).languageCode == 'ar';

        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 15,
                sigmaY: 15,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _accent.withOpacity(.30),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: _accent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.isVideo
                          ? l10n.analyzingVideo
                          : l10n.analyzingImage,
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isVideo
                          ? l10n.detectingVideoElements
                          : l10n.detectingElements,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.70),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _VideoPlayButton extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoPlayButton({
    required this.controller,
  });

  @override
  State<_VideoPlayButton> createState() => _VideoPlayButtonState();
}

class _VideoPlayButtonState extends State<_VideoPlayButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.controller.value.isPlaying;

    return GestureDetector(
      onTap: () {
        if (playing) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }
        setState(() {});
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: playing ? 0 : 1,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(.60),
            border: Border.all(
              color: Colors.white.withOpacity(.25),
            ),
          ),
          child: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }
}

class OverallConfidencePainter extends CustomPainter {
  final double confidence;
  final Color progressColor;
  final Color secondaryColor;
  final Color backgroundColor;

  OverallConfidencePainter({
    required this.confidence,
    required this.progressColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 9.0;

    final bg = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      center,
      radius - stroke / 2,
      bg,
    );

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final progress = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2,
        colors: [
          progressColor,
          secondaryColor,
          progressColor,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius - stroke / 2,
      ),
      -math.pi / 2,
      math.pi * 2 * confidence,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(
    covariant OverallConfidencePainter oldDelegate,
  ) {
    return oldDelegate.confidence != confidence ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  final double imageOriginalWidth;
  final double imageOriginalHeight;
  final bool isArabic;

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

  BoundingBoxPainter({
    required this.detections,
    required this.imageOriginalWidth,
    required this.imageOriginalHeight,
    required this.isArabic,
  });

  String _getEnglishClassName(String className) {
    const names = {
      'GARBAGE': 'Garbage',
      'GRAFFITI': 'Graffiti',
      'FADED_SIGNAGE': 'Faded Signage',
      'POTHOLES': 'Potholes',
      'CONSTRUCTION_ROAD': 'Construction Road',
      'BROKEN_SIGNAGE': 'Broken Signage',
      'BAD_STREETLIGHT': 'Bad Streetlight',
      'BAD_BILLBOARD': 'Bad Billboard',
      'SAND_ON_ROAD': 'Sand on Road',
      'CLUTTER_SIDEWALK': 'Cluttered Sidewalk',
      'UNKEPT_FACADE': 'Unkept Facade',
    };

    return names[className] ?? className;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (imageOriginalWidth <= 0 ||
        imageOriginalHeight <= 0 ||
        detections.isEmpty) {
      return;
    }

    final imageRatio =
        imageOriginalWidth / imageOriginalHeight;
    final canvasRatio = size.width / size.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (canvasRatio > imageRatio) {
      scale = size.height / imageOriginalHeight;
      offsetX =
          (size.width - imageOriginalWidth * scale) / 2;
    } else {
      scale = size.width / imageOriginalWidth;
      offsetY =
          (size.height - imageOriginalHeight * scale) / 2;
    }

    for (final detection in detections) {
      try {
        final x = (detection['x'] as num).toDouble();
        final y = (detection['y'] as num).toDouble();
        final width = (detection['width'] as num).toDouble();
        final height = (detection['height'] as num).toDouble();
        final confidence =
            (detection['confidence'] as num).toDouble();

        final className =
            detection['className'].toString().toUpperCase();

        final label = isArabic
            ? (pollutionClassesAr[className] ?? className)
            : _getEnglishClassName(className);

        final boxColor = className == 'GRAFFITI'
            ? const Color(0xFFFF5252)
            : const Color(0xFFFFB74D);

        final rect = Rect.fromLTWH(
          offsetX + x * scale,
          offsetY + y * scale,
          width * scale,
          height * scale,
        );

        final boxPaint = Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

        canvas.drawRect(rect, boxPaint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$label ${(confidence * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection:
              isArabic ? TextDirection.rtl : TextDirection.ltr,
        )..layout();

        final labelWidth = textPainter.width + 10;
        final labelHeight = textPainter.height + 6;

        double labelX = rect.left;
        double labelY = rect.top - labelHeight;

        if (labelY < 0) labelY = rect.top;
        if (labelX < 0) labelX = 0;
        if (labelX + labelWidth > size.width) {
          labelX = size.width - labelWidth;
        }

        canvas.drawRect(
          Rect.fromLTWH(
            labelX,
            labelY,
            labelWidth,
            labelHeight,
          ),
          Paint()..color = boxColor.withOpacity(.90),
        );

        textPainter.paint(
          canvas,
          Offset(labelX + 5, labelY + 3),
        );
      } catch (_) {}
    }
  }

  @override
  bool shouldRepaint(
    covariant BoundingBoxPainter oldDelegate,
  ) {
    return true;
  }
}