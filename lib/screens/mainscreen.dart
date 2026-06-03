import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tabs/home_tab.dart';
import 'tabs/daily_tab.dart';
import 'tabs/favorite_tab.dart';
import 'tabs/menu_tab.dart';

class MainScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = "";
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Try Prompt AI Image';
      case 1:
        return 'Daily Updates';
      case 2:
        return 'Favorite Prompts';
      case 3:
        return 'Menu';
      default:
        return 'Try Prompt';
    }
  }

  String _getAppBarSubtitle() {
    switch (_currentIndex) {
      case 0:
        return 'Welcome App';
      case 1:
        return 'Daily prompt template';
      case 2:
        return 'Your saved templates';
      case 3:
        return 'App settings and customization';
      default:
        return 'Welcome';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      HomeTab(searchQuery: _searchQuery),
      DailyTab(searchQuery: _searchQuery),
      FavoriteTab(
        isActive: _currentIndex == 2,
        searchQuery: _searchQuery,
      ),
      MenuTab(
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: PopScope(
        canPop: _currentIndex == 0 && !_isSearching,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          
          if (_isSearching) {
            _stopSearch();
            return;
          }
          
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
          }
        },
        child: Scaffold(
        appBar: _currentIndex == 3
            ? null
            : AppBar(
                systemOverlayStyle: overlayStyle,
                leading: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _stopSearch,
                      )
                    : null,
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search prompts by title...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getAppBarTitle(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getAppBarSubtitle(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                actions: [
                  if (_currentIndex != 3) ...[
                    if (_isSearching)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _startSearch,
                      ),
                    const SizedBox(width: 8),
                  ],
                ],
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
            left: 16,
            right: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Daily'),
              _buildNavItem(2, Icons.favorite_border, Icons.favorite, 'Favorite'),
              _buildNavItem(3, Icons.grid_view_outlined, Icons.grid_view, 'Menu'),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final activeColor = primaryColor;
    final inactiveColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return InkWell(
      onTap: () {
        _stopSearch();
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
