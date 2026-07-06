import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/paper_model.dart';
import '../services/bookmark_service.dart';
import '../theme/app_theme.dart';

class PaperDetailSheet extends StatefulWidget {
  final Paper paper;
  final VoidCallback? onBookmarkChanged;

  const PaperDetailSheet({
    super.key,
    required this.paper,
    this.onBookmarkChanged,
  });

  @override
  State<PaperDetailSheet> createState() => _PaperDetailSheetState();
}

class _PaperDetailSheetState extends State<PaperDetailSheet> {
  bool _isBookmarked = false;
  bool _isLoadingBookmark = true;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final status = await BookmarkService.isBookmarked(widget.paper.id);
    if (mounted) {
      setState(() {
        _isBookmarked = status;
        _isLoadingBookmark = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() => _isLoadingBookmark = true);
    
    if (_isBookmarked) {
      await BookmarkService.removeBookmark(widget.paper.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bỏ lưu bài báo này')),
      );
    } else {
      await BookmarkService.saveBookmark(widget.paper);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bài báo vào thư viện')),
      );
    }
    
    await _checkBookmarkStatus();
    widget.onBookmarkChanged?.call();
  }

  Future<void> _openPaperUrl() async {
    final urlString = widget.paper.url;
    
    if (urlString == null || urlString.isEmpty) {
      // Fallback: Nếu không có URL, cho phép tìm tiêu đề trên Google Scholar
      final googleScholarUrl = Uri.parse('https://scholar.google.com/scholar?q=${Uri.encodeComponent(widget.paper.title)}');
      await launchUrl(googleScholarUrl, mode: LaunchMode.externalApplication);
      return;
    }
    
    final uri = Uri.parse(urlString);
    try {
      // Thử mở trực tiếp (bỏ qua kiểm tra canLaunchUrl nếu nó trả về false giả)
      bool launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở trình duyệt. Vui lòng thử lại.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Nếu lỗi, thử mở bằng chế độ in-app webview như một phương án dự phòng
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: Không thể mở liên kết này')),
        );
      }
    }
  }

  void _copyLink() {
    if (widget.paper.url == null || widget.paper.url!.isEmpty) return;
    
    Clipboard.setData(ClipboardData(text: widget.paper.url!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết vào bộ nhớ tạm')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      if (widget.paper.url != null && widget.paper.url!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppTheme.textSecondary),
                          tooltip: 'Sao chép liên kết',
                          onPressed: _copyLink,
                        ),
                      _isLoadingBookmark
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: Padding(
                                padding: EdgeInsets.all(4.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                color: _isBookmarked ? AppTheme.primaryCyan : AppTheme.textSecondary,
                              ),
                              tooltip: _isBookmarked ? 'Bỏ lưu' : 'Lưu lại',
                              onPressed: _toggleBookmark,
                            ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  // Title
                  Text(
                    widget.paper.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Journal & Year
                  Row(
                    children: [
                      const Icon(Icons.menu_book, size: 14, color: AppTheme.primaryCyan),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.paper.journal ?? "Tạp chí không xác định"} (${widget.paper.year ?? "N/A"})',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.secondaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Authors
                  if (widget.paper.authors.isNotEmpty) ...[
                    const Text(
                      'TÁC GIẢ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.paper.authors.join(', '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Citation & Fields row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2E3E5D), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.format_quote, size: 14, color: AppTheme.lightTeal),
                            const SizedBox(width: 4),
                            Text(
                              'Trích dẫn: ${widget.paper.citationCount}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lightTeal,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.paper.fieldsOfStudy.isNotEmpty)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: widget.paper.fieldsOfStudy
                                  .map((field) => Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryCyan.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          field,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.primaryCyan,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // AI TLDR Summary
                  if (widget.paper.tldr != null && widget.paper.tldr!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryCyan.withOpacity(0.12),
                            AppTheme.secondaryBlue.withOpacity(0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryCyan.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [AppTheme.primaryCyan, AppTheme.secondaryBlue],
                                ).createShader(bounds),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'TÓM TẮT NHANH (AI)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryCyan,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.paper.tldr!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Full Abstract
                  const Text(
                    'TÓM TẮT NỘI DUNG (ABSTRACT)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.paper.abstractText ?? 'Không có tóm tắt chi tiết cho bài báo này.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Bottom Action Bar
            if (widget.paper.url != null && widget.paper.url!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _openPaperUrl,
                  icon: const Icon(Icons.launch, size: 18),
                  label: const Text('ĐỌC BÀI BÁO GỐC'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCyan,
                    foregroundColor: AppTheme.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
