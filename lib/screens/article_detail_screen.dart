import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import './edit_news_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Enhanced App bar with image and gradient
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: _buildAppBarActions(),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.article.urlToImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'article-image-${widget.article.title}',
                          child: Image.network(
                            widget.article.urlToImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.purple.shade400,
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, 
                                      size: 60, color: Colors.white70),
                                ),
                              );
                            },
                          ),
                        ),
                        // Enhanced gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.8),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.article, size: 60, color: Colors.white70),
                      ),
                    ),
            ),
          ),
          // Enhanced Content with animations
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced Title with gradient
                        Container(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            widget.article.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).primaryColor.withOpacity(0.7),
                                  ],
                                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Enhanced metadata chips
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildInfoChip(
                              context,
                              icon: Icons.source,
                              label: 'Sumber: ${widget.article.source}',
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            if (widget.article.publishedAt != null)
                              _buildInfoChip(
                                context,
                                icon: Icons.schedule,
                                label: 'Tanggal: ${_formatDate(widget.article.publishedAt!)}',
                                color: Colors.green,
                              ),
                            if (widget.article.author != null && widget.article.author!.isNotEmpty)
                              _buildInfoChip(
                                context,
                                icon: Icons.person,
                                label: 'Penulis: ${widget.article.author}',
                                color: Colors.orange,
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Enhanced Description Section
                        _buildSectionTitle('Ringkasan Berita', Icons.summarize),
                        const SizedBox(height: 16),
                        if (widget.article.description != null)
                          _buildContentCard(
                            child: Text(
                              widget.article.description!,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          )
                        else
                          _buildContentCard(
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, 
                                    color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Deskripsi tidak tersedia untuk artikel ini.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                        // Enhanced Content Section
                        _buildSectionTitle('Konten Lengkap', Icons.article),
                        const SizedBox(height: 16),
                        _buildContentCard(
                          child: widget.article.content != null && widget.article.content!.isNotEmpty
                            ? Text(
                                widget.article.content!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.7,
                                  color: Colors.black87,
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(Icons.open_in_browser, 
                                      color: Colors.blue[600], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Untuk membaca artikel lengkap, silakan klik tombol di bawah ini untuk membuka artikel di situs aslinya.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.7,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 32),
                        // Enhanced Action Button
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  if (widget.article.url != null) {
                                    await _launchURL(widget.article.url!);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Tidak dapat membuka URL'),
                                        backgroundColor: Colors.red[400],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.open_in_browser, color: Colors.white),
                              label: const Text(
                                'Baca Artikel Lengkap',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.2),
                Theme.of(context).primaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
  
  String _formatDate(DateTime date) {
    final List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Method untuk membangun actions di AppBar
  List<Widget> _buildAppBarActions() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Hanya tampilkan edit/delete jika user adalah creator artikel
    if (widget.article.isUserGenerated && 
        widget.article.userId == currentUser?.uid) {
      return [
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _editArticle(),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteArticle(),
          ),
        ),
      ];
    }
    return [];
  }

  // Method untuk edit artikel
  void _editArticle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNewsScreen(article: widget.article),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh data jika artikel berhasil diupdate
        Provider.of<NewsProvider>(context, listen: false).fetchUserGeneratedNews();
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    });
  }

  // Method untuk delete artikel
  void _deleteArticle() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Artikel'),
          content: const Text('Apakah Anda yakin ingin menghapus artikel ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog
                await _performDelete();
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Method untuk melakukan penghapusan artikel
  Future<void> _performDelete() async {
    try {
      if (widget.article.documentId != null) {
        await Provider.of<NewsProvider>(context, listen: false)
            .rejectArticle(widget.article.documentId!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Artikel berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Kembali ke halaman sebelumnya
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}