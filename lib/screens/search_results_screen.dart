import 'package:flutter/material.dart';
import '../models/paper_model.dart';
import '../services/api_service.dart';
import '../services/translation_helper.dart';
import 'paper_detail_sheet.dart';
import '../theme/app_theme.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final bool filterMedicineOnly;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.filterMedicineOnly = true,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Paper> _papers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _sortBy = 'relevance'; // 'relevance', 'year', 'citations'
  Map<String, String> _translationInfo = {};

  @override
  void initState() {
    super.initState();
    _translationInfo = TranslationHelper.getTranslationInfo(widget.query);
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await ApiService.searchPapers(
        query: widget.query,
        filterMedicineOnly: widget.filterMedicineOnly,
        sortBy: _sortBy,
      );

      if (mounted) {
        setState(() {
          _papers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e.toString().contains('RateLimitError')) {
            _errorMessage = 'Hệ thống đang quá tải (Rate Limit). Vui lòng thử lại sau vài giây.';
          } else if (e.toString().contains('NetworkError')) {
            _errorMessage = 'Không có kết nối mạng hoặc lỗi máy chủ. Vui lòng kiểm tra lại đường truyền.';
          } else {
            _errorMessage = 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
          }
        });
      }
    }
  }

  void _changeSorting(String? newSort) {
    if (newSort != null && newSort != _sortBy) {
      setState(() {
        _sortBy = newSort;
      });
      _performSearch();
    }
  }

  void _showPaperDetails(Paper paper) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: PaperDetailSheet(paper: paper),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTranslation = _translationInfo['translated'] != null && _translationInfo['translated']!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Kết quả tìm kiếm',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Query Information Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: AppTheme.darkBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Từ khóa: ',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    children: [
                      TextSpan(
                        text: widget.query,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasTranslation) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryCyan.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.translate,
                          size: 14,
                          color: AppTheme.primaryCyan,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tự động dịch học thuật (Eng):',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryCyan,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _translationInfo['translated']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                
                // Sorting & Results stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isLoading
                          ? 'Đang tìm kiếm tài liệu...'
                          : 'Tìm thấy ${_papers.length} bài báo khoa học',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    
                    // Sort Dropdown
                    if (!_isLoading && _errorMessage == null && _papers.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.sort, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          DropdownButton<String>(
                            value: _sortBy,
                            dropdownColor: AppTheme.darkSurface,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryCyan),
                            items: const [
                              DropdownMenuItem(value: 'relevance', child: Text('Độ liên quan')),
                              DropdownMenuItem(value: 'year', child: Text('Mới nhất')),
                              DropdownMenuItem(value: 'citations', child: Text('Trích dẫn nhiều')),
                            ],
                            onChanged: _changeSorting,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(height: 1, color: Color(0xFF2E3E5D)),
          
          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_papers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _papers.length,
      itemBuilder: (context, index) {
        final paper = _papers[index];
        return _buildPaperCard(paper);
      },
    );
  }

  Widget _buildPaperCard(Paper paper) {
    return Card(
      child: InkWell(
        onTap: () => _showPaperDetails(paper),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Journal & Year
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      paper.journal ?? 'Tạp chí chuyên ngành',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    paper.year?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Title
              Text(
                paper.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Authors
              if (paper.authors.isNotEmpty)
                Text(
                  paper.authors.join(', '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              
              // TLDR / Preview
              if (paper.tldr != null && paper.tldr!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Text(
                    paper.tldr!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Bottom row: citation count & Action indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Citations badge
                  Row(
                    children: [
                      const Icon(Icons.format_quote, size: 14, color: AppTheme.lightTeal),
                      const SizedBox(width: 2),
                      Text(
                        'Trích dẫn: ${paper.citationCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.lightTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  // Read detail indicator
                  const Row(
                    children: [
                      Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppTheme.primaryCyan,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E3E5D), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header line (Journal & year)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 120, height: 10, color: Colors.white.withOpacity(0.05)),
                  Container(width: 40, height: 10, color: Colors.white.withOpacity(0.05)),
                ],
              ),
              const SizedBox(height: 12),
              // Title lines
              Container(width: double.infinity, height: 14, color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 6),
              Container(width: 200, height: 14, color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 12),
              // Authors line
              Container(width: 150, height: 10, color: Colors.white.withOpacity(0.05)),
              const SizedBox(height: 16),
              // Bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 80, height: 12, color: Colors.white.withOpacity(0.05)),
                  Container(width: 70, height: 12, color: Colors.white.withOpacity(0.05)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy tài liệu nào',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thử thay đổi từ khóa, kiểm tra chính tả hoặc gõ từ khóa bằng Tiếng Anh trực tiếp.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.accentRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Lỗi kết nối / Truy vấn',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.accentRed),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Đã xảy ra lỗi khi kết nối hệ thống.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _performSearch,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
