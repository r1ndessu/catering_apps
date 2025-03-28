import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:caterings_app/cashiering.dart';
import 'package:caterings_app/packages.dart';
import 'package:caterings_app/orders.dart';
import 'package:caterings_app/sales.dart';

void main() async {
  await Hive.initFlutter();
  runApp(const CateringApp());
}

class CateringApp extends StatelessWidget {
  const CateringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catering Services',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionBuilder(),
            TargetPlatform.iOS: CustomPageTransitionBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
        )),
        child: child,
      ),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const AnimatedCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  _AnimatedCardState createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse().then((_) => widget.onTap());
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.isSmallScreen ? 32.0 : 40.0;
    final fontSize = widget.isSmallScreen ? 14.0 : 16.0;
    final padding = widget.isSmallScreen ? 12.0 : 16.0;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors[0].withOpacity(_isPressed ? 0.2 : 0.3),
                    blurRadius: _isPressed ? 4 : 8,
                    offset: _isPressed ? Offset(0, 2) : Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(_isPressed ? 0.05 : 0.1),
                            blurRadius: _isPressed ? 2 : 4,
                            offset: _isPressed ? Offset(0, 1) : Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: iconSize,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: widget.isSmallScreen ? 12 : 16),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: _isPressed ? Offset(0, 1) : Offset(0, 2),
                            blurRadius: _isPressed ? 1 : 2,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateWithAnimation(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuart,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get device screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360; // Adjust for Infinix X6731
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade300, Colors.orange.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange, Colors.orange.shade700],
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Catering Services',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 26 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.25),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: isSmallScreen ? 80 : 100,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                    child: Column(
                      children: [
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Select Options',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 22 : 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 32),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: isSmallScreen ? 12.0 : 16.0,
                          mainAxisSpacing: isSmallScreen ? 12.0 : 16.0,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          childAspectRatio: isSmallScreen ? 0.9 : 1.0, // Adjust for smaller screens
                          children: [
                            AnimatedCard(
                              icon: Icons.fastfood,
                              label: 'Book a Package',
                              gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
                              onTap: () => _navigateWithAnimation(context, CashieringScreen()),
                              isSmallScreen: isSmallScreen,
                            ),
                            AnimatedCard(
                              icon: Icons.shopping_cart,
                              label: 'Track Orders',
                              gradientColors: [Colors.red.shade400, Colors.red.shade700],
                              onTap: () => _navigateWithAnimation(context, TrackOrdersScreen()),
                              isSmallScreen: isSmallScreen,
                            ),
                            AnimatedCard(
                              icon: Icons.settings,
                              label: 'Manage Packages',
                              gradientColors: [Colors.orange.shade400, Colors.orange.shade700],
                              onTap: () => _navigateWithAnimation(context, ManagePackagesScreen()),
                              isSmallScreen: isSmallScreen,
                            ),
                            AnimatedCard(
                              icon: Icons.bar_chart,
                              label: 'Sales Dashboard',
                              gradientColors: [Colors.green.shade400, Colors.green.shade700],
                              onTap: () => _navigateWithAnimation(context, const SalesScreen()),
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}