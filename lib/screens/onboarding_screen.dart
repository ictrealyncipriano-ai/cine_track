import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.explore_rounded,
      title: 'Discover Movies',
      description:
          'Browse thousands of movies from TMDB. Search by genre, year, or popularity to find your next favorite film.',
      color: Color(0xFFFFC107),
    ),
    _OnboardingPage(
      icon: Icons.bookmark_rounded,
      title: 'Track Favorites',
      description:
          'Save movies to your favorites, build a watchlist, and keep track of everything you\'ve watched.',
      color: Color(0xFF7C4DFF),
    ),
    _OnboardingPage(
      icon: Icons.play_circle_fill_rounded,
      title: 'Start Watching',
      description:
          'Stream movies built-in, read reviews, rate films, and explore recommendations tailored just for you.',
      color: Color(0xFF4CAF50),
    ),
    _OnboardingPage(
      icon: Icons.person_rounded,
      title: 'Sign In or Explore',
      description:
          'Create an account to sync across devices, or browse as a guest and start watching right away.',
      color: Color(0xFFE91E63),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            if (!isLast)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildSlide(_pages[i]),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final page = _pages[i];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? page.color
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: isLast
                    ? _buildGetStartedButton()
                    : _buildNextButton(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      child: Text(
        'Next',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return ElevatedButton(
      onPressed: widget.onComplete,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      child: Text(
        'Get Started',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(page.icon, size: 56, color: page.color),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
