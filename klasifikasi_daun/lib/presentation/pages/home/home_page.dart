// lib/presentation/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; 
import 'package:klasifikasi_daun/presentation/pages/camera/CameraPage.dart';
import 'package:klasifikasi_daun/presentation/pages/home/history/detail_history_page.dart';
import 'package:klasifikasi_daun/presentation/pages/home/history/history_page.dart';
import 'package:klasifikasi_daun/presentation/pages/home/profile/profile_page.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_bottom_navbar.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_chart.dart'; // Import CustomChart dan LeafData
import 'package:klasifikasi_daun/models/history_item.dart'; // Import HistoryItem
import 'package:klasifikasi_daun/services/histori_service.dart'; // Pastikan import ini benar
import 'package:intl/intl.dart'; // Untuk DateFormat
import 'package:klasifikasi_daun/utils/auth_token_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeContent(), // Hapus 'const'
    ProfilePage(), // Hapus 'const'
  ];

  void _onTabTapped(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
    } else {
      debugPrint('Indeks navigasi tidak valid: $index');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: _pages[_currentIndex % _pages.length],
      bottomNavigationBar: PerfectBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;
  late ScrollController _scrollController;

  bool _isCollapsed = false;
  double _scrollOffset = 0.0;
  static const double _scrollThreshold = 100.0;

  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = ['Semua', 'Sehat', 'Kuning', 'Keriting'];

  List<LeafData> _weeklyData = [];
  List<HistoryItem> _recentHistoryData = [];
  int _todaysScanCount = 0;
  Map<String, int> _totalHistoryStats = {'total': 0, 'sehat': 0, 'kuning': 0, 'keriting': 0};

  bool _isLoadingData = true;
  String _loggedInUserName = 'Pengguna';
  int? _loggedInUserId;
  String? _profilePictureUrl;
  bool _isInitialLoadComplete = false;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutBack),
    );

    _headerAnimationController.forward();

    _selectedEndDate = DateTime.now();
    _selectedStartDate = _selectedEndDate!.subtract(const Duration(days: 6));

    _loadData();
    _loadUserInfo();
  }

  // Fungsi untuk menampilkan date range picker
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020), // Sesuaikan dengan tanggal histori terlama Anda
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate ?? DateTime.now().subtract(const Duration(days: 6)),
        end: _selectedEndDate ?? DateTime.now(),
      ),
      cancelText: 'Batal',
      confirmText: 'Pilih',
      saveText: 'Simpan',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF38B48B),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF38B48B),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && (picked.start != _selectedStartDate || picked.end != _selectedEndDate)) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _loadData(); // Muat ulang data dengan rentang tanggal baru
    }
  }

  // Fungsi untuk memuat info user dari AuthTokenManager
  Future<void> _loadUserInfo() async {
    final userName = await AuthTokenManager.getUserName();
    final userId = await AuthTokenManager.getUserId();
    final profilePicUrl = await AuthTokenManager.getProfilePictureUrl();
    if (mounted) {
      setState(() {
        _loggedInUserName = userName ?? 'Pengguna';
        _loggedInUserId = userId;
        _profilePictureUrl = profilePicUrl;
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingData = true;
    });
    try {
      final allHistory = await HistoryService.getHistory(forceRefresh: true);

      // Terapkan filter rentang tanggal di sini
      List<HistoryItem> filteredByDate = allHistory.where((item) {
        if (_selectedStartDate == null || _selectedEndDate == null) {
          return true;
        }
        DateTime itemDate = DateTime(item.scanDate.year, item.scanDate.month, item.scanDate.day);
        DateTime startDate = DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day);
        DateTime endDate = DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day);
        
        return (itemDate.isAtSameMomentAs(startDate) || itemDate.isAfter(startDate)) &&
               (itemDate.isAtSameMomentAs(endDate) || itemDate.isBefore(endDate));
      }).toList();

      // Memproses data berdasarkan histori yang sudah difilter
      final recentHistory = await HistoryService.getRecentHistory(limit: 5, data: filteredByDate); // FIX: Teruskan 'data' dan tambahkan await
      final todaysCount = await HistoryService.getTodaysScanCount(data: filteredByDate); // FIX: Teruskan 'data' dan tambahkan await
      final weeklyChartData = await HistoryService.getWeeklyData(data: filteredByDate); // FIX: Teruskan 'data'
      final historyStats = await HistoryService.getHistoryStats(data: filteredByDate); // FIX: Teruskan 'data' dan tambahkan await


      debugPrint('HomeContent: Data histori terbaru dimuat: ${recentHistory.length} item');
      debugPrint('HomeContent: Jumlah scan hari ini: $todaysCount');
      debugPrint('HomeContent: Data chart mingguan: ${weeklyChartData.length} hari');
      debugPrint('HomeContent: Statistik total: $historyStats');


      if (mounted) {
        setState(() {
          _recentHistoryData = recentHistory;
          _todaysScanCount = todaysCount;
          _weeklyData = weeklyChartData;
          _totalHistoryStats = historyStats;
          _isLoadingData = false; 
          _isInitialLoadComplete = true; 
        });
      }
    } catch (e) {
      debugPrint('Error memuat data beranda: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false; 
          _isInitialLoadComplete = true; 
        });
      }
    }
  }

  // Fungsi helper untuk memproses data mingguan
  List<LeafData> _processWeeklyData(List<HistoryItem> allHistory) {
    final now = DateTime.now();
    Map<String, Map<String, int>> dailyCounts = {};
    final List<String> weekDayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']; 

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      dailyCounts[formattedDate] = {'sehat': 0, 'kuning': 0, 'keriting': 0};
    }

    for (var item in allHistory) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(item.scanDate);
      if (dailyCounts.containsKey(formattedDate)) {
        switch (item.predictedDisease.toLowerCase()) {
          case 'sehat':
            dailyCounts[formattedDate]!['sehat'] = dailyCounts[formattedDate]!['sehat']! + 1;
            break;
          case 'kuning':
            dailyCounts[formattedDate]!['kuning'] = dailyCounts[formattedDate]!['kuning']! + 1;
            break;
          case 'keriting':
            dailyCounts[formattedDate]!['keriting'] = dailyCounts[formattedDate]!['keriting']! + 1;
            break;
        }
      }
    }

    final List<LeafData> weeklyData = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      final dayNameIndex = date.weekday % 7; 
      final dayName = weekDayNames[dayNameIndex];

      final counts = dailyCounts[formattedDate]!;
      weeklyData.add(LeafData(
        day: dayName,
        sehat: counts['sehat']!.toDouble(),
        kuning: counts['kuning']!.toDouble(),
        keriting: counts['keriting']!.toDouble(),
      ));
    }
    return weeklyData;
  }

  Map<String, int> _processHistoryStats(List<HistoryItem> allHistory) {
    final stats = <String, int>{
      'total': allHistory.length, 
      'sehat': 0,
      'kuning': 0,
      'keriting': 0,
    };
    for (final item in allHistory) {
      switch (item.predictedDisease.toLowerCase()) {
        case 'sehat':
          stats['sehat'] = stats['sehat']! + 1;
          break;
        case 'kuning':
          stats['kuning'] = stats['kuning']! + 1;
          break;
        case 'keriting':
          stats['keriting'] = stats['keriting']! + 1;
          break;
      }
    }
    return stats;
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
        _isCollapsed = _scrollOffset > _scrollThreshold;
      });
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<HistoryItem> get _filteredHistoryData {
    if (_selectedFilter.toLowerCase() == 'semua') {
      return _recentHistoryData;
    }
    return _recentHistoryData.where((item) => item.predictedDisease.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  double get _backgroundOpacity {
    if (_scrollOffset <= 0) return 1.0;
    if (_scrollOffset >= _scrollThreshold) return 0.0;
    return 1.0 - (_scrollOffset / _scrollThreshold);
  }

  double get _collapsedOpacity {
    if (_scrollOffset <= _scrollThreshold * 0.7) return 0.0;
    if (_scrollOffset >= _scrollThreshold) return 1.0;
    return (_scrollOffset - _scrollThreshold * 0.7) / (_scrollThreshold * 0.3);
  }

  String _calculateAverageAccuracy() {
    if (_recentHistoryData.isEmpty) return 'N/A';
    double totalAccuracy = 0; 
    for (var item in _recentHistoryData) {
      totalAccuracy += item.topAccuracy;
    }
    return '${(totalAccuracy / _recentHistoryData.length).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverAppBar(
            automaticallyImplyLeading: false, 
            expandedHeight: _isCollapsed ? 0 : 90,
            floating: false,
            pinned: true,
            elevation: _isCollapsed ? 8 : 0,
            backgroundColor: _isCollapsed ? Colors.white : Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildExpandedHeader(),
              collapseMode: CollapseMode.parallax,
            ),
            title: AnimatedOpacity(
              opacity: _collapsedOpacity,
              duration: const Duration(milliseconds: 200),
              child: _buildCollapsedHeader(),
            ),
          ),
        ];
      },
      body: _isLoadingData && !_isInitialLoadComplete
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38B48B)))
          : _buildBody(), 
      clipBehavior: Clip.hardEdge,
    );
  }

  Widget _buildExpandedHeader() {
    return AnimatedOpacity(
      opacity: _backgroundOpacity,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF38B48B),
              Color(0xFF269C7E),
              Color(0xFF1E8B6B),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 20, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxHeight < 60) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: constraints.maxHeight > 120 ? 34 : 26,
                            backgroundColor: const Color(0xFFFFFFFF),
                            backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                                ? NetworkImage(_profilePictureUrl!) as ImageProvider
                                : null,
                            child: (_profilePictureUrl == null || _profilePictureUrl!.isEmpty)
                                ? Text(
                                    _loggedInUserName.isNotEmpty
                                        ? _loggedInUserName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3F7D58),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (constraints.maxHeight > 80)
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: constraints.maxHeight > 120 ? 19 : 17,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  child: Text(_loggedInUserName),
                                ),
                              if (constraints.maxHeight > 80)
                                const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: constraints.maxHeight > 100 ? 21 : 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                child: const Text('Selamat Datang 🙌'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF3F7D58),
            backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                ? NetworkImage(_profilePictureUrl!) as ImageProvider
                : null,
            child: (_profilePictureUrl == null || _profilePictureUrl!.isEmpty)
                ? Text(
                    _loggedInUserName.isNotEmpty
                        ? _loggedInUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loggedInUserName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    
    if (_isInitialLoadComplete && _recentHistoryData.isEmpty && _selectedFilter.toLowerCase() != 'semua') {
      return _buildEmptyState();
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(0, _isCollapsed ? -10 : 0, 0),
            child: Stack(
              children: [
                ModernLeafAnalysisChart(
                  title: 'Analisis Kesehatan Daun',
                  period: _formatSelectedPeriod(),
                  data: _weeklyData, 
                  showAnimation: true,
                  maxY: null,
                  onPeriodTap: _showDateRangePicker,
                ),
                if (_isLoadingData)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF38B48B),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Enhanced Quick Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'Scan Hari Ini',
                  _todaysScanCount.toString(), 
                  Icons.camera_alt_outlined,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'Akurasi Rata-rata',
                  _calculateAverageAccuracy(), 
                  Icons.analytics_outlined,
                  const Color(0xFF38B48B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Enhanced History Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Histori Daun',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    );
                    _loadData(); 
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF38B48B),
                  ),
                  label: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF38B48B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Enhanced Filter Buttons
          _buildFilterButtons(),

          const SizedBox(height: 12),

          // Enhanced History List
          _filteredHistoryData.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredHistoryData.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(_filteredHistoryData[index]);
                  },
                ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
  // Fungsi helper untuk memformat periode yang dipilih
  String _formatSelectedPeriod() {
    if (_selectedStartDate != null && _selectedEndDate != null) {
      final formatter = DateFormat('dd MMMyyyy');
      final startFormatted = formatter.format(_selectedStartDate!);
      final endFormatted = formatter.format(_selectedEndDate!);
      
      if (startFormatted == endFormatted) {
        return startFormatted;
      }
      return '$startFormatted - $endFormatted';
    }
    return 'Mingguan'; // Default jika belum ada tanggal dipilih
  }

  
  Widget _buildFilterButtons() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option;

          Color getFilterColor(String filter) {
            switch (filter.toLowerCase()) {
              case 'sehat':
                return const Color(0xFF10B981);
              case 'kuning':
                return const Color(0xFFF59E0B);
              case 'keriting':
                return const Color(0xFFEF4444);
              default:
                return const Color(0xFF38B48B);
            }
          }

          IconData getFilterIcon(String filter) {
            switch (filter.toLowerCase()) {
              case 'sehat':
                return Icons.check_circle_outline;
              case 'kuning':
                return Icons.warning_amber_outlined;
              case 'keriting':
                return Icons.bug_report_outlined;
              default:
                return Icons.filter_list_outlined;
            }
          }

          final filterColor = getFilterColor(option);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = option;
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? filterColor : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? filterColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: filterColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getFilterIcon(option),
                      size: 18,
                      color: isSelected ? Colors.white : filterColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : filterColor,
                      ),
                    ),
                    if (option != 'Semua') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : filterColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_recentHistoryData.where((item) => item.predictedDisease.toLowerCase() == option.toLowerCase()).length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : filterColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada data untuk filter "$_selectedFilter"',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Coba pilih filter lain atau lakukan scan daun baru',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(HistoryItem item) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailHistoryPage(historyItem: item),
          ),
        );
        _loadData(); // Muat ulang data saat kembali dari DetailHistoryPage
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                item.statusIcon,
                color: item.statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.predictedDisease,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.predictedDisease,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${item.topAccuracy}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMMyyyy').format(item.scanDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}