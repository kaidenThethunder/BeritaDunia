import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article.dart';
import '../providers/news_provider.dart';
import '../utils/constants.dart';
import './article_detail_screen.dart';
import './search_result_screen.dart';
import '../widgets/news_card.dart';
import '../models/video_article.dart'; // Added for video news
import '../widgets/video_news_card.dart'; // Added for video news card
import 'package:firebase_auth/firebase_auth.dart'; // Added for logout functionality
import './add_news_screen.dart'; // Added for add news functionality
import './admin_screen.dart'; // Added for admin functionality
import '../utils/admin_utils.dart'; // Added for admin validation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin { // Added SingleTickerProviderStateMixin
  final TextEditingController _searchController = TextEditingController();
  TabController? _tabController; // Added TabController

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: AppConstants.categories.length + 1, vsync: this); // +1 for 'HOME'
    // Ambil berita saat widget diinisialisasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      newsProvider.fetchNews();
      newsProvider.fetchVideoNews(); // Fetch video news
      newsProvider.fetchUserGeneratedNews(); // Fetch user-generated news
    });
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Dispose TabController
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
              Colors.purple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar with gradient background
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Top row with menu, title, and actions
                    Row(
                      children: [
                        Builder(
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white, size: 20),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.newspaper,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Berita Dunia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Search button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: Colors.white, size: 20),
                            onPressed: () {
                              showSearch(context: context, delegate: ArticleSearchDelegate(_searchController));
                            },
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Country selector
                        Consumer<NewsProvider>(
                          builder: (context, newsProvider, child) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.flag_outlined, color: Colors.white, size: 20),
                                onSelected: (String countryCode) {
                                  newsProvider.setCountry(countryCode);
                                },
                                itemBuilder: (BuildContext context) {
                                  return AppConstants.countries.entries.map((entry) {
                                    return PopupMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    );
                                  }).toList();
                                },
                                tooltip: 'Select Country',
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        // Logout button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                            onPressed: () async {
                              try {
                                await FirebaseAuth.instance.signOut();
                                // Navigation will be handled by StreamBuilder in main.dart
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error during logout: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            tooltip: 'Logout',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Categories TabBar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: Colors.white,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.7),
                        tabs: [
                          const Tab(text: 'HOME'),
                          ...AppConstants.categories.map((category) => Tab(text: category.toUpperCase())).toList(),
                        ],
                        onTap: (index) {
                          if (index == 0) {
                            Provider.of<NewsProvider>(context, listen: false).setCategory(null);
                          } else {
                            Provider.of<NewsProvider>(context, listen: false).setCategory(AppConstants.categories[index - 1]);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _buildTabViews(),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  List<Widget> _buildTabViews() {
    return [
      _buildMainContent(context), // HOME tab
      ...AppConstants.categories.map((category) => _buildCategoryContent(category)),
    ];
  }

  Widget _buildCategoryContent(String category) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          final categoryArticles = newsProvider.getArticlesByCategory(category);
          
          if (newsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }
          
          if (categoryArticles.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Colors.purple.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.article_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tidak ada berita untuk kategori $category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coba refresh atau pilih kategori lain',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Colors.purple.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => newsProvider.refreshAllNews(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Separate articles for featured and latest sections like home
          final featuredArticle = categoryArticles.isNotEmpty ? categoryArticles.first : null;
          final latestArticles = categoryArticles.length > 1 ? categoryArticles.sublist(1) : <Article>[];
          
          return RefreshIndicator(
            onRefresh: () => newsProvider.refreshAllNews(),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Featured Article Section
                  if (featuredArticle != null)
                    _buildFeaturedArticle(context, featuredArticle),
                  
                  // Horizontal Scroll for other articles
                  if (latestArticles.isNotEmpty)
                    _buildHorizontalArticleList(context, 'Berita $category Lainnya', latestArticles),

                  // "The Latest" Section for this category
                  if (latestArticles.isNotEmpty)
                     Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Text(
                        'Terbaru - $category',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  if (latestArticles.isNotEmpty)
                    _buildLatestNewsGrid(context, latestArticles),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMainContent(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        final isLoading = newsProvider.isLoading || newsProvider.isVideoLoading;
        final hasNoContent = newsProvider.allArticles.isEmpty && newsProvider.videoArticles.isEmpty;
        
        if (isLoading && hasNoContent) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (!isLoading && hasNoContent) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Colors.purple.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.article_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tidak ada berita yang ditemukan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coba ubah kategori atau kata kunci pencarian',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Colors.purple.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => newsProvider.refreshAllNews(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Separate articles for featured and latest sections
        final articles = newsProvider.allArticles;
        final featuredArticle = articles.isNotEmpty ? articles.first : null;
        final latestArticles = articles.length > 1 ? articles.sublist(1) : <Article>[];

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: RefreshIndicator(
            onRefresh: () => newsProvider.refreshAllNews(),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Featured Article Section
                  if (featuredArticle != null)
                    _buildFeaturedArticle(context, featuredArticle),
                  
                  // Horizontal Scroll for other articles
                  if (latestArticles.isNotEmpty)
                    _buildHorizontalArticleList(context, 'Berita Lainnya', latestArticles),

                  // "The Latest" Section
                  if (latestArticles.isNotEmpty)
                     Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Text(
                        'The Latest',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  if (latestArticles.isNotEmpty)
                    _buildLatestNewsGrid(context, latestArticles),

                  // Video News Section
                  if (newsProvider.videoArticles.isNotEmpty)
                    _buildVideoNewsSection(context, 'Berita Video', newsProvider.videoArticles)
                  else if (newsProvider.isVideoLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (!newsProvider.isVideoLoading && newsProvider.videoArticles.isEmpty && newsProvider.articles.isNotEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Tidak ada berita video ditemukan.'),
                    ))
                  else
                    const SizedBox.shrink(),

                  // User Generated News Section
                  _buildUserGeneratedNewsSection(context, newsProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build the video news section (e.g., a horizontal list)
  Widget _buildVideoNewsSection(BuildContext context, String title, List<VideoArticle> videos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 270, // Adjust height for video cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return SizedBox(
                width: 200, // Adjust width for each video card
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppConstants.defaultPadding,
                    right: index == videos.length - 1 ? AppConstants.defaultPadding : 0,
                  ),
                  child: VideoNewsCard(videoArticle: video), // Using VideoNewsCard
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method to build the featured article card
  Widget _buildFeaturedArticle(BuildContext context, Article article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        height: 250, // Adjust height as needed
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          image: DecorationImage(
            image: NetworkImage(article.urlToImage ?? ''),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {},
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: AppConstants.defaultPadding,
              left: AppConstants.defaultPadding,
              right: AppConstants.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.source != null) // Check if source exists
                    Text(
                      article.source!.name.toUpperCase(), // Use source.name instead of source directly
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  Text(
                    article.title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a horizontal list of articles
  Widget _buildHorizontalArticleList(BuildContext context, String title, List<Article> articles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 270, // Adjust height for the horizontal cards (same as video cards)
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return SizedBox(
                width: 200, // Adjust width for each card in the horizontal list (same as video cards)
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppConstants.defaultPadding,
                    right: index == articles.length - 1 ? AppConstants.defaultPadding : 0,
                  ),
                  child: NewsCard(article: article), // Using the existing NewsCard
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method for "The Latest" news grid
  Widget _buildLatestNewsGrid(BuildContext context, List<Article> articles) {
    // For simplicity, let's reuse the GridView logic from before, but it could be different
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        }
        return GridView.builder(
          shrinkWrap: true, // Important for GridView inside SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: articles.length > 6 ? 6 : articles.length, // Limit to e.g., 6 articles for this section
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75, // Reduced aspect ratio to prevent overflow
            crossAxisSpacing: AppConstants.defaultPadding,
            mainAxisSpacing: AppConstants.defaultPadding,
          ),
          itemBuilder: (context, index) {
            final article = articles[index];
            return NewsCard(article: article);
          },
        );
      },
    );
  }



  // Method untuk membangun section berita user-generated
  Widget _buildUserGeneratedNewsSection(BuildContext context, NewsProvider newsProvider) {
    // Ambil semua berita user-generated yang sudah di-allow
    final userGeneratedArticles = newsProvider.allArticles
        .where((article) => article.isUserGenerated == true)
        .toList();

    if (userGeneratedArticles.isEmpty) {
      return const SizedBox.shrink(); // Tidak tampilkan section jika tidak ada berita
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.people,
                  color: Colors.green[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Berita Pengguna',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth > 1200) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 800) {
              crossAxisCount = 3;
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              itemCount: userGeneratedArticles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75, // Reduced aspect ratio to prevent overflow
                crossAxisSpacing: AppConstants.defaultPadding,
                mainAxisSpacing: AppConstants.defaultPadding,
              ),
              itemBuilder: (context, index) {
                final article = userGeneratedArticles[index];
                return NewsCard(article: article);
              },
            );
          },
        ),
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }

  // Method untuk membangun drawer
  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: Text(
              user?.displayName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.displayName?.isNotEmpty == true)
                    ? user!.displayName![0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle),
            title: const Text('Tambah Berita'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNewsScreen()),
              );
            },
          ),
          // Tampilkan menu Admin Panel hanya untuk admin
            if (AdminUtils.isCurrentUserAdmin())
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Panel'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminScreen()),
                  );
                },
              ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

// Delegate for search functionality (can be moved to a separate file)
class ArticleSearchDelegate extends SearchDelegate<String> {
  final TextEditingController searchController;

  ArticleSearchDelegate(this.searchController);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      // Navigate to SearchResultScreen when a search is submitted
      // This needs to be handled carefully as SearchDelegate builds UI directly
      // For simplicity, we'll pop and then push, or ideally, SearchResultScreen is designed to be shown here.
      // A better approach might be to call a provider method to search and update a list shown here.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => SearchResultScreen(searchQuery: query),
                ),
            );
        }
      });
      return Center(child: Text("Mencari '$query'...")); // Placeholder while navigating
    }
    return const Center(child: Text("Masukkan kata kunci untuk mencari."));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // You could show search history or suggestions here
    // For now, just show a message
    return const Center(
      child: Text('Ketik untuk mencari berita...'),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
        iconTheme: theme.primaryIconTheme,
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),
        toolbarTextStyle: theme.textTheme.bodyMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
        border: InputBorder.none,
      ),
    );
  }
}