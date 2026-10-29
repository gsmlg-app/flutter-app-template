import 'package:flutter_app_template/widgets/app_adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:flutter_app_template/screens/showcase/widgets/pelican_bicycle_painter.dart';
import 'package:flutter_app_template/screens/showcase/widgets/pelican_bicycle_widget.dart';

class PelicanBicycleDemoScreen extends StatefulWidget {
  static const name = 'Pelican Ride';
  static const path = 'pelican-ride';

  const PelicanBicycleDemoScreen({super.key});

  @override
  State<PelicanBicycleDemoScreen> createState() =>
      _PelicanBicycleDemoScreenState();
}

class _PelicanBicycleDemoScreenState extends State<PelicanBicycleDemoScreen> {
  bool _isPlaying = true;
  double _speed = 1.0;
  PelicanRideTimeOfDay _timeOfDay = PelicanRideTimeOfDay.day;
  bool _showSunglasses = true;
  bool _showCap = true;
  bool _showFishInPouch = true;
  bool _showEffects = true;
  Color _bikeColor = const Color(0xFFE65100);

  static const List<Color> _bikeColors = [
    Color(0xFFE65100), // Orange
    Color(0xFFD32F2F), // Red
    Color(0xFF1976D2), // Blue
    Color(0xFF388E3C), // Green
    Color(0xFF7B1FA2), // Purple
    Color(0xFF0097A7), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppAdaptiveScaffold(
      internalAnimations: false,
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
              const SliverAppBar(title: Text('Pelican on Bicycle')),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Main Stage Card with Canvas
                    Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PelicanBicycleWidget(
                            speedFactor: _speed,
                            isPlaying: _isPlaying,
                            timeOfDay: _timeOfDay,
                            showSunglasses: _showSunglasses,
                            showCap: _showCap,
                            showFishInPouch: _showFishInPouch,
                            showSpeedLines: _showEffects,
                            showDust: _showEffects,
                            bikeFrameColor: _bikeColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isPlaying
                                      ? Icons.directions_bike
                                      : Icons.pause_circle_outline,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isPlaying
                                      ? 'Pedaling (${(_speed * 60).toInt()} RPM / ${(_speed * 22).toStringAsFixed(1)} km/h)'
                                      : 'Paused at roadside',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                IconButton.filledTonal(
                                  onPressed: () {
                                    setState(() {
                                      _isPlaying = !_isPlaying;
                                    });
                                  },
                                  icon: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                  ),
                                  tooltip: _isPlaying ? 'Pause' : 'Play',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Controls: Speed & Playback
                    _buildSection(
                      context,
                      title: 'Speed & Gear',
                      description:
                          'Adjust pelican pedaling cadence and parallax speed',
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Text('Cadence Speed'),
                                    const Spacer(),
                                    Text(
                                      '${_speed.toStringAsFixed(1)}x',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _speed,
                                  min: 0.2,
                                  max: 2.8,
                                  divisions: 13,
                                  label: '${_speed.toStringAsFixed(1)}x',
                                  onChanged: (val) {
                                    setState(() {
                                      _speed = val;
                                    });
                                  },
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          setState(() => _speed = 0.6),
                                      icon: const Icon(
                                        Icons.directions_walk,
                                        size: 18,
                                      ),
                                      label: const Text('Cruise (0.6x)'),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: () =>
                                          setState(() => _speed = 1.0),
                                      icon: const Icon(
                                        Icons.pedal_bike,
                                        size: 18,
                                      ),
                                      label: const Text('Standard (1.0x)'),
                                    ),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          setState(() => _speed = 2.4),
                                      icon: const Icon(Icons.bolt, size: 18),
                                      label: const Text('Sprint (2.4x)'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Controls: Time of Day
                    _buildSection(
                      context,
                      title: 'Environment & Time of Day',
                      description:
                          'Switch between daytime sun, sunset glow, and starry night',
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SegmentedButton<PelicanRideTimeOfDay>(
                              segments: const [
                                ButtonSegment(
                                  value: PelicanRideTimeOfDay.day,
                                  label: Text('Sunny Day'),
                                  icon: Icon(Icons.wb_sunny_outlined),
                                ),
                                ButtonSegment(
                                  value: PelicanRideTimeOfDay.sunset,
                                  label: Text('Sunset'),
                                  icon: Icon(Icons.wb_twilight),
                                ),
                                ButtonSegment(
                                  value: PelicanRideTimeOfDay.night,
                                  label: Text('Starry Night'),
                                  icon: Icon(Icons.nightlight_round),
                                ),
                              ],
                              selected: {_timeOfDay},
                              onSelectionChanged:
                                  (Set<PelicanRideTimeOfDay> selection) {
                                    setState(() {
                                      _timeOfDay = selection.first;
                                    });
                                  },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Controls: Styling & Easter Eggs
                    _buildSection(
                      context,
                      title: 'Pelican Accessories & Easter Eggs',
                      description:
                          'Toggle funny accessories and scenery effects',
                      children: [
                        Card(
                          child: Column(
                            children: [
                              SwitchListTile(
                                secondary: const Icon(Icons.sports_motorsports),
                                title: const Text('Retro Cycling Cap (复古骑行帽)'),
                                subtitle: const Text(
                                  'Stylish racing cap with flipped-up brim',
                                ),
                                value: _showCap,
                                onChanged: (val) =>
                                    setState(() => _showCap = val),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                secondary: const Icon(Icons.wb_incandescent),
                                title: const Text('Speed Sunglasses (帅气墨镜)'),
                                subtitle: const Text(
                                  'Aerodynamic mirrored sunglasses',
                                ),
                                value: _showSunglasses,
                                onChanged: (val) =>
                                    setState(() => _showSunglasses = val),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                secondary: const Icon(Icons.phishing),
                                title: const Text('Fish in Gular Pouch (喉囊小鱼)'),
                                subtitle: const Text(
                                  'Surprised little fish peaking out of the pouch!',
                                ),
                                value: _showFishInPouch,
                                onChanged: (val) =>
                                    setState(() => _showFishInPouch = val),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                secondary: const Icon(Icons.air),
                                title: const Text(
                                  'Speed Lines & Tire Dust (疾风与飞扬尘埃)',
                                ),
                                subtitle: const Text(
                                  'Dynamic particle effects while riding',
                                ),
                                value: _showEffects,
                                onChanged: (val) =>
                                    setState(() => _showEffects = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Controls: Bicycle Frame Color
                    _buildSection(
                      context,
                      title: 'Bicycle Customization',
                      description:
                          'Choose custom frame color for the pelican’s bicycle',
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: _bikeColors.map((color) {
                                final isSelected = _bikeColor == color;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _bikeColor = color),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                        width: 3.5,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                      ],
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Technical Architecture Card
                    _buildSection(
                      context,
                      title: 'Technical Implementation',
                      description: 'Under the hood animation details',
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.code,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pure Flutter CustomPainter',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• 2D 逆运动学 (Inverse Kinematics): 根据曲柄旋转角度动态实时解算两段骨骼联动（大腿、小腿与脚蹼），呈现顺滑真实的圆周踩踏动作。\n'
                                  '• 喉囊弹性物理 (Secondary Motion): 鹈鹕大嘴黄色喉囊带有弹性质感与相位滞后微摆，配合整车颠簸呈现生动自然的体感。\n'
                                  '• 视差环境与粒子系统 (Parallax & Particles): 多层远景山脉、动态白云与星月视差滚动，搭配轮后尘埃与疾风流线。\n'
                                  '• 分辨率无关与零外部依赖: 100% 纯代码矢量绘制，在 Android、iOS、macOS、Windows、Linux 上均可提供丝滑高帧率表现。',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
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
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
