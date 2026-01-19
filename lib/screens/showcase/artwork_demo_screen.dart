import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_artwork/app_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';

class ArtworkDemoScreen extends StatefulWidget {
  static const name = 'Artwork Demo';
  static const path = 'artwork';

  const ArtworkDemoScreen({super.key});

  @override
  State<ArtworkDemoScreen> createState() => _ArtworkDemoScreenState();
}

class _ArtworkDemoScreenState extends State<ArtworkDemoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleAnimation() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(ShowcaseScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(title: Text(ArtworkDemoScreen.name)),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSection(
                      context,
                      title: 'LaddingPageLottie',
                      description:
                          'Lottie animation widget for loading/landing pages',
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: LaddingPageLottie(
                                      width: 150,
                                      height: 150,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Default animation (auto-play, repeat)',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: LaddingPageLottie(
                                      width: 150,
                                      height: 150,
                                      controller: _controller,
                                      animate: false,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Controlled animation: ${_isPlaying ? "Playing" : "Paused"}',
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton.filled(
                                      onPressed: _toggleAnimation,
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      context,
                      title: 'LogoGSMLGDEV',
                      description: 'Custom vector logo using CustomPaint',
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: const LogoGSMLGDEV(),
                                ),
                                const SizedBox(height: 16),
                                const Text('Full width logo'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      width: 100,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.inverseSurface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const LogoGSMLGDEV(),
                                    ),
                                    Container(
                                      width: 150,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const LogoGSMLGDEV(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text('Different sizes and backgrounds'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
