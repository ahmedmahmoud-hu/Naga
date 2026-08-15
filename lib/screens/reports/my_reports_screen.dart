import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:naga_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/ticket_service.dart';
import '../../widgets/shared/language_switcher.dart';
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({ super.key });
  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}
class _MyReportsScreenState extends State<MyReportsScreen> {
  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xff19C6FF);
  static const Color _accent2 = Color(0xff29B6F6);
  static const Color _glassBg = Color(0x14FFFFFF);
  static const Color _glassBorder = Color(0x22FFFFFF);
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  @override
  void initState() { super.initState(); _loadTickets(); }
  Future<void> _loadTickets() async {
    if (mounted) { setState(() { _isLoading = true; _error = null; }); }
    try {
      final List<dynamic> tickets = await TicketService.getMyTickets();
      debugPrint('MY REPORTS: $tickets');
      debugPrint('COUNT: ${ tickets.length }');
      if (mounted) { setState(() { _tickets = tickets; _isLoading = false; }); }
    } catch (e) {
      debugPrint('MY REPORTS ERROR: $e');
      if (mounted) { setState(() { _isLoading = false; _error = e.toString(); }); }
    }
  }
  String _getMediaUrl(dynamic originalUrl) {
    if (originalUrl == null || originalUrl.toString().trim().isEmpty) { return ''; }
    String url = originalUrl.toString().trim();
    final markdownMatch = RegExp(r'\]\((.*?)\)').firstMatch(url);
    if (markdownMatch != null) { url = markdownMatch.group(1) ?? ''; }
    url = url.replaceFirst(
      'http://localhost:5021',
      'http://91.108.112.27:5021',
    );
    return url;
  }
  bool _isVideo(dynamic ticket) {
    final String url = ticket['originalUrl']?.toString().toLowerCase() ?? '';
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        ticket['type']?.toString().toLowerCase() == 'video';
  }
  String _formatDate(dynamic createdAt,bool isArabic,) {
    if (createdAt == null) { return isArabic ? 'تاريخ غير معروف' : 'Unknown date'; }
    try {
      final DateTime date = DateTime.parse(createdAt.toString()).toLocal();
      final String day = date.day.toString().padLeft(2, '0');
      final String month = date.month.toString().padLeft(2, '0');
      final String year = date.year.toString();
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year • $hour:$minute';
    } catch (_) { return createdAt.toString(); }
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
      case 'resolved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'in progress':
      case 'in-progress':
        return Colors.orangeAccent;
      case 'open':
      default:
        return _accent;
    }
  }
  String _getDisplayStatus(String status,bool isArabic,AppLocalizations l10n,) {
    switch (status.toLowerCase()) {
      case 'closed':
      case 'resolved':
        return l10n.resolved;
      case 'rejected':
        return l10n.rejected;
      case 'in progress':
      case 'in-progress':
        return l10n.inProgress;
      case 'open':
        return isArabic ? 'مفتوح' : 'Open';
      default:
        return status;
    }
  }
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.amberAccent;
      case 'low':
        return Colors.greenAccent;
      case 'pending':
        return Colors.lightBlueAccent;
      default:
        return Colors.white70;
    }
  }
  String _getDisplayPriority(String priority,bool isArabic,) {
    switch (priority.toLowerCase()) {
      case 'high':
        return isArabic ? 'عالية' : 'High';
      case 'medium':
        return isArabic ? 'متوسطة' : 'Medium';
      case 'low':
        return isArabic ? 'منخفضة' : 'Low';
      case 'pending':
        return isArabic ? 'معلّق' : 'Pending';
      default:
        return priority;
    }
  }
  List<dynamic> _getFilteredTickets() {
    return _tickets.where((ticket) {
      final String status = ticket['status']?.toString().toLowerCase() ?? '';
      final String priority =
          ticket['priority']?.toString().toLowerCase() ?? '';
      bool matchesStatus = true;
      if (_selectedStatus != 'all') {
        switch (_selectedStatus) {
          case 'open':
            matchesStatus = status == 'open';
            break;
          case 'progress':
            matchesStatus =
                status == 'in progress' || status == 'in-progress';
            break;
          case 'resolved':
            matchesStatus = status == 'resolved' || status == 'closed';
            break;
          case 'rejected':
            matchesStatus = status == 'rejected';
            break;
        }
      }
      bool matchesPriority = true;
      if (_selectedPriority != 'all') {
        matchesPriority = priority == _selectedPriority.toLowerCase();
      }
      return matchesStatus && matchesPriority;
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: _navy,
      resizeToAvoidBottomInset: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            width: screenWidth,
            height: screenHeight,
            child: const Image(image: AssetImage('assets/images/bg3.png',),fit: BoxFit.cover,),
          ),
          Positioned(
            top: 0,
            left: 0,
            width: screenWidth,
            height: screenHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _navy.withOpacity(0.82),
                    _navy.withOpacity(0.66),
                    _navy.withOpacity(0.96),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(isArabic,l10n,),
                  _buildFilterToolbar(isArabic,),
                  const SizedBox(height: 14),
                  Expanded(child: _buildBody(isArabic,l10n,),),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTopBar(bool isArabic,AppLocalizations l10n,) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20,20,20,0,),
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/kasct.png',height: 35,),
                Transform.scale(scale: 0.85,child: const LanguageSwitcher(),),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.12),
                  border: Border.all(color: _accent.withOpacity(0.28),),
                ),
                child: const Icon(Icons.assignment_outlined,color: _accent,size: 20,),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.navMyReports,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  Widget _buildFilterToolbar(bool isArabic,) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20,),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              value: _selectedStatus,
              icon: Icons.tune_rounded,
              width: double.infinity,
              items: [
                DropdownMenuItem(value: 'all',child: Text(isArabic ? 'الحالة' : 'Status',),),
                DropdownMenuItem(value: 'open',child: Text(isArabic ? 'مفتوح' : 'Open',),),
                DropdownMenuItem(
                  value: 'progress',
                  child: Text(isArabic ? 'قيد التنفيذ' : 'In Progress',),
                ),
                DropdownMenuItem(
                  value: 'resolved',
                  child: Text(isArabic ? 'تم الحل' : 'Resolved',),
                ),
                DropdownMenuItem(
                  value: 'rejected',
                  child: Text(isArabic ? 'مرفوض' : 'Rejected',),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() { _selectedStatus = value; });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildDropdown(
              value: _selectedPriority,
              icon: Icons.flag_outlined,
              width: double.infinity,
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(isArabic ? 'الأولوية' : 'Priority',),
                ),
                DropdownMenuItem(value: 'high',child: Text(isArabic ? 'عالية' : 'High',),),
                DropdownMenuItem(value: 'medium',child: Text(isArabic ? 'متوسطة' : 'Medium',),),
                DropdownMenuItem(value: 'low',child: Text(isArabic ? 'منخفضة' : 'Low',),),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text(isArabic ? 'معلّق' : 'Pending',),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() { _selectedPriority = value; });
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDropdown({
    required String value,
    required IconData icon,
    required double width,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isActive = value != 'all';
    return Container(
      width: width,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 7,),
      decoration: BoxDecoration(
        color: isActive
            ? _accent.withOpacity(0.10)
            : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? _accent.withOpacity(0.35)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF10213D),
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withOpacity(0.55),
            size: 18,
          ),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item.value,
              child: Row(
                children: [
                  Icon(icon,size: 15,color: isActive? _accent: Colors.white.withOpacity(0.55),),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      child: item.child,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  Widget _buildBody(bool isArabic,AppLocalizations l10n,) {
    if (_isLoading) { return const Center(child: CircularProgressIndicator(color: _accent,),); }
    if (_error != null) { return _buildErrorState(isArabic,); }
    final List<dynamic> filteredTickets = _getFilteredTickets();
    if (filteredTickets.isEmpty) { return _buildEmptyState(isArabic,); }
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _navy,
      onRefresh: _loadTickets,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics(),),
        padding: const EdgeInsets.fromLTRB(20,0,20,120,),
        itemCount: filteredTickets.length,
        itemBuilder: (context, index) {
          final ticket = filteredTickets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10,),
            child: _buildReportCard(ticket,isArabic,l10n,),
          );
        },
      ),
    );
  }
  Widget _buildReportCard(dynamic ticket,bool isArabic,AppLocalizations l10n,) {
    final String ticketNumber =
        ticket['ticketNumber']?.toString() ?? '#--------';
    final String description = ticket['description']?.toString() ??
        (isArabic ? 'لا يوجد وصف' : 'No description');
    final String date = _formatDate(ticket['createdAt'],isArabic,);
    final String status = ticket['status']?.toString() ?? 'Open';
    final String priority = ticket['priority']?.toString() ?? 'Pending';
    final String imageUrl = _getMediaUrl(ticket['originalUrl'],);
    final bool isVideo = _isVideo(ticket);
    final Color statusColor = _getStatusColor(status);
    final Color priorityColor = _getPriorityColor(priority);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TicketDetailsScreen(ticket: ticket,),),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12,sigmaY: 12,),
          child: Container(
            height: 132,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _glassBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _glassBorder,),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildThumbnail(imageUrl: imageUrl,isVideo: isVideo,),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticketNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusBadge(
                            text: _getDisplayStatus(status,isArabic,l10n,),
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white.withOpacity(0.42),
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.52),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.flag_outlined,color: priorityColor,size: 14,),
                          const SizedBox(width: 4),
                          Text(
                            _getDisplayPriority(priority,isArabic,),
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(color: Colors.white.withOpacity(0.10),),
                            ),
                            child: Icon(
                              isArabic
                                  ? Icons.arrow_back_ios_new
                                  : Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.65),
                              size: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildThumbnail({ required String imageUrl,required bool isVideo, }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 104,
        height: 110,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              isVideo
                  ? _VideoThumbnail(
                      videoUrl: imageUrl,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context,error,stackTrace,) { return _mediaError(isVideo,); },
                    )
            else
              _mediaError(isVideo),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent,Colors.black.withOpacity(0.30),],
                  ),
                ),
              ),
            ),
            if (isVideo)
              Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.45),
                    border: Border.all(color: Colors.white.withOpacity(0.65),),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,color: Colors.white,size: 23,),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatusBadge({ required String text,required Color color, }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7,vertical: 4,),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.28),),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.5),blurRadius: 5,),],
            ),
          ),
          const SizedBox(width: 5),
          Text(text,style: TextStyle(color: color,fontSize: 8.5,fontWeight: FontWeight.bold,),),
        ],
      ),
    );
  }
  Widget _buildErrorState(bool isArabic,) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.25),),
              ),
              child: const Icon(Icons.cloud_off_outlined,color: Colors.redAccent,size: 34,),
            ),
            const SizedBox(height: 18),
            Text(
              isArabic
                  ? 'حدث خطأ أثناء تحميل البلاغات'
                  : 'Failed to load reports',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadTickets,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),
              ),
              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry',),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState(bool isArabic,) {
    final bool hasFilter =
        _selectedStatus != 'all' || _selectedPriority != 'all';
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _navy,
      onRefresh: _loadTickets,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.20,),
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.08),
                border: Border.all(color: _accent.withOpacity(0.18),),
              ),
              child: Icon(
                hasFilter
                    ? Icons.filter_alt_off_outlined
                    : Icons.description_outlined,
                color: Colors.white.withOpacity(0.40),
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              hasFilter
                  ? (isArabic
                      ? 'لا توجد بلاغات مطابقة'
                      : 'No matching reports')
                  : (isArabic
                      ? 'لا توجد بلاغات حتى الآن'
                      : 'No reports yet'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!hasFilter)
            Center(
              child: Text(
                isArabic
                    ? 'ستظهر البلاغات التي ترسلها هنا'
                    : 'Your submitted reports will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.35),fontSize: 11,),
              ),
            ),
        ],
      ),
    );
  }
  Widget _mediaError(bool isVideo,) {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: Colors.white38,
        size: 30,
      ),
    );
  }
}
class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  const _VideoThumbnail({ required this.videoUrl, });
  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}
