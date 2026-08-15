import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:naga_app/l10n/app_localizations.dart';

import '../../widgets/shared/language_switcher.dart';
import '../../widgets/onboarding/background_image.dart';
import '../../services/ticket_service.dart';

// =========================================================
// STATISTICS SCREEN
// =========================================================

class StatisticsScreen extends StatefulWidget {
  final List<dynamic> tickets;
  final bool isArabic;

  const StatisticsScreen({
    super.key,
    this.tickets = const [],
    required this.isArabic,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // =========================================================
  // COLORS — same palette as Home / My Reports
  // =========================================================

  static const Color _navy = Color(0xFF04102A);
  static const Color _accent = Color(0xff19C6FF);
  static const Color _accent2 = Color(0xff29B6F6);
  static const Color _glassBg = Color(0x1AFFFFFF);
  static const Color _glassBorder = Color(0x26FFFFFF);

  static const Color _resolvedColor = Colors.greenAccent;
  static const Color _progressColor = Colors.orangeAccent;
  static const Color _openColor = Colors.redAccent;

  String _range = 'month'; // week | month | all

  List<dynamic> _allTickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Start with whatever was passed in (if anything) so the screen
    // isn't empty for a frame, then fetch the real data ourselves —
    // this screen must not depend on a list the parent may never fill.
    _allTickets = widget.tickets;
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final List<dynamic> fetched = await TicketService.getMyTickets();

      if (mounted) {
        setState(() {
          _allTickets = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('STATISTICS LOAD ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  // =========================================================
  // DATE HELPERS
  // =========================================================

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _inRange(DateTime? date) {
    if (date == null) return true;
    final DateTime now = DateTime.now();

    switch (_range) {
      case 'week':
        return now.difference(date).inDays <= 7 &&
            date.isBefore(now.add(const Duration(days: 1)));
      case 'month':
        return date.year == now.year && date.month == now.month;
      default:
        return true;
    }
  }

  List<dynamic> get _filteredTickets => _allTickets
      .where((t) => _inRange(_parseDate(t['createdAt'])))
      .toList();

  List<dynamic> get _previousTickets {
    final DateTime now = DateTime.now();
    final DateTime prevMonth = DateTime(now.year, now.month - 1);

    return _allTickets.where((t) {
      final DateTime? d = _parseDate(t['createdAt']);
      if (d == null) return false;

      if (_range == 'week') {
        final DateTime start = now.subtract(const Duration(days: 14));
        final DateTime end = now.subtract(const Duration(days: 7));
        return d.isAfter(start) && d.isBefore(end);
      }

      return d.year == prevMonth.year && d.month == prevMonth.month;
    }).toList();
  }

  String _status(dynamic t) =>
      (t['status']?.toString() ?? '').toLowerCase();

  bool _isResolved(dynamic t) =>
      ['closed', 'resolved'].contains(_status(t));
  bool _isInProgress(dynamic t) =>
      ['in progress', 'in-progress'].contains(_status(t));
  bool _isOpen(dynamic t) => _status(t) == 'open';

  double _pctChange(int current, int previous) {
    if (previous == 0) return current == 0 ? 0 : 100;
    return ((current - previous) / previous) * 100;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final bool isArabic = widget.isArabic;

    final List<dynamic> tickets = _filteredTickets;
    final List<dynamic> prevTickets = _previousTickets;

    final int total = tickets.length;
    final int resolved = tickets.where(_isResolved).length;
    final int inProgress = tickets.where(_isInProgress).length;
    final int open = tickets.where(_isOpen).length;

    final int prevTotal = prevTickets.length;
    final int prevResolved = prevTickets.where(_isResolved).length;
    final int prevInProgress = prevTickets.where(_isInProgress).length;
    final int prevOpen = prevTickets.where(_isOpen).length;

    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          const BackgroundImage(
            imagePath: 'assets/images/bg3.png',
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _navy.withOpacity(0.8),
                  _navy.withOpacity(0.6),
                  _navy.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading && _allTickets.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _accent,
                          ),
                        )
                      : _error != null && _allTickets.isEmpty
                          ? _buildErrorState(isArabic)
                          : RefreshIndicator(
                              color: _accent,
                              backgroundColor: _navy,
                              onRefresh: _loadTickets,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  bottom: 100,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _buildHeader(isArabic),
                                    const SizedBox(height: 18),
                                    _buildStatCards(
                                      isArabic,
                                      total,
                                      resolved,
                                      inProgress,
                                      open,
                                      prevTotal,
                                      prevResolved,
                                      prevInProgress,
                                      prevOpen,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTicketsOverTime(isArabic),
                                    const SizedBox(height: 20),
                                    _buildTicketsByStatus(
                                      isArabic,
                                      resolved,
                                      inProgress,
                                      open,
                                      total,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildPollutionTypes(isArabic, tickets),
                                    const SizedBox(height: 20),
                                    _buildTopLocations(isArabic, tickets),
                                    const SizedBox(height: 20),
                                    _buildResolutionRate(
                                      isArabic,
                                      resolved,
                                      total,
                                      prevResolved,
                                      prevTotal,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState(bool isArabic) {
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
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.25),
                ),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Colors.redAccent,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isArabic
                  ? 'حدث خطأ أثناء تحميل الإحصائيات'
                  : 'Failed to load statistics',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isArabic ? 'إعادة المحاولة' : 'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TOP BAR — identical to Home screen
  // =========================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/kasct.png',
              height: 35,
            ),
            Transform.scale(
              scale: 0.85,
              child: const LanguageSwitcher(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER — title + range dropdown
  // =========================================================

  Widget _buildHeader(bool isArabic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.12),
                border: Border.all(
                  color: _accent.withOpacity(0.28),
                ),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: _accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isArabic ? 'الإحصائيات' : 'Statistics',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        _buildRangeDropdown(isArabic),
      ],
    );
  }

  Widget _buildRangeDropdown(bool isArabic) {
    final Map<String, String> labels = {
      'week': isArabic ? 'هذا الأسبوع' : 'This Week',
      'month': isArabic ? 'هذا الشهر' : 'This Month',
      'all': isArabic ? 'كل الوقت' : 'All Time',
    };

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _range,
          dropdownColor: const Color(0xFF10213D),
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withOpacity(0.6),
            size: 18,
          ),
          items: labels.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: _accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return labels.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: _accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          onChanged: (v) {
            if (v == null) return;
            setState(() => _range = v);
          },
        ),
      ),
    );
  }

  // =========================================================
  // STAT CARDS (Total / Resolved / In Progress / Open)
  // =========================================================

  Widget _buildStatCards(
    bool isArabic,
    int total,
    int resolved,
    int inProgress,
    int open,
    int prevTotal,
    int prevResolved,
    int prevInProgress,
    int prevOpen,
  ) {
    final List<_StatCardData> items = [
      _StatCardData(
        icon: Icons.description_outlined,
        iconColor: _accent,
        title: isArabic ? 'إجمالي البلاغات' : 'Total Tickets',
        value: total,
        change: _pctChange(total, prevTotal),
      ),
      _StatCardData(
        icon: Icons.check_circle_outline,
        iconColor: _resolvedColor,
        title: isArabic ? 'البلاغات المحلولة' : 'Resolved Tickets',
        value: resolved,
        change: _pctChange(resolved, prevResolved),
      ),
      _StatCardData(
        icon: Icons.access_time,
        iconColor: _progressColor,
        title: isArabic ? 'قيد التنفيذ' : 'In Progress',
        value: inProgress,
        change: _pctChange(inProgress, prevInProgress),
      ),
      _StatCardData(
        icon: Icons.cancel_outlined,
        iconColor: _openColor,
        title: isArabic ? 'البلاغات المفتوحة' : 'Open Tickets',
        value: open,
        change: _pctChange(open, prevOpen),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) =>
          _buildStatCard(items[index], isArabic),
    );
  }

  Widget _buildStatCard(_StatCardData data, bool isArabic) {
    final bool isPositive = data.change >= 0;
    final Color changeColor =
        isPositive ? Colors.greenAccent : Colors.redAccent;

    return _buildGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.iconColor.withOpacity(0.12),
              border: Border.all(
                color: data.iconColor.withOpacity(0.3),
              ),
            ),
            child: Icon(
              data.icon,
              color: data.iconColor,
              size: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${data.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: changeColor,
                size: 12,
              ),
              Text(
                '${data.change.abs().toStringAsFixed(0)}%',
                style: TextStyle(
                  color: changeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isArabic ? 'مقارنة بالشهر الماضي' : 'vs last month',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TICKETS OVER TIME (line chart, current calendar month)
  // =========================================================

  Map<int, int> _dailyCounts() {
    final DateTime now = DateTime.now();
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final Map<int, int> counts = {
      for (int d = 1; d <= daysInMonth; d++) d: 0,
    };

    for (final t in _allTickets) {
      final DateTime? date = _parseDate(t['createdAt']);
      if (date != null &&
          date.year == now.year &&
          date.month == now.month) {
        counts[date.day] = (counts[date.day] ?? 0) + 1;
      }
    }

    return counts;
  }

  Widget _buildTicketsOverTime(bool isArabic) {
    final DateTime now = DateTime.now();
    final Map<int, int> counts = _dailyCounts();
    final List<int> days = counts.keys.toList()..sort();
    final List<double> values =
        days.map((d) => counts[d]!.toDouble()).toList();

    final double maxVal =
        values.isEmpty ? 0.0 : values.reduce(math.max);
    final double niceMax =
        maxVal <= 0 ? 10.0 : (((maxVal / 10).ceil()) * 10).toDouble();

    int peakIndex = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[peakIndex]) peakIndex = i;
    }

    final bool hasData = values.any((v) => v > 0);

    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                color: _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic
                      ? 'البلاغات عبر الزمن'
                      : 'Tickets Over Time',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Text(
                  isArabic ? 'يوميًا' : 'Daily',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasData)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  isArabic
                      ? 'لا توجد بيانات كافية'
                      : 'Not enough data yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildYAxisLabels(niceMax),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        values: values,
                        maxY: niceMax,
                        lineColor: _accent,
                        peakIndex: peakIndex,
                      ),
                      child: Container(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: _buildXAxisLabels(days, isArabic),
            ),
            if (values[peakIndex] > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isArabic
                        ? 'الذروة: ${days[peakIndex]} ${_monthShort(now.month, true)} • ${values[peakIndex].toInt()} بلاغ'
                        : 'Peak: ${days[peakIndex]} ${_monthShort(now.month, false)} • ${values[peakIndex].toInt()} tickets',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildYAxisLabels(double maxY) {
    const int steps = 4;

    return SizedBox(
      width: 26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(steps + 1, (i) {
          final double value = (maxY / steps) * (steps - i);
          return Text(
            value.toInt().toString(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 9,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildXAxisLabels(List<int> days, bool isArabic) {
    if (days.isEmpty) return const SizedBox.shrink();

    final DateTime now = DateTime.now();
    const int labelCount = 6;
    final int step =
        (days.length / labelCount).ceil().clamp(1, days.length);

    final List<int> picks = [];
    for (int i = 0; i < days.length; i += step) {
      picks.add(days[i]);
    }
    if (picks.last != days.last) picks.add(days.last);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: picks.map((d) {
        return Text(
          '$d ${_monthShort(now.month, isArabic)}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 9,
          ),
        );
      }).toList(),
    );
  }

  String _monthShort(int month, bool isArabic) {
    const List<String> en = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const List<String> ar = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return isArabic ? ar[month - 1] : en[month - 1];
  }

  // =========================================================
  // TICKETS BY STATUS (donut chart)
  // =========================================================

  Widget _buildTicketsByStatus(
    bool isArabic,
    int resolved,
    int inProgress,
    int open,
    int total,
  ) {
    final List<double> segments = [
      resolved.toDouble(),
      inProgress.toDouble(),
      open.toDouble(),
    ];
    const List<Color> colors = [
      _resolvedColor,
      _progressColor,
      _openColor,
    ];

    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.donut_large_rounded,
                color: _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'البلاغات حسب الحالة' : 'Tickets by Status',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _DonutPainter(
                      values: segments,
                      colors: colors,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isArabic ? 'الإجمالي' : 'Total',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildStatusLegendItem(
            isArabic ? 'محلولة' : 'Resolved',
            resolved,
            total,
            _resolvedColor,
          ),
          const SizedBox(height: 10),
          _buildStatusLegendItem(
            isArabic ? 'قيد التنفيذ' : 'In Progress',
            inProgress,
            total,
            _progressColor,
          ),
          const SizedBox(height: 10),
          _buildStatusLegendItem(
            isArabic ? 'مفتوحة' : 'Open',
            open,
            total,
            _openColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegendItem(
    String label,
    int value,
    int total,
    Color color,
  ) {
    final int pct = total == 0 ? 0 : (value / total * 100).round();

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12.5,
            ),
          ),
        ),
        Text(
          '$value ($pct%)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TICKETS BY POLLUTION TYPE
  // =========================================================

  static const Map<String, IconData> _pollutionIcons = {
    'GARBAGE': Icons.delete_outline,
    'GRAFFITI': Icons.format_paint_outlined,
    'POTHOLES': Icons.warning_amber_rounded,
    'FADED_SIGNAGE': Icons.signpost_outlined,
    'BROKEN_SIGNAGE': Icons.signpost_outlined,
    'BAD_STREETLIGHT': Icons.lightbulb_outline,
    'BAD_BILLBOARD': Icons.image_outlined,
    'CONSTRUCTION_ROAD': Icons.construction_outlined,
    'SAND_ON_ROAD': Icons.terrain_outlined,
    'CLUTTER_SIDEWALK': Icons.dashboard_outlined,
    'UNKEPT_FACADE': Icons.house_outlined,
  };

  Color _pollutionColor(String key) {
    switch (key.toUpperCase()) {
      case 'GARBAGE':
        return Colors.redAccent;
      case 'GRAFFITI':
        return Colors.pinkAccent;
      case 'POTHOLES':
        return Colors.amberAccent;
      case 'FADED_SIGNAGE':
        return Colors.cyanAccent;
      case 'BROKEN_SIGNAGE':
        return Colors.redAccent;
      case 'BAD_STREETLIGHT':
        return Colors.yellowAccent;
      case 'BAD_BILLBOARD':
        return Colors.purpleAccent;
      case 'CONSTRUCTION_ROAD':
        return Colors.deepOrangeAccent;
      case 'SAND_ON_ROAD':
        return Colors.brown.shade200;
      case 'CLUTTER_SIDEWALK':
        return Colors.pinkAccent;
      case 'UNKEPT_FACADE':
        return Colors.blueAccent;
      default:
        return _accent;
    }
  }

  String _pollutionLabel(String key, bool isArabic) {
    if (!isArabic) {
      return key
          .replaceAll('_', ' ')
          .toLowerCase()
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }

    switch (key.toUpperCase()) {
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
        return 'واجهة غير معتنى بها';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  Widget _buildPollutionTypes(bool isArabic, List<dynamic> tickets) {
    final Map<String, int> counts = {};

    for (final t in tickets) {
      final dynamic types = t['pollutionTypes'];
      if (types is List) {
        for (final ty in types) {
          final String key = ty.toString().toUpperCase();
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }

    final int total = counts.values.fold<int>(0, (a, b) => a + b);
    final List<MapEntry<String, int>> entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<MapEntry<String, int>> top = entries.take(5).toList();

    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart_outline_rounded,
                color: _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic
                      ? 'البلاغات حسب نوع التلوث'
                      : 'Tickets by Pollution Type',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                isArabic ? 'لا توجد بيانات' : 'No data yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            )
          else
            Column(
              children: top.map((e) {
                final double pct = total == 0 ? 0 : (e.value / total * 100);
                final Color color = _pollutionColor(e.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          _pollutionIcons[e.key] ??
                              Icons.warning_amber_rounded,
                          color: color,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _pollutionLabel(e.key, isArabic),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${e.value}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${pct.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 5,
                                backgroundColor:
                                    Colors.white.withOpacity(0.08),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // TOP LOCATIONS
  // =========================================================

  String _extractLocationLabel(dynamic address, bool isArabic) {
    if (address == null) return isArabic ? 'غير معروف' : 'Unknown';

    final String full = address.toString();
    final List<String> parts = full.split(' - ');

    final String chosen = isArabic
        ? (parts.isNotEmpty ? parts.first : full)
        : (parts.length > 1 ? parts[1] : full);

    final List<String> segments = chosen
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final List<String> filtered = segments
        .where((s) => double.tryParse(s.replaceAll(' ', '')) == null)
        .toList();

    if (filtered.length >= 3) {
      return '${filtered[filtered.length - 3]}, ${filtered[filtered.length - 2]}';
    } else if (filtered.length == 2) {
      return '${filtered[0]}, ${filtered[1]}';
    } else if (filtered.isNotEmpty) {
      return filtered.first;
    }

    return chosen;
  }

  Widget _buildTopLocations(bool isArabic, List<dynamic> tickets) {
    final Map<String, int> counts = {};

    for (final t in tickets) {
      final String label = _extractLocationLabel(t['address'], isArabic);
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final List<MapEntry<String, int>> entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final List<MapEntry<String, int>> top = entries.take(5).toList();
    final int maxVal = top.isEmpty ? 1 : top.first.value;

    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'أكثر المواقع تكرارًا' : 'Top Locations',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                isArabic ? 'لا توجد بيانات' : 'No data yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            )
          else
            Column(
              children: top.map((e) {
                final double ratio = maxVal == 0 ? 0.0 : e.value / maxVal;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${e.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // RESOLUTION RATE
  // =========================================================

  Widget _buildResolutionRate(
    bool isArabic,
    int resolved,
    int total,
    int prevResolved,
    int prevTotal,
  ) {
    final double rate = total == 0 ? 0 : (resolved / total * 100);
    final double prevRate =
        prevTotal == 0 ? 0 : (prevResolved / prevTotal * 100);
    final double change = rate - prevRate;
    final bool isPositive = change >= 0;

    return _buildGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.speed_rounded,
                color: _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'معدل الحل' : 'Resolution Rate',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: rate / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _accent,
                        ),
                      ),
                    ),
                    Text(
                      '${rate.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResolutionStatRow(
                      isArabic ? 'محلولة' : 'Resolved',
                      '$resolved',
                      _resolvedColor,
                    ),
                    const SizedBox(height: 10),
                    _buildResolutionStatRow(
                      isArabic ? 'الإجمالي' : 'Total',
                      '$total',
                      _accent,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isPositive
                                ? Colors.greenAccent
                                : Colors.redAccent)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isPositive
                                  ? Colors.greenAccent
                                  : Colors.redAccent)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: isPositive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: 12,
                          ),
                          Flexible(
                            child: Text(
                              '${change.abs().toStringAsFixed(0)}%  ${isArabic ? 'مقارنة بالشهر الماضي' : 'vs last month'}',
                              style: TextStyle(
                                color: isPositive
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionStatRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // GLASS CARD (same visual language as Home)
  // =========================================================

  Widget _buildGlassCard({
    required Widget child,
    required EdgeInsets padding,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor ?? _glassBorder,
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =========================================================
// STAT CARD DATA MODEL
// =========================================================

class _StatCardData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int value;
  final double change;

  _StatCardData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.change,
  });
}

// =========================================================
// LINE CHART PAINTER (Tickets Over Time)
// =========================================================

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxY;
  final Color lineColor;
  final int peakIndex;

  _LineChartPainter({
    required this.values,
    required this.maxY,
    required this.lineColor,
    required this.peakIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double stepX =
        values.length > 1 ? size.width / (values.length - 1) : 0;

    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = stepX * i;
      final double ratio =
          maxY == 0 ? 0 : (values[i] / maxY).clamp(0, 1);
      final double y = size.height - (ratio * size.height);
      points.add(Offset(x, y));
    }

    // Area fill under the line
    final Path fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.35),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Line itself
    final Path linePath = Path()
      ..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Dots
    final Paint dotPaint = Paint()..color = lineColor;
    final Paint dotBorderPaint = Paint()
      ..color = const Color(0xFF04102A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < points.length; i++) {
      final double r = i == peakIndex ? 5.0 : 2.5;
      canvas.drawCircle(points[i], r, dotPaint);
      if (i == peakIndex) {
        canvas.drawCircle(points[i], r, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.maxY != maxY;
  }
}

// =========================================================
// DONUT CHART PAINTER (Tickets by Status)
// =========================================================

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;

  _DonutPainter({
    required this.values,
    required this.colors,
    this.strokeWidth = 26,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold<double>(0, (a, b) => a + b);
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    if (total <= 0) {
      final Paint emptyPaint = Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 2 * math.pi, false, emptyPaint);
      return;
    }

    double startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final double sweep = (values[i] / total) * 2 * math.pi;
      if (sweep <= 0) continue;

      final Paint paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}