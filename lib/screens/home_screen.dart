import 'package:flutter/material.dart';
import '../services/translation_helper.dart';
import 'search_results_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewBookmarks;

  const HomeScreen({
    super.key,
    this.onViewBookmarks,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _filterMedicineOnly = true;
  String _translationPreview = '';

  // Quick categories
  final List<Map<String, String>> _categories = [
    {
      'title': 'Ung thư',
      'english': 'cancer oncology',
      'icon': '🔬',
      'description': 'Nghiên cứu ung thư & khối u',
    },
    {
      'title': 'Tim mạch',
      'english': 'cardiology cardiovascular',
      'icon': '❤️',
      'description': 'Bệnh tim & tuần hoàn máu',
    },
    {
      'title': 'Thần kinh',
      'english': 'neurology brain stroke',
      'icon': '🧠',
      'description': 'Não bộ & thần kinh học',
    },
    {
      'title': 'Vắc-xin',
      'english': 'vaccine immunization',
      'icon': '💉',
      'description': 'Miễn dịch học & vắc-xin',
    },
    {
      'title': 'Nhi khoa',
      'english': 'pediatrics child health',
      'icon': '🧸',
      'description': 'Y học trẻ em',
    },
    {
      'title': 'Dược lý',
      'english': 'pharmacology clinical trials',
      'icon': '💊',
      'description': 'Thử nghiệm thuốc & lâm sàng',
    },
    {
      'title': 'Tiểu đường',
      'english': 'diabetes endocrinology',
      'icon': '🩸',
      'description': 'Đái tháo đường & nội tiết',
    },
    {
      'title': 'Di truyền',
      'english': 'genetics dna genomics',
      'icon': '🧬',
      'description': 'Gen & bản đồ di truyền',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final text = _searchController.text;
    final info = TranslationHelper.getTranslationInfo(text);
    setState(() {
      _translationPreview = info['translated'] ?? '';
    });
  }

  void _navigateToResults(String query) {
    if (query.trim().isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          query: query,
          filterMedicineOnly: _filterMedicineOnly,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: AppTheme.primaryCyan,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'AEGIS MED',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (widget.onViewBookmarks != null)
                    IconButton(
                      icon: const Icon(Icons.bookmark_outline, color: AppTheme.textSecondary),
                      onPressed: widget.onViewBookmarks,
                      tooltip: 'Thư viện đã lưu',
                    ),
                ],
              ),
              const SizedBox(height: 36),
              
              // Welcome Banner
              Text(
                'Tìm kiếm thông tin\nY học Chuyên sâu',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hệ thống kết nối trực tiếp cơ sở dữ liệu Semantic Scholar. Loại bỏ hoàn toàn các thông tin thương mại, phòng khám, bệnh viện.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              
              // Search Panel
              _buildSearchPanel(),
              const SizedBox(height: 36),
              
              // Quick Categories Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chủ đề chuyên khoa nổi bật',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Icon(Icons.star_outline, size: 16, color: AppTheme.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              
              // Categories Grid/List
              _buildCategoriesList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2E3E5D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text field
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _navigateToResults,
            decoration: InputDecoration(
              hintText: 'Nhập tên bệnh, hoạt chất, nghiên cứu...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          
          // Translation tips display
          if (_translationPreview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: AppTheme.primaryCyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'Thuật ngữ dịch học thuật: ',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        children: [
                          TextSpan(
                            text: _translationPreview,
                            style: const TextStyle(
                              color: AppTheme.primaryCyan,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Filter toggle
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _filterMedicineOnly,
                  activeColor: AppTheme.primaryCyan,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _filterMedicineOnly = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Chỉ hiển thị bài báo y sinh & lâm sàng',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Search Button
          ElevatedButton(
            onPressed: () => _navigateToResults(_searchController.text),
            child: const Text('TÌM KIẾM TÀI LIỆU'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return InkWell(
          onTap: () => _navigateToResults(cat['english']!),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E3E5D), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat['icon']!,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat['title']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat['description']!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
