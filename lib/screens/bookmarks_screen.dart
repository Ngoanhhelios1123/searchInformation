import 'package:flutter/material.dart';
import '../models/paper_model.dart';
import '../services/bookmark_service.dart';
import 'paper_detail_sheet.dart';
import '../theme/app_theme.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Paper> _savedPapers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final papers = await BookmarkService.getBookmarks();
    if (mounted) {
      setState(() {
        _savedPapers = papers;
        _isLoading = false;
      });
    }
  }

  void _showPaperDetails(Paper paper) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: PaperDetailSheet(
          paper: paper,
          onBookmarkChanged: _loadBookmarks,
        ),
      ),
    );
  }

  Future<void> _removeBookmark(Paper paper) async {
    final success = await BookmarkService.removeBookmark(paper.id);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${paper.title}" khỏi danh sách lưu'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: AppTheme.primaryCyan,
            onPressed: () async {
              await BookmarkService.saveBookmark(paper);
              _loadBookmarks();
            },
          ),
        ),
      );
      _loadBookmarks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'Thư viện đã lưu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_savedPapers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
              onPressed: _loadBookmarks,
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_savedPapers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 72,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa lưu tài liệu nào',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Khi tìm thấy các bài báo khoa học hay, bạn hãy nhấn nút Lưu (biểu tượng Bookmark) ở màn hình chi tiết để lưu chúng vào đây nhé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedPapers.length,
      itemBuilder: (context, index) {
        final paper = _savedPapers[index];
        return _buildBookmarkCard(paper);
      },
    );
  }

  Widget _buildBookmarkCard(Paper paper) {
    return Card(
      key: ValueKey(paper.id),
      child: InkWell(
        onTap: () => _showPaperDetails(paper),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Journal and delete button row
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
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _removeBookmark(paper),
                    tooltip: 'Xóa khỏi danh sách lưu',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Title
              Text(
                paper.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Authors & Year
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      paper.authors.isNotEmpty ? paper.authors.join(', ') : 'Tác giả ẩn danh',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    paper.year?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
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
}
