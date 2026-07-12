import 'package:flutter/material.dart';
import 'package:national_academy/core/constants/app_colors.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Physics', 'Chemistry', 'Mathematics', 'Notes'];

  // Mock list of books/resources
  final List<Map<String, dynamic>> _resources = const [
    {
      'title': 'Concepts of Physics (Vol 1)',
      'author': 'Prof. H.C. Verma',
      'category': 'Physics',
      'isDownloaded': true,
      'isBookmarked': true,
      'coverColor': Color(0xFFE2F0FD),
      'textColor': Color(0xFF0066CC),
    },
    {
      'title': 'Organic Chemistry Mechanisms',
      'author': 'Prof. Sudha Murthy',
      'category': 'Chemistry',
      'isDownloaded': false,
      'isBookmarked': false,
      'coverColor': Color(0xFFFFF2E6),
      'textColor': Color(0xFFD35400),
    },
    {
      'title': 'Coordinate Geometry Handbooks',
      'author': 'S.L. Loney',
      'category': 'Mathematics',
      'isDownloaded': true,
      'isBookmarked': false,
      'coverColor': Color(0xFFE8F8F5),
      'textColor': Color(0xFF16A085),
    },
    {
      'title': 'JEE Advanced Physics Revision Notes',
      'author': 'Academy Experts',
      'category': 'Notes',
      'isDownloaded': false,
      'isBookmarked': true,
      'coverColor': Color(0xFFF4ECF7),
      'textColor': Color(0xFF8E44AD),
    },
    {
      'title': 'Physical Chemistry Formula Sheet',
      'author': 'Academy Experts',
      'category': 'Notes',
      'isDownloaded': true,
      'isBookmarked': true,
      'coverColor': Color(0xFFF9EBEA),
      'textColor': Color(0xFFC0392B),
    },
    {
      'title': 'Calculus Problems & Solutions',
      'author': 'I.A. Maron',
      'category': 'Mathematics',
      'isDownloaded': false,
      'isBookmarked': false,
      'coverColor': Color(0xFFFEF9E7),
      'textColor': Color(0xFFD4AC0D),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.surfaceTile1 : AppColors.canvas;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final mutedTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    // Filter resources based on selection & search query
    final filteredResources = _resources.where((res) {
      final matchesCategory = _selectedCategory == 'All' || res['category'] == _selectedCategory;
      final matchesSearch = res['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          res['author'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Study Library',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: -0.6,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.bookmark_outline_rounded, color: textColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceTile1 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairline),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: mutedTextColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(fontSize: 15, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search books, authors, notes...',
                          hintStyle: TextStyle(color: mutedTextColor.withValues(alpha: 0.7), fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Categories Horizontal List ───────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : cardColor,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppColors.hairline,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Grid of Books ───────────────────────────────────────────────
            Expanded(
              child: filteredResources.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_books_rounded, size: 64, color: mutedTextColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No Resources Found',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try altering your search or categories.',
                            style: TextStyle(fontSize: 14, color: mutedTextColor),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.70,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: filteredResources.length,
                      itemBuilder: (context, index) {
                        final res = filteredResources[index];
                        return _buildBookItem(
                          cardColor: cardColor,
                          textColor: textColor,
                          mutedTextColor: mutedTextColor,
                          resource: res,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookItem({
    required Color cardColor,
    required Color textColor,
    required Color mutedTextColor,
    required Map<String, dynamic> resource,
  }) {
    final title = resource['title'] as String;
    final author = resource['author'] as String;
    final category = resource['category'] as String;
    final isDownloaded = resource['isDownloaded'] as bool;
    final isBookmarked = resource['isBookmarked'] as bool;
    final coverColor = resource['coverColor'] as Color;
    final bookTextColor = resource['textColor'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Graphic Cover Representation
          Expanded(
            child: Container(
              color: coverColor,
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  // Book Spine/Binding Highlight
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Title representation in cover
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: bookTextColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: bookTextColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icons overlay
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {},
                      child: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: bookTextColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info Block
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedTextColor,
                      ),
                    ),
                    Icon(
                      isDownloaded ? Icons.cloud_done_rounded : Icons.cloud_download_outlined,
                      color: isDownloaded ? AppColors.success : mutedTextColor,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