class _VideoThumbnailState extends State<_VideoThumbnail> {
  Uint8List? _thumbnailData;
  bool _loading = true;
  @override
  void initState() { super.initState(); _generateThumbnail(); }
  Future<void> _generateThumbnail() async {
    try {
      final Uint8List? data = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        maxWidth: 250,
        quality: 40,
      );
      if (mounted) { setState(() { _thumbnailData = data; _loading = false; }); }
    } catch (e) {
      debugPrint('Video thumbnail error: $e',);
      if (mounted) { setState(() { _loading = false; }); }
    }
  }
  @override
  Widget build(BuildContext context,) {
    if (_loading) {
      return Container(
        color: Colors.white.withOpacity(0.05),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2,color: Color(0xff19C6FF),),
          ),
        ),
      );
    }
    if (_thumbnailData != null) { return Image.memory(_thumbnailData!,fit: BoxFit.cover,); }
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: const Icon(Icons.videocam_outlined,color: Colors.white38,size: 30,),
    );
  }
}
class TicketDetailsScreen extends StatelessWidget {
  final dynamic ticket;
  const TicketDetailsScreen({ super.key,required this.ticket, });
  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xff19C6FF);
  static const Color _accent2 = Color(0xff29B6F6);
  static const Color _glassBg = Color(0x14FFFFFF);
  static const Color _glassBorder = Color(0x22FFFFFF);
  String _cleanUrl(dynamic originalUrl) {
    if (originalUrl == null || originalUrl.toString().trim().isEmpty) { return ''; }
    String url = originalUrl.toString().trim();
    final markdownMatch = RegExp(r'\]\((.*?)\)').firstMatch(url);
    if (markdownMatch != null) { url = markdownMatch.group(1) ?? ''; }
    url = url.replaceFirst(
      'http://localhost:5021',
      'http://91.108.112.27:5021',
    );
    return url;
  }
  bool _isVideo() {
    final String url =
        ticket['originalUrl']?.toString().toLowerCase() ?? '';
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        ticket['type']?.toString().toLowerCase() == 'video';
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
      case 'resolved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'in progress':
      case 'in-progress':
        return Colors.orangeAccent;
      case 'open':
      default:
        return _accent;
    }
  }
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      case 'pending':
        return Colors.orangeAccent;
      default:
        return Colors.white70;
    }
  }
  String _formatDate(dynamic createdAt) {
    if (createdAt == null) { return 'Unknown date'; }
    try {
      final DateTime date =
          DateTime.parse(createdAt.toString()).toLocal();
      final String day = date.day.toString().padLeft(2, '0');
      final String month = date.month.toString().padLeft(2, '0');
      final String year = date.year.toString();
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year • $hour:$minute';
    } catch (_) { return createdAt.toString(); }
  }
  dynamic _getAiData() {
    return ticket['aiAnalysis'] ??
        ticket['aiResult'] ??
        ticket['analysis'] ??
        ticket['detectionResult'];
  }
  List<dynamic> _getDetections() {
    final dynamic aiData = _getAiData();
    if (aiData is Map) {
      final dynamic detections = aiData['detections'] ??
          aiData['results'] ??
          aiData['issues'];
      if (detections is List) { return detections; }
    }
    final dynamic detections = ticket['detections'];
    if (detections is List) { return detections; }
    return [];
  }
  double _getOverallConfidence() {
    final dynamic aiData = _getAiData();
    dynamic value;
    if (aiData is Map) {
      value = aiData['overallConfidence'] ??
          aiData['overall_confidence'] ??
          aiData['confidence'];
    }
    value ??= ticket['overallConfidence'];
    if (value != null) {
      double result = double.tryParse(value.toString()) ?? 0;
      if (result <= 1) { result *= 100; }
      return result.clamp(0, 100);
    }
    final List<dynamic> detections = _getDetections();
    if (detections.isNotEmpty) {
      double sum = 0;
      for (var d in detections) { sum += _getDetectionConfidence(d); }
      return (sum / detections.length).clamp(0, 100);
    }
    return 0;
  }
  String _getAiDescription() {
    final dynamic aiData = _getAiData();
    dynamic description;
    if (aiData is Map) {
      description = aiData['description'] ??
          aiData['aiDescription'] ??
          aiData['generatedDescription'] ??
          aiData['aiGeneratedDescription'];
    }
    description ??= ticket['aiGeneratedDescription'];
    description ??= ticket['description'];
    if (description == null || description.toString().trim().isEmpty) {
      return 'No AI generated description available.';
    }
    return description.toString();
  }
  String _getClassName(dynamic detection) {
    if (detection is Map) {
      return detection['className']?.toString() ??
          detection['class']?.toString() ??
          detection['label']?.toString() ??
          'Unknown';
    }
    return 'Unknown';
  }
  double _getDetectionConfidence(dynamic detection) {
    if (detection is! Map) { return 0; }
    dynamic value = detection['confidence'] ?? detection['score'];
    if (value == null) { return 0; }
    double result = double.tryParse(value.toString()) ?? 0;
    if (result <= 1) { result *= 100; }
    return result.clamp(0, 100);
  }
  int _getDetectionCount(String className,List<dynamic> detections,) {
    return detections.where((detection) {
      return _getClassName(detection).toLowerCase() ==
          className.toLowerCase();
    }).length;
  }
  List<Map<String, dynamic>> _groupDetections(List<dynamic> detections,) {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final detection in detections) {
      final String className = _getClassName(detection);
      final double confidence = _getDetectionConfidence(detection);
      if (!grouped.containsKey(className)) {
        grouped[className] = { 'className': className,'confidence': confidence,'count': 1, };
      } else {
        grouped[className]!['count'] =
            (grouped[className]!['count'] as int) + 1;
        final double oldConfidence =
            grouped[className]!['confidence'] as double;
        if (confidence > oldConfidence) { grouped[className]!['confidence'] = confidence; }
      }
    }
    return grouped.values.toList();
  }
  @override
  Widget build(BuildContext context) {
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';
    final String ticketNumber =
        ticket['ticketNumber']?.toString() ?? '#--------';
    final String status = ticket['status']?.toString() ?? 'Open';
    final String priority = ticket['priority']?.toString() ?? 'Pending';
    final String originalUrl = _cleanUrl(ticket['originalUrl']);
    final String processedUrl = _cleanUrl(ticket['processedUrl']);
    final bool isVideo = _isVideo();
    final String displayMediaUrl = isVideo
        ? (processedUrl.isNotEmpty ? processedUrl : originalUrl)
        : originalUrl;
    final List<dynamic> detections = _getDetections();
    final List<Map<String, dynamic>> groupedDetections =
        _groupDetections(detections);
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/bg3.png',fit: BoxFit.cover,),),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _navy.withOpacity(0.78),
                    _navy.withOpacity(0.72),
                    _navy.withOpacity(0.96),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                            border: Border.all(color: Colors.white.withOpacity(0.12),),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 17,
                            ),
                            onPressed: () { Navigator.pop(context); },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isArabic ? 'تفاصيل البلاغ' : 'Report Details',
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Transform.scale(scale: 0.85,child: const LanguageSwitcher(),),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16,8,16,40,),
                    children: [
                      _buildTicketHeader(ticketNumber,status,priority,isArabic,),
                      const SizedBox(height: 14),
                      _buildAIAnalysisContainer(
                        context,
                        detections,
                        groupedDetections,
                        displayMediaUrl,
                        isVideo,
                        isArabic,
                      ),
                      const SizedBox(height: 14),
                      if (_cleanUrl(ticket['fixedUrl']).isNotEmpty) ...[
                        _buildFixedMediaCard(isArabic),
                        const SizedBox(height: 14),
                      ],
                      _buildLocationCard(
                        ticket['latitude'],
                        ticket['longitude'],
                        ticket['address'],
                        isArabic,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTicketHeader(String ticketNumber,String status,String priority,bool isArabic,) {
    final Color statusColor = _getStatusColor(status);
    final Color priorityColor = _getPriorityColor(priority);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12,sigmaY: 12,),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glassBorder,),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withOpacity(0.10),
                      border: Border.all(color: _accent.withOpacity(0.25),),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: _accent,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticketNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isArabic ? 'معلومات البلاغ' : 'Report Information',
                          style: TextStyle(color: Colors.white.withOpacity(0.45),fontSize: 10,),
                        ),
                      ],
                    ),
                  ),
                  _buildSmallBadge(_getStatusText(status,isArabic,),statusColor,),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBar(
                      icon: Icons.flag_outlined,
                      title: isArabic ? 'الأولوية' : 'Priority',
                      value: _getPriorityText(priority,isArabic,),
                      color: priorityColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoBar(
                      icon: Icons.access_time,
                      title: isArabic ? 'التاريخ' : 'Date',
                      value: _formatDate(ticket['createdAt'],),
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAIAnalysisContainer(
    BuildContext context,
    List<dynamic> detections,
    List<Map<String, dynamic>> groupedDetections,
    String mediaUrl,
    bool isVideo,
    bool isArabic,
  ) {
    final double overallConfidence = _getOverallConfidence();
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14,sigmaY: 14,),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _accent.withOpacity(0.22),width: 1,),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withOpacity(0.10),
                      border: Border.all(color: _accent.withOpacity(0.25),),
                    ),
                    child: const Icon(Icons.auto_awesome,color: _accent,size: 20,),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'نتائج تحليل الذكاء الاصطناعي'
                          : 'AI Analysis Results',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(
                icon: isVideo ? Icons.video_library_outlined : Icons.auto_awesome,
                title: isVideo
                    ? (isArabic ? 'الفيديو المعالج' : 'Processed Video')
                    : (isArabic ? 'الصورة المعالجة' : 'Processed Image'),
              ),
              const SizedBox(height: 10),
              _buildProcessedImage(mediaUrl,isVideo,detections,),
              const SizedBox(height: 22),
              _buildSectionTitle(
                icon: Icons.warning_amber_rounded,
                title: isArabic ? 'المشكلات المكتشفة' : 'Detected Issues',
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildConfidenceCircle(overallConfidence,isArabic,),
                  const SizedBox(width: 18),
                  Expanded(
                    child: groupedDetections.isEmpty
                        ? Text(
                            isArabic
                                ? 'لم يتم اكتشاف مشكلات'
                                : 'No issues detected',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12,
                            ),
                          )
                        : Column(
                            children: groupedDetections.map(
                              (item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12,),
                                  child: _buildDetectionItem(item,detections,isArabic,),
                                );
                              },
                            ).toList(),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.10),height: 28,),
              _buildSectionTitle(
                icon: Icons.auto_awesome,
                title: isArabic
                    ? 'الوصف المُنشأ بواسطة الذكاء الاصطناعي'
                    : 'AI Generated Description',
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _accent.withOpacity(0.10),),
                ),
                child: Text(
                  _getAiDescription(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildLocationCard(dynamic lat,dynamic lng,dynamic address,bool isArabic,) {
    String displayAddress = '';
    if (address != null && address.toString().contains(' - ')) {
      final parts = address.toString().split(' - ');
      displayAddress = isArabic ? parts[0].trim() : parts[1].trim();
    } else {
      displayAddress = address?.toString() ??
          (isArabic ? 'العنوان غير متوفر' : 'Address not available');
    }
    String latStr = '-';
    String lngStr = '-';
    if (lat != null) {
      final double? parsedLat = double.tryParse(lat.toString());
      latStr = parsedLat != null ? parsedLat.toStringAsFixed(5) : lat.toString();
    }
    if (lng != null) {
      final double? parsedLng = double.tryParse(lng.toString());
      lngStr = parsedLng != null ? parsedLng.toStringAsFixed(5) : lng.toString();
    }
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.location_on_outlined,
            title: isArabic ? 'موقع البلاغ' : 'Report Location',
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                border: Border.all(color: Colors.white.withOpacity(0.08),),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.15,
                    child: CustomPaint(
                      size: const Size(double.infinity, double.infinity),
                      painter: _GridPainter(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,color: Colors.redAccent,size: 45,),
                      Container(
                        width: 12,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.5),blurRadius: 4,),
                          ],
                        ),
                      )
                    ],
                  ),
                  Positioned(
                    bottom: 12,
                    right: isArabic ? null : 12,
                    left: isArabic ? 12 : null,
                    child: GestureDetector(
                      onTap: () async {
                        if (lat != null && lng != null) {
                          final Uri url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                          try {
                            await launchUrl(url,mode: LaunchMode.externalApplication,);
                          } catch (e) { debugPrint('Error launching Map: $e'); }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 6,),
                        decoration: BoxDecoration(
                          color: _navy.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _accent.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.map_outlined, color: _accent, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              isArabic ? 'فتح الخريطة' : 'Open Map',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.my_location_rounded,color: Colors.white.withOpacity(0.40),size: 16,),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayAddress,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                _buildCoordinateChip('Lat', latStr),
                const SizedBox(width: 10),
                _buildCoordinateChip('Lng', lngStr),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCoordinateChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildProcessedImage(String mediaUrl,bool isVideo,List<dynamic> detections,) {
    if (mediaUrl.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,color: Colors.white38,size: 40,),
        ),
      );
    }
    if (isVideo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoThumbnail(videoUrl: mediaUrl,),
              Container(color: Colors.black.withOpacity(0.15),),
              const Center(
                child: Icon(Icons.play_circle_fill_rounded,color: Colors.white,size: 54,),
              ),
            ],
          ),
        ),
      );
    }
    return BoundingBoxImage(
      imageUrl: mediaUrl,
      detections: detections,
      getDetectionColor: _getDetectionColor,
    );
  }
  Widget _buildConfidenceCircle(double confidence,bool isArabic,) {
    return SizedBox(
      width: 125,
      height: 125,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: confidence / 100,
              strokeWidth: 9,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(_accent,),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${ confidence.round() }%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isArabic ? 'الثقة الكلية' : 'Overall\nConfidence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.48),
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildDetectionItem(
    Map<String, dynamic> item,
    List<dynamic> detections,
    bool isArabic,
  ) {
    final String className =
        item['className']?.toString() ?? 'Unknown';
    final double confidence =
        (item['confidence'] as num?)?.toDouble() ?? 0;
    final int count = item['count'] as int? ?? 0;
    final Color color = _getDetectionColor(className);
    final String displayName = _getDisplayClassName(className,isArabic,);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.20),),
              ),
              child: Icon(Icons.warning_amber_rounded,color: color,size: 17,),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${ isArabic ? 'اكتشاف' : 'detections' }',
                    style: TextStyle(color: Colors.white.withOpacity(0.40),fontSize: 9,),
                  ),
                ],
              ),
            ),
            Text(
              '${ confidence.round() }%',
              style: TextStyle(color: color,fontSize: 12,fontWeight: FontWeight.bold,),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 42,),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: confidence / 100,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color,),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSectionTitle({ required IconData icon,required String title, }) {
    return Row(
      children: [
        Icon(icon,color: _accent,size: 20,),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white,fontSize: 17,fontWeight: FontWeight.bold,),
        ),
      ],
    );
  }
  Widget _buildSmallBadge(String text,Color color,) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 5,),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25),),
      ),
      child: Text(
        text,
        style: TextStyle(color: color,fontSize: 9,fontWeight: FontWeight.bold,),
      ),
    );
  }
  Widget _buildInfoBar({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    final Color itemColor = color ?? _accent;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07),),
      ),
      child: Row(
        children: [
          Icon(icon,color: itemColor,size: 15,),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white.withOpacity(0.38),fontSize: 8,),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: itemColor,fontSize: 9.5,fontWeight: FontWeight.bold,),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildGlassContainer({ required Widget child, }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12,sigmaY: 12,),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glassBorder,),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
  String _getStatusText(String status,bool isArabic,) {
    switch (status.toLowerCase()) {
      case 'closed':
      case 'resolved':
        return isArabic ? 'تم الحل' : 'Resolved';
      case 'rejected':
        return isArabic ? 'مرفوض' : 'Rejected';
      case 'in progress':
      case 'in-progress':
        return isArabic ? 'قيد التنفيذ' : 'In Progress';
      case 'open':
      default:
        return isArabic ? 'مفتوح' : 'Open';
    }
  }
  String _getPriorityText(String priority,bool isArabic,) {
    switch (priority.toLowerCase()) {
      case 'high':
        return isArabic ? 'عالية' : 'High';
      case 'medium':
        return isArabic ? 'متوسطة' : 'Medium';
      case 'low':
        return isArabic ? 'منخفضة' : 'Low';
      case 'pending':
        return isArabic ? 'معلّق' : 'Pending';
      default:
        return priority;
    }
  }
  Color _getDetectionColor(String className,) {
    switch (className.toLowerCase()) {
      case 'garbage':
      case 'trash':
        return Colors.orangeAccent;
      case 'graffiti':
        return Colors.redAccent;
      case 'potholes':
        return Colors.amberAccent;
      case 'bad_streetlight':
        return Colors.yellowAccent;
      case 'bad_billboard':
        return Colors.purpleAccent;
      case 'faded_signage':
        return Colors.cyanAccent;
      case 'broken_signage':
        return Colors.redAccent;
      case 'construction_road':
        return Colors.deepOrangeAccent;
      case 'sand_on_road':
        return Colors.brown.shade200;
      case 'clutter_sidewalk':
        return Colors.pinkAccent;
      case 'unkept_facade':
        return Colors.blueAccent;
      default:
        return _accent;
    }
  }
  bool _isFixedVideo() {
    final String url = ticket['fixedUrl']?.toString().toLowerCase() ?? '';
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi');
  }
  Widget _buildFixedMediaCard(bool isArabic) {
    final String fixedUrl = _cleanUrl(ticket['fixedUrl']);
    if (fixedUrl.isEmpty) { return const SizedBox.shrink(); }
    final bool isVideo = _isFixedVideo();
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionTitle(
                  icon: Icons.build_circle_outlined,
                  title: isArabic ? 'بعد الإصلاح' : 'After Fix',
                ),
              ),
              _buildSmallBadge(isArabic ? 'تم الإصلاح' : 'Fixed',Colors.greenAccent,),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: isVideo
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        _VideoThumbnail(videoUrl: fixedUrl),
                        Container(color: Colors.black.withOpacity(0.15),),
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                      ],
                    )
                  : Image.network(
                      fixedUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.white.withOpacity(0.05),
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xff19C6FF),),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withOpacity(0.05),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white38,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
  String _getDisplayClassName(String className,bool isArabic,) {
    if (!isArabic) { return className.replaceAll('_', ' '); }
    switch (className.toUpperCase()) {
      case 'GARBAGE':
        return 'مخلفات';
      case 'GRAFFITI':
        return 'كتابات على الجدران';
      case 'POTHOLES':
        return 'حفر الطرق';
      case 'FADED_SIGNAGE':
        return 'لافتات باهتة';
      case 'BROKEN_SIGNAGE':
        return 'لافتات مكسورة';
      case 'BAD_STREETLIGHT':
        return 'إضاءة شارع سيئة';
      case 'BAD_BILLBOARD':
        return 'لوحات إعلانية سيئة';
      case 'CONSTRUCTION_ROAD':
        return 'أعمال طرق';
      case 'SAND_ON_ROAD':
        return 'رمال على الطريق';
      case 'CLUTTER_SIDEWALK':
        return 'فوضى على الرصيف';
      case 'UNKEPT_FACADE':
        return 'واجهة غير مُعتنى بها';
      default:
        return className.replaceAll('_', ' ');
    }
  }
}
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const double spacing = 20.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class BoundingBoxImage extends StatefulWidget {
  final String imageUrl;
  final List<dynamic> detections;
  final Color Function(String) getDetectionColor;
  const BoundingBoxImage({
    super.key,
    required this.imageUrl,
    required this.detections,
    required this.getDetectionColor,
  });
  @override
  State<BoundingBoxImage> createState() => _BoundingBoxImageState();
}
class _BoundingBoxImageState extends State<BoundingBoxImage> {
  dynamic _rawImage;
  bool _hasError = false;
  @override
  void initState() { super.initState(); _loadImage(); }
  void _loadImage() {
    final ImageStream stream =
        NetworkImage(widget.imageUrl).resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) { if (mounted) { setState(() { _rawImage = info.image; }); } },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (mounted) { setState(() { _hasError = true; }); }
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.broken_image_outlined,color: Colors.white38,size: 40,),
        ),
      );
    }
    if (_rawImage == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xff19C6FF),),),
      );
    }
    final double imgWidth = _rawImage!.width.toDouble();
    final double scale = (imgWidth / 550.0).clamp(0.8, 6.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _rawImage!.width.toDouble(),
            height: _rawImage!.height.toDouble(),
            child: Stack(
              children: [
                RawImage(image: _rawImage),
                ...widget.detections.map((d) {
                  if (d['x'] == null ||
                      d['y'] == null ||
                      d['width'] == null ||
                      d['height'] == null) {
                    return const SizedBox.shrink();
                  }
                  final String className =
                      d['className']?.toString() ?? 'Unknown';
                  final Color color = widget.getDetectionColor(className);
                  double rawConf = (d['confidence'] as num?)?.toDouble() ?? 0;
                  if (rawConf <= 1 && rawConf > 0) { rawConf *= 100; }
                  final String confidenceText = '${ rawConf.round() }%';
                  return Positioned(
                    left: (d['x'] as num).toDouble(),
                    top: (d['y'] as num).toDouble(),
                    width: (d['width'] as num).toDouble(),
                    height: (d['height'] as num).toDouble(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: color,width: 3.0 * scale,),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            color: color,
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.0 * scale,
                              vertical: 3.0 * scale,
                            ),
                            child: Text(
                              '$className $confidenceText',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0 * scale,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}