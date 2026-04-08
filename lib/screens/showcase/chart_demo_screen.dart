import 'dart:math';

import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';

class ChartDemoScreen extends StatefulWidget {
  static const name = 'Chart Demo';
  static const path = 'chart';

  const ChartDemoScreen({super.key});

  @override
  State<ChartDemoScreen> createState() => _ChartDemoScreenState();
}

class _ChartDemoScreenState extends State<ChartDemoScreen> {
  // ── Line chart data ──
  final List<DmVizPoint> lineData = [
    DmVizPoint(x: 0, y: 30),
    DmVizPoint(x: 1, y: 50),
    DmVizPoint(x: 2, y: 35),
    DmVizPoint(x: 3, y: 70),
    DmVizPoint(x: 4, y: 55),
    DmVizPoint(x: 5, y: 80),
    DmVizPoint(x: 6, y: 65),
  ];

  final List<DmVizPoint> lineComparisonData = [
    DmVizPoint(x: 0, y: 20),
    DmVizPoint(x: 1, y: 40),
    DmVizPoint(x: 2, y: 25),
    DmVizPoint(x: 3, y: 55),
    DmVizPoint(x: 4, y: 45),
    DmVizPoint(x: 5, y: 60),
    DmVizPoint(x: 6, y: 50),
  ];

  // ── Bar chart data ──
  final List<DmVizPoint> barData = [
    DmVizPoint(x: 'Mon', y: 35),
    DmVizPoint(x: 'Tue', y: 28),
    DmVizPoint(x: 'Wed', y: 45),
    DmVizPoint(x: 'Thu', y: 60),
    DmVizPoint(x: 'Fri', y: 52),
  ];

  // ── Scatter chart data ──
  late final List<DmVizPoint> scatterData = _generateScatterData();

  List<DmVizPoint> _generateScatterData() {
    final rng = Random(42);
    return List.generate(
      30,
      (i) => DmVizPoint(
        x: rng.nextDouble() * 100,
        y: rng.nextDouble() * 100,
        metadata: {'size': 5.0 + rng.nextDouble() * 20},
      ),
    );
  }

  // ── Heatmap data ──
  late final List<DmVizHeatmapCell> heatmapData = _generateHeatmapData();

  List<DmVizHeatmapCell> _generateHeatmapData() {
    final rng = Random(42);
    final cells = <DmVizHeatmapCell>[];
    for (var r = 0; r < 7; r++) {
      for (var c = 0; c < 12; c++) {
        cells.add(DmVizHeatmapCell(row: r, column: c, value: rng.nextDouble()));
      }
    }
    return cells;
  }

  final List<String> heatmapRowLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final List<String> heatmapColumnLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // ── Network graph data ──
  final List<DmVizNetworkNode> networkNodes = [
    DmVizNetworkNode(id: 'flutter', label: 'Flutter', group: 'framework'),
    DmVizNetworkNode(id: 'dart', label: 'Dart', group: 'language'),
    DmVizNetworkNode(id: 'bloc', label: 'BLoC', group: 'state'),
    DmVizNetworkNode(id: 'riverpod', label: 'Riverpod', group: 'state'),
    DmVizNetworkNode(id: 'provider', label: 'Provider', group: 'state'),
    DmVizNetworkNode(id: 'firebase', label: 'Firebase', group: 'backend'),
    DmVizNetworkNode(id: 'supabase', label: 'Supabase', group: 'backend'),
    DmVizNetworkNode(id: 'material', label: 'Material', group: 'ui'),
    DmVizNetworkNode(id: 'cupertino', label: 'Cupertino', group: 'ui'),
  ];

  final List<DmVizNetworkEdge> networkEdges = [
    DmVizNetworkEdge(source: 'flutter', target: 'dart'),
    DmVizNetworkEdge(source: 'flutter', target: 'material'),
    DmVizNetworkEdge(source: 'flutter', target: 'cupertino'),
    DmVizNetworkEdge(source: 'flutter', target: 'bloc'),
    DmVizNetworkEdge(source: 'flutter', target: 'riverpod'),
    DmVizNetworkEdge(source: 'flutter', target: 'provider'),
    DmVizNetworkEdge(source: 'flutter', target: 'firebase'),
    DmVizNetworkEdge(source: 'flutter', target: 'supabase'),
    DmVizNetworkEdge(source: 'bloc', target: 'dart'),
    DmVizNetworkEdge(source: 'riverpod', target: 'dart'),
    DmVizNetworkEdge(source: 'provider', target: 'dart'),
  ];

