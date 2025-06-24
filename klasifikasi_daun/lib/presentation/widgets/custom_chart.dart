// lib/presentation/widgets/custom_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Pastikan ini diimpor untuk DateFormat

// Model class untuk data daun
class LeafData {
  final String day;
  final double sehat;
  final double kuning;
  final double keriting;

  const LeafData({
    required this.day,
    required this.sehat,
    required this.kuning,
    required this.keriting,
  });
}

class ModernLeafAnalysisChart extends StatefulWidget {
  final String title;
  final String period;
  final List<LeafData> data;
  final bool showAnimation;
  final double? maxY;
  final int maxVisibleBars;
  final VoidCallback? onPeriodTap; // Callback untuk tap periode

  const ModernLeafAnalysisChart({
    super.key,
    this.title = 'Analisis Kesehatan Daun',
    this.period = 'Mingguan',
    this.data = const [],
    this.showAnimation = true,
    this.maxY,
    this.maxVisibleBars = 7,
    this.onPeriodTap, // Inisialisasi callback
  });

  @override
  State<ModernLeafAnalysisChart> createState() =>
      _ModernLeafAnalysisChartState();
}

class _ModernLeafAnalysisChartState extends State<ModernLeafAnalysisChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late ScrollController _scrollController;
  int touchedIndex = -1;
  int currentPage = 0;
  int totalPages = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOutCubic),
    );

    _updateTotalPages(); // Calculate total pages initially

    if (widget.showAnimation) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _animationController.forward();
      });
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ModernLeafAnalysisChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.length != widget.data.length ||
        oldWidget.maxVisibleBars != widget.maxVisibleBars) {
      _updateTotalPages();
      _animationController.reset();
      _animationController.forward();
      if (currentPage >= totalPages) {
        currentPage = totalPages > 0 ? totalPages - 1 : 0;
      }
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(currentPage * (45.0 * widget.maxVisibleBars));
      }
    }
  }

  void _updateTotalPages() {
    final dataLength = widget.data.length;
    totalPages = (dataLength / widget.maxVisibleBars).ceil();
    if (totalPages == 0 && dataLength > 0) totalPages = 1;
    if (dataLength == 0) totalPages = 0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38B48B).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(), // Header sekarang akan menampilkan periode yang bisa di-tap
          const SizedBox(height: 20),
          _buildLegend(),
          const SizedBox(height: 20),
          if (_shouldShowPagination()) _buildPaginationControls(),
          const SizedBox(height: 16),
          _buildChart(),
          const SizedBox(height: 16),
          _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris kedua: Judul chart
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 2),
        // Baris ketiga: Deskripsi data
        Text(
          'Data analisis kesehatan daun${_shouldShowPagination() ? ' (${_getCurrentDataRange()})' : ''}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: widget.onPeriodTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF38B48B).withOpacity(0.2),
                      const Color(0xFF38B48B).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF38B48B).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF38B48B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.period,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF38B48B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLegendItem(
          const Color(0xFF10B981), // Emerald
          'Sehat',
          Icons.eco_outlined,
        ),
        _buildLegendItem(
          const Color(0xFFF59E0B), // Amber
          'Kuning',
          Icons.warning_amber_outlined,
        ),
        _buildLegendItem(
          const Color(0xFFEF4444), // Red
          'Keriting',
          Icons.bug_report_outlined,
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF38B48B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38B48B).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: currentPage > 0 ? _previousPage : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: currentPage > 0
                    ? const Color(0xFF38B48B).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                // FIX: Tambah const
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left,
                    size: 16,
                    color: Color(0xFF38B48B), // FIX: Warna icon disesuaikan
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Prev',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF38B48B), // FIX: Warna teks disesuaikan
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF38B48B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF38B48B),
              ),
            ),
          ),
          GestureDetector(
            onTap: currentPage < totalPages - 1 ? _nextPage : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: currentPage < totalPages - 1
                    ? const Color(0xFF38B48B).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                // FIX: Tambah const
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF38B48B), // FIX: Warna teks disesuaikan
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFF38B48B), // FIX: Warna icon disesuaikan
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            if (widget.data.isEmpty) {
              return const Center(
                child: Text(
                  'Tidak ada data chart tersedia.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            // Logic for scrolling vs static chart (should work after pagination in HomeContent)
            return Padding(
              padding: const EdgeInsets.all(16),
              child: BarChart(_getBarChartData()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScrollableChart() {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: _calculateChartWidth(),
        height: 280,
        child: BarChart(_getBarChartData()),
      ),
    );
  }

  Widget _buildStaticChart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(_getBarChartData()),
    );
  }

  Widget _buildSummary() {
    final totalData =
        _calculateTotalData(); // This now calculates from widget.data (which is _weeklyData)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF38B48B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38B48B).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
              'Total Sehat', totalData['sehat']!, const Color(0xFF10B981)),
          _buildSummaryItem(
              'Total Kuning', totalData['kuning']!, const Color(0xFFF59E0B)),
          _buildSummaryItem('Total Keriting', totalData['keriting']!,
              const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _shouldShowScrolling() {
    return widget.data.length > widget.maxVisibleBars;
  }

  bool _shouldShowPagination() {
    return widget.data.length > widget.maxVisibleBars && totalPages > 1;
  }

  double _calculateChartWidth() {
    return widget.data.length *
        45.0; // 45.0 = width per bar group (adjust as needed)
  }

  String _getCurrentDataRange() {
    final startIndex = currentPage * widget.maxVisibleBars;
    final endIndex = ((currentPage + 1) * widget.maxVisibleBars)
        .clamp(0, widget.data.length);
    return '${startIndex + 1}-${endIndex}';
  }

  void _previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
      _animationController.reset();
      _animationController.forward();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          currentPage * (45.0 * widget.maxVisibleBars),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _nextPage() {
    if (currentPage < totalPages - 1) {
      setState(() {
        currentPage++;
      });
      _animationController.reset();
      _animationController.forward();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          currentPage * (45.0 * widget.maxVisibleBars),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  List<LeafData> _getCurrentPageData() {
    if (widget.data.isEmpty) {
      return [];
    }

    final startIndex = currentPage * widget.maxVisibleBars;
    final endIndex = ((currentPage + 1) * widget.maxVisibleBars)
        .clamp(0, widget.data.length);
    return widget.data.sublist(startIndex, endIndex);
  }

  String _getDayName(int index) {
    final currentData = _getCurrentPageData();
    if (index < currentData.length) {
      return currentData[index].day;
    }
    return '';
  }

  String _getCategoryName(int index) {
    const categories = [
      'Sehat',
      'Kuning',
      'Keriting'
    ]; // Order must match BarChartRodData order
    return categories[index];
  }

  BarChartData _getBarChartData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _calculateMaxY(),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: const Color(0xFF1A202C),
          tooltipRoundedRadius: 12,
          tooltipMargin: 8,
          tooltipPadding: const EdgeInsets.all(12),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String dayName = _getDayName(group.x.toInt());
            String category = _getCategoryName(rodIndex);
            return BarTooltipItem(
              '$dayName\n$category: ${rod.y.round()}',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
          showTitles: true,
          getTextStyles: (context, value) => const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          margin: 16,
          getTitles: (double value) {
            return _getDayName(value.toInt());
          },
        ),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (context, value) => const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          margin: 15,
          reservedSize: 16,
          interval: _calculateInterval(),
          getTitles: (value) {
            return value.toInt().toString();
          },
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
          left: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
      barGroups: _generateBarGroups(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _calculateInterval(),
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.15),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    final currentData = _getCurrentPageData();

    return List.generate(currentData.length, (index) {
      bool isTouched = index == touchedIndex;
      double width = isTouched ? 12 : 8;

      final data = currentData[index];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            y: data.sehat * _animation.value,
            colors: [const Color(0xFF10B981)],
            width: width,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          BarChartRodData(
            y: data.kuning * _animation.value,
            colors: [const Color(0xFFF59E0B)],
            width: width,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          BarChartRodData(
            y: data.keriting * _animation.value,
            colors: [const Color(0xFFEF4444)],
            width: width,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0, 1, 2] : [],
      );
    });
  }

  double _calculateMaxY() {
    final currentData = _getCurrentPageData();
    if (currentData.isEmpty) return 5.0; // Default max Y if no data

    double maxDataValue = 0;

    for (var leaf in currentData) {
      maxDataValue = [maxDataValue, leaf.sehat, leaf.kuning, leaf.keriting]
          .reduce((a, b) => a > b ? a : b);
    }

    return widget.maxY ??
        (maxDataValue + (maxDataValue * 0.2)).clamp(5.0, double.infinity);
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (maxY == 0) return 1.0;
    double interval = (maxY / 5).ceilToDouble();
    if (interval == 0) interval = 1.0;
    return interval;
  }

  Map<String, int> _calculateTotalData() {
    final dataToUse =
        _getCurrentPageData(); // Calculate total data from current page data

    int totalSehat = 0;
    int totalKuning = 0;
    int totalKeriting = 0;

    for (var leaf in dataToUse) {
      totalSehat += leaf.sehat.toInt();
      totalKuning += leaf.kuning.toInt();
      totalKeriting += leaf.keriting.toInt();
    }

    return {
      'sehat': totalSehat,
      'kuning': totalKuning,
      'keriting': totalKeriting,
    };
  }
}