  final Map<String, Color> networkGroupColors = {
    'framework': Colors.blue,
    'language': Colors.teal,
    'state': Colors.orange,
    'backend': Colors.purple,
    'ui': Colors.green,
  };

  @override
  Widget build(BuildContext context) {
    return DmScaffold(
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
              SliverAppBar(title: Text(ChartDemoScreen.name)),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Line Chart ──
                    _buildSection(
                      context,
                      title: 'DmVizLineChart',
                      description: 'Smooth line charts with optional comparison',
                      children: [
                        _buildChartCard(
                          context,
                          title: 'Basic Line Chart',
                          height: 250,
                          child: DmVizLineChart(
                            data: lineData,
                            xAxisLabel: 'Day',
                            yAxisLabel: 'Value',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChartCard(
                          context,
                          title: 'Line Chart with Comparison',
                          height: 250,
                          child: DmVizLineChart(
                            data: lineData,
                            comparisonData: lineComparisonData,
                            xAxisLabel: 'Day',
                            yAxisLabel: 'Value',
                            smooth: true,
                            showMarkers: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChartCard(
                          context,
                          title: 'Straight Line (no markers)',
                          height: 250,
                          child: DmVizLineChart(
                            data: lineData,
                            smooth: false,
                            showMarkers: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Bar Chart ──
                    _buildSection(
                      context,
                      title: 'DmVizBarChart',
                      description: 'Vertical bar charts with rounded corners',
                      children: [
                        _buildChartCard(
                          context,
                          title: 'Bar Chart',
                          height: 250,
                          child: DmVizBarChart(
                            data: barData,
                            xAxisLabel: 'Weekday',
                            yAxisLabel: 'Sales',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChartCard(
                          context,
                          title: 'Bar Chart (sharp corners)',
                          height: 250,
                          child: DmVizBarChart(
                            data: barData,
                            cornerRadius: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Scatter Chart ──
                    _buildSection(
                      context,
                      title: 'DmVizScatterChart',
                      description:
                          'Scatter plots with marker shapes and dynamic radius',
                      children: [
                        _buildChartCard(
                          context,
                          title: 'Circle Scatter',
                          height: 300,
                          child: DmVizScatterChart(
                            data: scatterData,
                            xAxisLabel: 'X',
                            yAxisLabel: 'Y',
                            shape: DmVizMarkerShape.circle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChartCard(
                          context,
                          title: 'Bubble Scatter (dynamic radius)',
                          height: 300,
                          child: DmVizScatterChart(
                            data: scatterData,
                            xAxisLabel: 'X',
                            yAxisLabel: 'Y',
                            shape: DmVizMarkerShape.diamond,
                            radiusAccessor: (point) =>
                                (point.metadata?['size'] as double?) ?? 8.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Heatmap ──
                    _buildSection(
                      context,
                      title: 'DmVizHeatmap',
                      description:
                          'Grid heatmap with row/column labels and values',
                      children: [
                        _buildChartCard(
                          context,
                          title: 'Activity Heatmap',
                          height: 300,
                          child: DmVizHeatmap(
                            data: heatmapData,
                            rows: 7,
                            columns: 12,
                            rowLabels: heatmapRowLabels,
                            columnLabels: heatmapColumnLabels,
                            showValues: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChartCard(
                          context,
                          title: 'Heatmap with Values',
                          height: 300,
                          child: DmVizHeatmap(
                            data: heatmapData,
                            rows: 7,
                            columns: 12,
                            rowLabels: heatmapRowLabels,
                            columnLabels: heatmapColumnLabels,
                            showValues: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Network Graph ──
                    _buildSection(
                      context,
                      title: 'DmVizNetworkGraph',
                      description:
                          'Interactive force-directed network with groups',
                      children: [
                        _buildChartCard(
                          context,
                          title: 'Flutter Ecosystem Graph',
                          height: 400,
                          child: DmVizNetworkGraph(
                            nodes: networkNodes,
                            links: networkEdges,
                            enableSimulation: true,
                            showNodeLabels: true,
                            showLinkLabels: false,
                            enableZoomPan: true,
                            draggableNodes: true,
                            groupColors: networkGroupColors,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChartCard(
                          context,
                          title: 'Static Network (no simulation)',
                          height: 400,
                          child: DmVizNetworkGraph(
                            nodes: networkNodes,
                            links: networkEdges,
                            enableSimulation: false,
                            showNodeLabels: true,
                            nodeShape: DmVizNetworkNodeShape.hexagon,
                            linkStyle: DmVizNetworkLinkStyle.dashed,
                            groupColors: networkGroupColors,
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

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required double height,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}
